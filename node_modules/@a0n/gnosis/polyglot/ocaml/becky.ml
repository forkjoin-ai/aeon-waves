(* becky.ml -- GG compiler in OCaml.
   Hashtbl for O(1) lookup. ML pattern matching. Functional core.
   Build: ocamlfind ocamlopt -package re -linkpkg becky.ml -o becky-ocaml
   Or interpreted: ocaml becky.ml betti.gg --summary *)

let strip_comments source =
  source |> String.split_on_char '\n'
  |> List.filter_map (fun line ->
    let line = match String.index_opt line '/' with
      | Some i when i + 1 < String.length line && line.[i+1] = '/' ->
        String.sub line 0 i
      | _ -> line
    in
    let line = String.trim line in
    if String.length line > 0 then Some line else None)
  |> String.concat "\n"

let split_pipe raw =
  String.split_on_char '|' raw
  |> List.filter_map (fun part ->
    let p = String.trim part in
    let p = if String.length p > 0 && p.[0] = '(' then String.sub p 1 (String.length p - 1) else p in
    let p = if String.length p > 0 && p.[String.length p - 1] = ')' then String.sub p 0 (String.length p - 1) else p in
    let p = match String.index_opt p ':' with Some i -> String.sub p 0 i | None -> p in
    let p = match String.index_opt p '{' with Some i -> String.sub p 0 i | None -> p in
    let p = String.trim p in
    if String.length p > 0 then Some p else None)

