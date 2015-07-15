################################################################################
# Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
defmodule ABNF.Interpreter do
  alias ABNF.Util, as: Util
  require Logger
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
    if v === nil do
      throw {:invalid_rule, rule}
    end
    case run_tail grammar, input, state, v.elements do
      r = {match, values, rest, state} ->
        if(v.code !== nil) do
          m = case match do
            [] -> ''
            _ -> :lists.flatten(match)
          end
          case Code.eval_string v.code, [
            {:state, state}, {String.to_atom(rule), m}, {:tokens, values}
          ], __ENV__ do
            {{:ok, state}, _} -> {match, match, rest, state}
            {{:ok, state, val}, _} -> {match, val, rest, state}
            r -> throw r
          end
        else
          r
        end
      _ -> nil
    end
  end

  # No more concats, then the rule doesn't match.
  defp run_tail(_grammar, _input, _state, []) do
    nil
  end

  # Each concat MUST match and in order. Each concat means different paths,
  # i.e: concat1 / concat2 / concat3. This is an alternation.
  defp run_tail(grammar, input, state, cs) do
    # We run all concatenations, and then choose by the longest match in the
    # best possible ugly way :\
    r = Enum.reduce cs, nil, fn(%{concatenation: c}, acc) ->
      case concatenations grammar, input, state, c do
        nil -> acc
        {match, values, rest, state} ->
          l = :erlang.iolist_size(match)
          case acc do
            nil -> {match, values, rest, state, l}
            {_last_match, _last_values, _last_rest, _last_state, last_length} ->
              if l > last_length do
                {match, values, rest, state, l}
              else
                acc
              end
          end
      end
    end
    case r do
      {lm, lv, lr, ls, _} -> {lm, lv, lr, ls}
      nil -> nil
    end
  end

  defp concatenations(grammar, input, state, concs) do
    concatenations grammar, input, state, concs, [], []
  end

  defp concatenations(_grammar, input, state, [], acc, acc_values) do
    match = Enum.map Enum.reverse(acc), fn(m) -> :lists.flatten(m) end
    values = Enum.reverse acc_values
    {match, values, input, state}
  end

  defp concatenations(
    grammar, input, state, [c|concs], acc, acc_values,
    bt \\ 1, next_match \\ nil
  ) do
    this_match = if is_nil next_match do
      concatenation grammar, input, state, c
    else
      next_match
    end
    case this_match do
      {match, value, rest, new_state} ->
        case concs do
          [c2|_next_concs] ->
            case concatenation grammar, rest, new_state, c2 do
              nil ->
                lm = length(match)
                if (lm - bt) >= c.repetition.repeat.from do
                  [last_one|right_matches] = Enum.slice match, (bt - 1), lm
                  [_last_one_value|right_matches_value] = Enum.slice value, (bt - 1), lm
                  concatenations(
                    grammar, :lists.flatten([last_one|rest]),
                    state, concs, (right_matches ++ acc),
                    (right_matches_value ++ acc_values),
                    (bt + 1)
                )
                else
                  concatenations(
                    grammar, rest, new_state, concs,
                    [Enum.reverse(match)|acc], [Enum.reverse(value)|acc_values]
                  )
                end
              r -> concatenations(
                grammar, rest, new_state, concs,
                [Enum.reverse(match)|acc], [Enum.reverse(value)|acc_values],
                bt, r
              )
            end
          [] -> concatenations(
            grammar, rest, new_state, concs,
            [Enum.reverse(match)|acc], [Enum.reverse(value)|acc_values]
          )
      end
      nil ->
        if c.repetition.repeat.from === 0 do
          concatenations grammar, input, state, concs, acc, acc_values
        else
          nil
        end
    end
  end

  # Every concatenation is wrapped into a repetition.
  defp concatenation(grammar, input, state, %{repetition: %{element: e, repeat: r}}) do
    repetition grammar, input, state, e, r.from, r.to, [], []
  end

  defp repetition(grammar, input, state, e, from, to, acc, acc_values) do
    case element grammar, input, state, e do
      {match, value, rest, state} ->
        acc = [match|acc]
        acc_values = [value|acc_values]
        if(length(acc) === to) do
          {acc, acc_values, rest, state}
        else
          if ((match === [] or match === [[]]) and from === 0) do
            nil
          else
            repetition grammar, rest, state, e, from, to, acc, acc_values
          end
        end
      _ -> if(length(acc) >= from) do
        {acc, acc_values, input, state}
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
    run_tail grammar, input, state, concs
  end

  defp element(grammar, input, state, %{option: concs}) do
    run_tail grammar, input, state, concs
  end

  defp element(grammar, input, state, %{prose: rule}) do
    run grammar, rule, input, state
  end

  defp char_val(input, state, string) do
    string_len = String.length string
    if(length(input) >= string_len) do
      {cl2, rest} = Enum.split input, string_len
      s2 = String.downcase(to_string cl2)
      if string === s2 do
        {cl2, cl2, rest, state}
      else
        nil
      end
    else
      nil
    end
  end

  defp num_val(input, state, char) do
    case input do
      [^char|rest] -> {[char], [char], rest, state}
      _ -> nil
    end
  end

  defp num_concat(input, state, chars) do
    num_concat input, state, chars, ''
  end

  defp num_concat(_input, _state, '', '') do
    nil
  end

  defp num_concat(input, state, '', acc) do
    m = Enum.reverse(acc)
    {m, m, input, state}
  end

  defp num_concat(input, state, [char|rest2], acc) do
    case input do
      [^char|rest1] -> num_concat rest1, state, rest2, [char|acc]
      _ -> nil
    end
  end

  defp num_range(input, state, min, max) do
    case input do
      [char|rest] -> if(char >= min and char <= max) do
        {[char], [char], rest, state}
      else
        nil
      end
      _ -> nil
    end
  end
end
