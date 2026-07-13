-module(gnosis_client).

-export([
  new/0,
  new/1,
  run/2,
  lint/4,
  analyze/3,
  verify/3,
  run_topology/3,
  test_topology/2
]).

-record(client, {binary = "gnosis"}).

new() ->
  #client{}.

new(Binary) when is_list(Binary), Binary =/= "" ->
  #client{binary = Binary};
new(_) ->
  #client{}.

run(#client{binary = Binary}, Args) ->
  Command = join_command([Binary | Args]),
  Port = open_port(
    {spawn, Command},
    [stream, exit_status, use_stdio, stderr_to_stdout, hide]
  ),
  collect_port(Port, []).

lint(Client, TopologyPath, Target, AsJson) ->
  Base = ["lint", TopologyPath],
  WithTarget =
    case Target of
      undefined -> Base;
      "" -> Base;
      _ -> Base ++ ["--target", Target]
    end,
  Args =
    case AsJson of
      true -> WithTarget ++ ["--json"];
      _ -> WithTarget
    end,
  run(Client, Args).

analyze(Client, TargetPath, AsJson) ->
  Base = ["analyze", TargetPath],
  Args =
    case AsJson of
      true -> Base ++ ["--json"];
      _ -> Base
    end,
  run(Client, Args).

verify(Client, TopologyPath, TlaOut) ->
  Base = ["verify", TopologyPath],
  Args =
    case TlaOut of
      undefined -> Base;
      "" -> Base;
      _ -> Base ++ ["--tla-out", TlaOut]
    end,
  run(Client, Args).

run_topology(Client, TopologyPath, NativeRuntime) ->
  Base = ["run", TopologyPath],
  Args =
    case NativeRuntime of
      true -> Base ++ ["--native"];
      _ -> Base
    end,
  run(Client, Args).

test_topology(Client, TestPath) ->
  run(Client, ["test", TestPath]).

collect_port(Port, Acc) ->
  receive
    {Port, {data, Data}} ->
      collect_port(Port, [Data | Acc]);
    {Port, {exit_status, Status}} ->
      #{
        exit_code => Status,
        stdout => lists:flatten(lists:reverse(Acc)),
        stderr => ""
      }
  end.

join_command(Parts) ->
  lists:flatten(string:join([quote(Part) || Part <- Parts], " ")).

quote(Value) ->
  [$' | escape(Value)] ++ [$'].

escape([]) ->
  [];
escape([$' | Rest]) ->
  "'\\''" ++ escape(Rest);
escape([Char | Rest]) ->
  [Char | escape(Rest)].
