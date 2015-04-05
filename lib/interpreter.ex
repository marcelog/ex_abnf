defmodule RFC4234.Interpreter do
  require Logger

  @moduledoc """
  Parser functions for the abnf rules.
  """

  @type match :: [byte]
  @type rest :: [byte]
  @type result :: nil | {match, rest}

  @spec run(Map, String.t, [byte]) :: result
  def run(grammar, rule, input) do
    rule = String.downcase rule
    v = Map.get(grammar, rule)
    run_tail grammar, input, v
  end

  defp run_tail(_grammar, '', _concs) do
    nil
  end

  defp run_tail(_grammar, _input, []) do
    nil
  end

  defp run_tail(grammar, input, [%{concatenation: c}|concs]) do
    case concatenations grammar, input, c do
      nil -> run_tail grammar, input, concs
      r -> r
    end
  end

  defp concatenations(grammar, input, concs) do
    concatenations grammar, input, concs, []
  end

  defp concatenations(_grammar, input, '', acc) do
    {:lists.flatten(Enum.reverse(acc)), input}
  end

  defp concatenations(_grammar, '', _cs, _acc) do
    nil
  end

  defp concatenations(grammar, input, [c|concs], acc) do
    case concatenation grammar, input, c do
      {match, rest} -> concatenations grammar, rest, concs, [match|acc]
      _ -> nil
    end
  end

  defp concatenation(grammar, input, %{repetition: %{element: e, repeat: r}}) do
    repetition grammar, input, e, r.from, r.to, []
  end

  defp repetition(grammar, input, e, from, to, acc) do
    case element grammar, input, e do
      {match, rest} ->
        acc = [match|acc]
        if(length(acc) === to) do
          {:lists.flatten(Enum.reverse(acc)), rest}
        else
          repetition grammar, rest, e, from, to, acc
        end
      _ -> if(length(acc) > from) do
        {:lists.flatten(Enum.reverse(acc)), input}
      else
        nil
      end
    end
  end

  defp element(grammar, input, %{rulename: rule}) do
    run grammar, rule, input
  end

  defp element(_grammar, input, %{char_val: string}) do
    char_val input, string
  end

  defp element(_grammar, input, %{hex_val: num}) do
    num_val input, num
  end

  defp element(_grammar, input, %{dec_val: num}) do
    num_val input, num
  end

  defp element(_grammar, input, %{bit_val: num}) do
    num_val input, num
  end

  defp element(_grammar, input, %{bit_concat: nums}) do
    num_concat input, nums
  end

  defp element(_grammar, input, %{dec_concat: nums}) do
    num_concat input, nums
  end

  defp element(_grammar, input, %{hex_concat: nums}) do
    num_concat input, nums
  end

  defp element(_grammar, input, %{bit_range: {min, max}}) do
    num_range input, min, max
  end

  defp element(_grammar, input, %{dec_range: {min, max}}) do
    num_range input, min, max
  end

  defp element(_grammar, input, %{hex_range: {min, max}}) do
    num_range input, min, max
  end

  defp element(grammar, input, %{group: concs}) do
    case run_tail grammar, input, concs do
      nil -> nil
      r -> r
    end
  end

  defp element(grammar, input, %{option: concs}) do
    case run_tail grammar, input, concs do
      nil -> {'', input}
      r -> r
    end
  end

  defp char_val(input, string) do
    string_len = String.length string
    if(length(input) >= string_len) do
      {cl2, rest} = Enum.split input, string_len
      s2 = String.downcase(to_string cl2)
      if string === s2 do
        {cl2, rest}
      else
        nil
      end
    else
      nil
    end
  end

  defp num_val(input, char) do
    case input do
      [^char|rest] -> {[char], rest}
      _ -> nil
    end
  end

  defp num_concat(input, chars) do
    num_concat input, chars, ''
  end

  defp num_concat(_input, '', '') do
    nil
  end

  defp num_concat(input, '', acc) do
    {Enum.reverse(acc), input}
  end

  defp num_concat(input, [char|rest2], acc) do
    case input do
      [^char|rest1] -> num_concat rest1, rest2, [char|acc]
      _ -> nil
    end
  end

  defp num_range(input, min, max) do
    case input do
      [char|rest] -> if(char >= min and char <= max) do
        {[char], rest}
      else
        nil
      end
      _ -> nil
    end
  end
end
