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

  # No more concats, then the rule doesn't match.
  defp run_tail(_grammar, _input, _state, []) do
    nil
  end

  # Each concat MUST match and in order. Each concat means different paths,
  # i.e: concat1 / concat2 / concat3. This is an alternation.
  defp run_tail(grammar, input, state, cs) do
    # We run all concatenations, and then choose by the longest match in the
    # best possible ugly way :\
    Enum.reduce cs, nil, fn(%{concatenation: c}, acc) ->
      case concatenations grammar, input, state, c do
        nil -> acc
        r = {match, _rest, _state} -> case acc do
          nil -> r
          {last_match, _last_rest, _last_state} ->
            if length(match) > length(last_match) do
              r
            else
              acc
            end
        end
      end
    end
  end

  defp concatenations(grammar, input, state, concs) do
    concatenations grammar, input, state, concs, []
  end

  defp concatenations(_grammar, input, state, [], acc) do
    {:lists.flatten(Enum.reverse(acc)), input, state}
  end

  defp concatenations(grammar, input, state, [c|concs], acc, bt \\ 1) do
    case concatenation grammar, input, state, c do
      {match, rest, new_state} ->
        case concs do
          [c2|_next_concs] ->
            case concatenation grammar, rest, new_state, c2 do
              nil -> if (length(match) - bt) >= c.repetition.repeat.from do
                [last_one|right_matches] = Enum.slice match, (bt - 1), length(match)
                concatenations(
                  grammar, (last_one ++ rest), state, concs, (right_matches ++ acc), (bt + 1)
                )
              else
                concatenations(
                  grammar, rest, new_state, concs,
                  [:lists.flatten(Enum.reverse(match))|acc]
                )
              end
              _ -> concatenations(
                grammar, rest, new_state, concs,
                [:lists.flatten(Enum.reverse(match))|acc]
              )
            end
          _ -> concatenations(
            grammar, rest, new_state, concs,
            [:lists.flatten(Enum.reverse(match))|acc]
          )
      end
      _ ->
        if c.repetition.repeat.from === 0 do
          concatenations grammar, input, state, concs, acc
        else
          nil
        end
    end
  end

  # Every concatenation is wrapped into a repetition.
  defp concatenation(grammar, input, state, %{repetition: %{element: e, repeat: r}}) do
    repetition grammar, input, state, e, r.from, r.to, []
  end

  defp repetition(grammar, input, state, e, from, to, acc) do
    case element grammar, input, state, e do
      {match, rest, state} ->
        acc = [match|acc]
        if(length(acc) === to) do
          {acc, rest, state}
        else
          repetition grammar, rest, state, e, from, to, acc
        end
      _ -> if(length(acc) >= from) do
        {acc, input, state}
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

  defp num_concat(input, state, '', acc) do
    {Enum.reverse(acc), input, state}
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
        {[char], rest, state}
      else
        nil
      end
      _ -> nil
    end
  end
end
