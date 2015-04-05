defmodule RFC4234.Interpreter do
  alias RFC4234.Util, as: Util

  @moduledoc """
  Parser functions for the abnf rules.
  """

  @type match :: [byte]
  @type rest :: [byte]
  @type result :: nil | {match, rest}

  @spec run(Map, String.t, [byte], term) :: result
  def run(grammar, rule, input, state) do
    rule = Util.normalize_rule_name rule
    v = Map.get(grammar, rule)
    case run_tail grammar, input, state, v.elements do
      r = {match, rest, state} ->
        if(v.code !== nil) do
          case Code.eval_string v.code, [
            {:state, state}, {String.to_atom(rule), match}
          ], __ENV__ do
            {{:ok, state}, _} -> {match, rest, state}
            r -> throw r
          end
        else
          r
        end
      _ -> nil
    end
  end

  defp run_tail(_grammar, '', _state, _concs) do
    nil
  end

  defp run_tail(_grammar, _input, _state, []) do
    nil
  end

  defp run_tail(grammar, input, state, [%{concatenation: c}|concs]) do
    case concatenations grammar, input, state, c do
      nil -> run_tail grammar, input, state, concs
      r -> r
    end
  end

  defp concatenations(grammar, input, state, concs) do
    concatenations grammar, input, state, concs, []
  end

  defp concatenations(_grammar, input, state, '', acc) do
    {:lists.flatten(Enum.reverse(acc)), input, state}
  end

  defp concatenations(_grammar, '', _state, _cs, _acc) do
    nil
  end

  defp concatenations(grammar, input, state, [c|concs], acc) do
    case concatenation grammar, input, state, c do
      {match, rest, state} -> concatenations grammar, rest, state, concs, [match|acc]
      _ -> nil
    end
  end

  defp concatenation(grammar, input, state, %{repetition: %{element: e, repeat: r}}) do
    repetition grammar, input, state, e, r.from, r.to, []
  end

  defp repetition(grammar, input, state, e, from, to, acc) do
    case element grammar, input, state, e do
      {match, rest, state} ->
        acc = [match|acc]
        if(length(acc) === to) do
          {:lists.flatten(Enum.reverse(acc)), rest, state}
        else
          repetition grammar, rest, state, e, from, to, acc
        end
      _ -> if(length(acc) > from) do
        {:lists.flatten(Enum.reverse(acc)), input, state}
      else
        nil
      end
    end
  end

  defp element(grammar, input, state, %{rulename: rule}) do
    run grammar, rule, input, state
  end

  defp element(_grammar, input, state, %{char_val: string}) do
    char_val input, state, string
  end

  defp element(_grammar, input, state, %{hex_val: num}) do
    num_val input, state, num
  end

  defp element(_grammar, input, state, %{dec_val: num}) do
    num_val input, state, num
  end

  defp element(_grammar, input, state, %{bit_val: num}) do
    num_val input, state, num
  end

  defp element(_grammar, input, state, %{bit_concat: nums}) do
    num_concat input, state, nums
  end

  defp element(_grammar, input, state, %{dec_concat: nums}) do
    num_concat input, state, nums
  end

  defp element(_grammar, input, state, %{hex_concat: nums}) do
    num_concat input, state, nums
  end

  defp element(_grammar, input, state, %{bit_range: {min, max}}) do
    num_range input, state, min, max
  end

  defp element(_grammar, input, state, %{dec_range: {min, max}}) do
    num_range input, state, min, max
  end

  defp element(_grammar, input, state, %{hex_range: {min, max}}) do
    num_range input, state, min, max
  end

  defp element(grammar, input, state, %{group: concs}) do
    case run_tail grammar, input, state, concs do
      nil -> nil
      r -> r
    end
  end

  defp element(grammar, input, state, %{option: concs}) do
    case run_tail grammar, input, state, concs do
      nil -> {'', input, state}
      r -> r
    end
  end

  defp char_val(input, state, string) do
    string_len = String.length string
    if(length(input) >= string_len) do
      {cl2, rest} = Enum.split input, string_len
      s2 = String.downcase(to_string cl2)
      if string === s2 do
        {cl2, rest, state}
      else
        nil
      end
    else
      nil
    end
  end

  defp num_val(input, state, char) do
    case input do
      [^char|rest] -> {[char], rest, state}
      _ -> nil
    end
  end

  defp num_concat(input, state, chars) do
    num_concat input, chars, '', state
  end

  defp num_concat(_input, _state, '', '') do
    nil
  end

  defp num_concat(input, '', state, acc) do
    {Enum.reverse(acc), input, state}
  end

  defp num_concat(input, state, [char|rest2], acc) do
    case input do
      [^char|rest1] -> num_concat rest1, rest2, [char|acc]
      _ -> nil
    end
  end

  defp num_range(input, state, min, max) do
    case input do
      [char|rest] -> if(char >= min and char <= max) do
        {[char], rest, state}
      else
        nil
      end
      _ -> nil
    end
  end
end