(* Simple regex-free edge finder using string scanning *)
let find_edges cleaned =
  let len = String.length cleaned in
  let edges = ref [] in
  let i = ref 0 in
  while !i + 4 < len do
    if cleaned.[!i] = ')' && cleaned.[!i+1] = '-' && cleaned.[!i+2] = '[' && cleaned.[!i+3] = ':' then begin
      (* Backtrack for source ( *)
      let marker = !i in
      let src_start = ref marker in
      let depth = ref 0 in
      let j = ref (marker - 1) in
      while !j >= 0 do
        if cleaned.[!j] = ')' then incr depth
        else if cleaned.[!j] = '(' then begin
          if !depth = 0 then (src_start := !j + 1; j := 0)
          else decr depth
        end;
        decr j
      done;
      let source_raw = String.sub cleaned !src_start (marker - !src_start) in
      (* Find ] *)
      let bracket_start = marker + 3 in
      (match String.index_from_opt cleaned bracket_start ']' with
      | Some bracket_end ->
        let rel = String.sub cleaned bracket_start (bracket_end - bracket_start) in
        let rel = if String.length rel > 0 && rel.[0] = ':' then String.sub rel 1 (String.length rel - 1) else rel in
        let edge_type = match String.index_opt rel '{' with
          | Some b -> String.trim (String.sub rel 0 b)
          | None -> String.trim rel
        in
        let arrow_start = bracket_end + 1 in
        if arrow_start + 2 < len && cleaned.[arrow_start] = '-' && cleaned.[arrow_start+1] = '>' then begin
          (match String.index_from_opt cleaned (arrow_start + 2) '(' with
          | Some tgt_open ->
            let depth2 = ref 0 in
            let tgt_close = ref tgt_open in
            for k = tgt_open to len - 1 do
              if cleaned.[k] = '(' then incr depth2
              else if cleaned.[k] = ')' then begin
                decr depth2;
                if !depth2 = 0 then tgt_close := k
              end
            done;
            let target_raw = String.sub cleaned (tgt_open + 1) (!tgt_close - tgt_open - 1) in
            edges := (source_raw, edge_type, target_raw) :: !edges;
            i := !tgt_close
          | None -> ())
        end
      | None -> ());
    end;
    incr i
  done;
  List.rev !edges

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  let beta1_only = ref false in
  let summary = ref false in
  let bench_iters = ref 0 in
  let filepath = ref "" in
  let rec parse_args = function
    | "--beta1" :: rest -> beta1_only := true; parse_args rest
    | "--summary" :: rest -> summary := true; parse_args rest
    | "--bench" :: n :: rest -> bench_iters := int_of_string n; parse_args rest
    | s :: rest -> filepath := s; parse_args rest
    | [] -> ()
  in
  parse_args args;
  if !filepath = "" then (Printf.eprintf "usage: ocaml becky.ml [--beta1|--summary|--bench N] <file.gg>\n"; exit 1);
  let ic = open_in !filepath in
  let n = in_channel_length ic in
  let source = really_input_string ic n in
  close_in ic;
  let cleaned = strip_comments source in
  let raw_edges = find_edges cleaned in
  let nodes : (string, unit) Hashtbl.t = Hashtbl.create 64 in
  let edge_count = ref 0 in
  let b1 = ref 0 in
  let void_dims = ref 0 in
  List.iter (fun (src_raw, edge_type, tgt_raw) ->
    let src_ids = split_pipe src_raw in
    let tgt_ids = split_pipe tgt_raw in
    incr edge_count;
    List.iter (fun id -> if not (Hashtbl.mem nodes id) then Hashtbl.add nodes id ()) src_ids;
    List.iter (fun id -> if not (Hashtbl.mem nodes id) then Hashtbl.add nodes id ()) tgt_ids;
    let s = List.length src_ids and t = List.length tgt_ids in
    (match edge_type with
    | "FORK" -> b1 := !b1 + t - 1; void_dims := !void_dims + t
    | "FOLD" | "COLLAPSE" | "OBSERVE" -> b1 := max 0 (!b1 - (s - 1))
    | "RACE" | "SLIVER" -> b1 := max 0 (!b1 - (max 0 (s - t)))
    | "VENT" -> b1 := max 0 (!b1 - 1)
    | _ -> ())
  ) raw_edges;
  (* Standalone nodes *)
  String.split_on_char '\n' cleaned |> List.iter (fun line ->
    if not (try let _ = Str.search_forward (Str.regexp_string "-[:") line 0 in true with Not_found -> false) then
      (* Simple scan for (id...) *)
      let len = String.length line in
      let i = ref 0 in
      while !i < len do
        if line.[!i] = '(' then begin
          let start = !i + 1 in
          let depth = ref 1 in
          let j = ref start in
          while !j < len && !depth > 0 do
            if line.[!j] = '(' then incr depth;
            if line.[!j] = ')' then decr depth;
            if !depth > 0 then incr j
          done;
          if !depth = 0 then begin
            let inner = String.sub line start (!j - start) in
            if not (String.contains inner '|') then begin
              let id = match String.index_opt inner ':' with Some c -> String.sub inner 0 c | None -> inner in
              let id = match String.index_opt id '{' with Some c -> String.sub id 0 c | None -> id in
              let id = String.trim id in
              if String.length id > 0 && not (Hashtbl.mem nodes id) then Hashtbl.add nodes id ()
            end;
            i := !j + 1
          end else incr i
        end else incr i
      done
  );
  let node_count = Hashtbl.length nodes in

  if !bench_iters > 0 then begin
    (* Warmup *)
    for _ = 1 to 10 do
      let c = strip_comments source in
      let _ = find_edges c in ()
    done;
    let start = Unix.gettimeofday () in
    for _ = 1 to !bench_iters do
      let c = strip_comments source in
      let _ = find_edges c in ()
    done;
    let elapsed = Unix.gettimeofday () -. start in
    let us = elapsed *. 1e6 /. (float_of_int !bench_iters) in
    Printf.printf "%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d\n"
      us !bench_iters node_count !edge_count !b1 !void_dims
  end else if !beta1_only then
    Printf.printf "%d\n" !b1
  else if !summary then
    Printf.printf "%s: %d nodes, %d edges, b1=%d, void=%d\n"
      !filepath node_count !edge_count !b1 !void_dims
  else
    Printf.printf "{\"nodes\":%d,\"edges\":%d,\"beta1\":%d}\n"
      node_count !edge_count !b1
