#!/usr/bin/env elixir
# becky.exs -- GG compiler in Elixir.
# BEAM VM + Map. Pattern matching + immutable data.

defmodule Becky do
  @edge_re ~r/\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)/
  @node_re ~r/\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)/

  def strip_comments(source) do
    source
    |> String.split("\n")
    |> Enum.map(fn line ->
      case String.split(line, "//", parts: 2) do
        [before | _] -> String.trim(before)
        _ -> String.trim(line)
      end
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  def parse_properties(nil), do: %{}
  def parse_properties(""), do: %{}
  def parse_properties(raw) do
    raw
    |> String.split(",")
    |> Enum.reduce(%{}, fn seg, acc ->
      case String.split(seg, ":", parts: 2) do
        [key, val] ->
          k = String.trim(key)
          v = val |> String.trim() |> String.trim("'") |> String.trim("\"")
          if k != "" and v != "", do: Map.put(acc, k, v), else: acc
        _ -> acc
      end
    end)
  end

  def split_pipe(raw) do
    raw
    |> String.split("|")
    |> Enum.map(fn part ->
      part
      |> String.trim()
      |> String.trim_leading("(")
      |> String.trim_trailing(")")
      |> String.split(~r/[:{\s]/, parts: 2)
      |> List.first()
      |> String.trim()
    end)
    |> Enum.reject(&(&1 == ""))
  end

  def parse_gg(source) do
    cleaned = strip_comments(source)

    {nodes, edges} = Regex.scan(@edge_re, cleaned)
    |> Enum.reduce({%{}, []}, fn [_full, src, type, props, tgt], {nodes, edges} ->
      src_ids = split_pipe(src)
      tgt_ids = split_pipe(tgt)
      edge = %{source_ids: src_ids, target_ids: tgt_ids, type: String.trim(type), properties: parse_properties(props)}

      new_nodes = (src_ids ++ tgt_ids)
      |> Enum.reduce(nodes, fn id, acc ->
        Map.put_new(acc, id, %{id: id, labels: [], properties: %{}})
      end)

      {new_nodes, [edge | edges]}
    end)

    nodes = cleaned
    |> String.split("\n")
    |> Enum.reject(&String.contains?(&1, "-[:"))
    |> Enum.reduce(nodes, fn line, acc ->
      Regex.scan(@node_re, line)
      |> Enum.reduce(acc, fn [_full, id | rest], acc ->
        id = String.trim(id)
        cond do
          id == "" or String.contains?(id, "|") -> acc
          Map.has_key?(acc, id) -> acc
          true ->
            label = case rest do [l | _] when l != "" -> String.trim(l); _ -> "" end
            labels = if label != "", do: [label], else: []
            props_raw = case rest do [_, p | _] -> p; _ -> "" end
            Map.put(acc, id, %{id: id, labels: labels, properties: parse_properties(props_raw)})
        end
      end)
    end)

    %{nodes: nodes, edges: Enum.reverse(edges)}
  end

  def compute_beta1(prog) do
    Enum.reduce(prog.edges, 0, fn e, b1 ->
      s = length(e.source_ids); t = length(e.target_ids)
      case e.type do
        "FORK" -> b1 + t - 1
        x when x in ["FOLD", "COLLAPSE", "OBSERVE"] -> max(0, b1 - (s - 1))
        x when x in ["RACE", "SLIVER"] -> max(0, b1 - max(0, s - t))
        "VENT" -> max(0, b1 - 1)
        _ -> b1
      end
    end)
  end

  def compute_void(prog), do: prog.edges |> Enum.filter(&(&1.type == "FORK")) |> Enum.map(&length(&1.target_ids)) |> Enum.sum()
  def compute_heat(prog) do
    prog.edges
    |> Enum.filter(&(&1.type in ["FOLD", "COLLAPSE", "OBSERVE"] and length(&1.source_ids) > 1))
    |> Enum.map(&(:math.log2(length(&1.source_ids))))
    |> Enum.sum()
  end
end

# CLI
{opts, args} = OptionParser.parse!(System.argv(), strict: [beta1: :boolean, summary: :boolean, bench: :integer])
filepath = List.first(args)

unless filepath do
  IO.puts(:stderr, "usage: elixir becky.exs [--beta1] [--summary] [--bench N] <file.gg>")
  System.halt(1)
end

source = File.read!(filepath)
bench_iters = Keyword.get(opts, :bench, 0)

if bench_iters > 0 do
  Enum.each(1..10, fn _ -> Becky.parse_gg(source) end)
  start = System.monotonic_time(:nanosecond)
  Enum.each(1..bench_iters, fn _ -> Becky.parse_gg(source) end)
  elapsed = System.monotonic_time(:nanosecond) - start
  us = elapsed / bench_iters / 1000
  p = Becky.parse_gg(source)
  IO.puts("#{Float.round(us / 1, 1)}us/iter | #{bench_iters} iterations | #{map_size(p.nodes)} nodes #{length(p.edges)} edges | b1=#{Becky.compute_beta1(p)} | void=#{Becky.compute_void(p)} heat=#{Float.round(Becky.compute_heat(p), 3)}")
  System.halt(0)
end

p = Becky.parse_gg(source)
b1 = Becky.compute_beta1(p)

cond do
  Keyword.get(opts, :beta1, false) -> IO.puts(b1)
  Keyword.get(opts, :summary, false) ->
    IO.puts("#{filepath}: #{map_size(p.nodes)} nodes, #{length(p.edges)} edges, b1=#{b1}, void=#{Becky.compute_void(p)}, heat=#{Float.round(Becky.compute_heat(p), 3)}")
  true ->
    IO.puts(~s({"nodes":#{map_size(p.nodes)},"edges":#{length(p.edges)},"beta1":#{b1}}))
end
