#!/usr/bin/env elixir
# Gnosis polyglot execution harness for Elixir.
#
# Protocol: reads JSON request from stdin, loads the target file,
# calls the named function, writes JSON response to stdout.

defmodule GnodeHarness do
  def run do
    raw_input = IO.read(:stdio, :eof)

    case raw_input do
      :eof ->
        write_response(%{status: "error", value: "empty input", stdout: "", stderr: ""})

      data when is_binary(data) ->
        data = String.trim(data)
        if data == "" do
          write_response(%{status: "error", value: "empty input", stdout: "", stderr: ""})
        else
          case Jason.decode(data) do
            {:ok, request} -> handle_request(request)
            {:error, _} ->
              # Fallback: try Poison or manual parsing.
              try do
                request = :erlang.binary_to_term(data)
                handle_request(request)
              rescue
                _ -> write_response(%{status: "error", value: "invalid JSON input (install jason: mix deps.get)", stdout: "", stderr: ""})
              end
          end
        end
    end
  end

  defp handle_request(%{"action" => "ping"}) do
    write_response(%{status: "ok", value: "pong", stdout: "", stderr: ""})
  end

  defp handle_request(request) do
    file_path = Map.get(request, "filePath", "")
    function_name = Map.get(request, "functionName", "main") |> String.to_atom()
    args = Map.get(request, "args", [])

    try do
      # Compile and load the target file.
      Code.compile_file(file_path)

      # Find the module -- convention: module name matches file name.
      module_name = file_path
        |> Path.basename(".exs")
        |> Path.basename(".ex")
        |> Macro.camelize()
        |> String.to_atom()

      # Try to find the module.
      module = Module.concat([module_name])

      result = apply(module, function_name, args)

      write_response(%{
        status: "ok",
        value: result,
        stdout: "",
        stderr: ""
      })
    rescue
      e ->
        write_response(%{
          status: "error",
          value: Exception.message(e),
          stdout: "",
          stderr: ""
        })
    end
  end

  defp write_response(response) do
    case Jason.encode(response) do
      {:ok, json} -> IO.write(:stdio, json)
      {:error, _} ->
        # Fallback: manual JSON.
        IO.write(:stdio, ~s({"status":"#{response.status}","value":"#{response.value}","stdout":"","stderr":""}))
    end
  end
end

# Check if Jason is available; if not, provide a minimal implementation.
unless Code.ensure_loaded?(Jason) do
  defmodule Jason do
    def decode(string) do
      try do
        # Use :json module (OTP 27+) or eval-based fallback.
        result = Code.eval_string(string |> String.replace("null", "nil") |> String.replace("true", "true") |> String.replace("false", "false"))
        {:ok, elem(result, 0)}
      rescue
        _ -> {:error, :decode_error}
      end
    end

    def encode(term) do
      try do
        {:ok, do_encode(term)}
      rescue
        _ -> {:error, :encode_error}
      end
    end

    defp do_encode(nil), do: "null"
    defp do_encode(true), do: "true"
    defp do_encode(false), do: "false"
    defp do_encode(n) when is_integer(n), do: Integer.to_string(n)
    defp do_encode(n) when is_float(n), do: Float.to_string(n)
    defp do_encode(s) when is_binary(s), do: ~s("#{String.replace(s, "\"", "\\\"")}")
    defp do_encode(s) when is_atom(s), do: do_encode(Atom.to_string(s))
    defp do_encode(list) when is_list(list) do
      "[" <> Enum.map_join(list, ",", &do_encode/1) <> "]"
    end
    defp do_encode(map) when is_map(map) do
      pairs = Enum.map_join(map, ",", fn {k, v} ->
        do_encode(to_string(k)) <> ":" <> do_encode(v)
      end)
      "{" <> pairs <> "}"
    end
    defp do_encode(other), do: do_encode(inspect(other))
  end
end

GnodeHarness.run()
