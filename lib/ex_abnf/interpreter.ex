defmodule ABNF.Interpreter do
  @moduledoc """
  This modules implements the Grammar.t interpreter. Applying a Grammar.t to the
  given input will result in a CaptureResult.t or an exception.

      Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>

      Licensed under the Apache License, Version 2.0 (the "License");
      you may not use this file except in compliance with the License.
      You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      See the License for the specific language governing permissions and
      limitations under the License.
  """

  alias ABNF.Util, as: Util
  alias ABNF.Grammar, as: Grammar
  alias ABNF.CaptureResult, as: Res
  require Logger

  @doc """
  Parses the given input using the given grammar.
  """
  @spec apply(
    Grammar.t, String.t, char_list, term
  ) :: CaptureResult.t | no_return
  def apply(grammar, rule_str, input, state \\ nil) do
    rule_str = Util.rulename rule_str
    case parse_real grammar, %{element: :rulename, value: rule_str}, input, state do
      nil -> nil
      {
        r_string_text,
        r_string_tokens,
        r_values,
        r_state,
        r_rest
      } -> %Res{
        string_text: r_string_text,
        string_tokens: r_string_tokens,
        values: r_values,
        state: r_state,
        input: input,
        rest: r_rest
      }
    end
  end

  defp parse_real(
    grammar, e = %{element: :rule, value: a}, input, state
  ) do
    case parse_real grammar, a, input, state do
      nil -> nil
      r = {
        r_string_text,
        r_string_tokens,
        r_values,
        r_state,
        r_rest
      } ->
        if is_nil e[:code] do
          r
        else
          try do
            case Code.eval_string e.code, [
              {:state, r_state},
              {:rule, r_string_text},
              {:string_values, r_string_tokens},
              {:values, r_values}
            ], __ENV__ do
              {{:ok, state}, _} -> {
                r_string_text,
                r_string_tokens,
                r_values,
                state,
                r_rest
              }
              {{:ok, state, val}, _} -> {
                r_string_text,
                r_string_tokens,
                [val],
                state,
                r_rest
              }
              r -> raise ArgumentError,
                "Unexpected result for rule #{inspect e} #{inspect r}"
            end
          rescue
            ex ->
              Logger.error "Unexpected result for rule " <>
              " when running code #{inspect e.code}"
              stacktrace = System.stacktrace
              reraise ex, stacktrace
          end
        end
    end
  end

  defp parse_real(
    grammar, %{element: :prose_val, value: v}, input, state
  ) do
    parse_real grammar, %{element: :rulename, value: v}, input, state
  end

  defp parse_real(
    grammar, %{element: :alternation, value: alternation}, input, state
  ) do
    r = Enum.reduce alternation, nil, fn(e, acc) ->
      case concatenation grammar, e.value, input, state, {
        [],
        [],
        [],
        state,
        input
      } do
        nil -> acc
        r = {
          r_string_text,
          _r_string_tokens,
          _r_values,
          _r_state,
          _r_rest
        } -> case acc do
          nil -> {:erlang.iolist_size(r_string_text), r}
          {last_l, _last_r} ->
            l = :erlang.iolist_size r_string_text
            if last_l >= l do
              acc
            else
              {l, r}
            end
        end
      end
    end
    case r do
      nil -> nil
      {_, r} -> r
    end
  end

  defp parse_real(grammar, e = %{element: :repetition}, input, state) do
    repetition grammar, e, input, state, {
      [],
      [],
      [],
      state,
      input
    }
  end

  defp parse_real(
    _grammar, %{element: :num_range, value: %{from: from, to: to}}, input, state
  ) do
    case input do
      [char|rest] -> if(char >= from and char <= to) do
        result = [char]
        {
          result,
          [result],
          [result],
          state,
          rest
        }
      else
        nil
      end
      _ -> nil
    end
  end

  defp parse_real(
    _grammar, %{element: :char_val, value: %{length: l, string: string}},
    input, state
  ) do
    {s1, rest} = Enum.split input, l
    s1s = String.downcase to_string(s1)
    if s1s === string do
      {
        s1,
        [s1],
        [s1],
        state,
        rest
      }
    else
      nil
    end
  end

  defp parse_real(_grammar, %{element: :num_concat, value: list}, input, state) do
    case num_concat list, input do
      nil -> nil
      {match, rest} -> {
        match,
        [match],
        [match],
        state,
        rest
      }
    end
  end

  defp parse_real(grammar, %{element: :rulename, value: e}, input, state) do
    value = Map.get grammar, e
    if is_nil value do
      raise ArgumentError, "Rule #{e} not found in #{Map.keys(grammar)}"
    end
    parse_real grammar, value, input, state
  end

  defp parse_real(grammar, %{element: :group, value: e}, input, state) do
    parse_real grammar, e, input, state
  end

  defp parse_real(grammar, %{element: :option, value: e}, input, state) do
    case parse_real grammar, e, input, state do
      nil -> {
        '',
        [''],
        [],
        state,
        input
      }
      r -> r
    end
  end

  defp num_concat(list, input, acc \\ [])

  defp num_concat([], input, acc) do
    match = Enum.reverse acc
    {match, input}
  end

  defp num_concat([char1|rest_list], [char2|rest_input], acc) do
    if char1 === char2 do
      num_concat rest_list, rest_input, [char1|acc]
    else
      nil
    end
  end

  defp repetition(
    grammar, e = %{element: :repetition, value: %{from: from, to: to, value: v}},
    input, state, acc = {
      acc_string_text,
      acc_string_tokens,
      acc_values,
      _acc_state,
      _acc_rest
    }
  ) do
    case parse_real grammar, v, input, state do
      nil -> if length(acc_values) >= from do
        acc
      else
        nil
      end
      {
        r_string_text,
        _r_string_tokens,
        r_values,
        r_state,
        r_rest
      } ->
        {
          _acc_string_text,
          _acc_string_tokens,
          acc_values,
          _acc_state,
          _acc_rest
        } = acc = {
          [r_string_text|acc_string_text],
          [r_string_text|acc_string_tokens],
          [r_values|acc_values],
          r_state,
          r_rest
        }
        if length(acc_values) === to do
          acc
        else
          # Check for from:0 to: :infinity and empty match
          if r_string_text === '' do
            acc
          else
            repetition grammar, e, r_rest, r_state, acc
          end
        end
    end
  end

  defp concatenation(_grammar, [], _input, _state, acc) do
    prep_result acc
  end

  defp concatenation(
    grammar, [c|cs], input, state, acc, next_match \\ nil
  ) do
    r = if is_nil next_match do
      parse_real grammar, c, input, state
    else
      next_match
    end

    if is_nil r do
      nil
    else
      # This one matches, but we need to check if the next one also matches
      # and try with one less repetition if not (backtracking)
      {
        _r_string_text,
        r_string_tokens,
        r_values,
        r_state,
        r_rest
      } = r
      case cs do
        [next_c|_next_cs] -> case repetition grammar, next_c, r_rest, r_state, {
          [],
          [],
          [],
          r_state,
          r_rest
        } do
          nil ->
            match_length = length r_string_tokens
            to = match_length - 1
            if to > 0 and to >= c.value.from do
              c_val = Map.put c.value, :to, to
              c = Map.put c, :value, c_val

              [h_string_tokens|t_string_tokens] = r_string_tokens
              string_tokens = t_string_tokens

              [_h_values|t_values] = r_values
              values = t_values

              rest = h_string_tokens ++ r_rest
              r = {
                string_tokens,
                string_tokens,
                values,
                r_state,
                rest
              }
              concatenation grammar, [c|cs], input, state, acc, r
            else
              if c.value.from === 0 do
                r = {
                  '',
                  [],
                  [],
                  state,
                  input
                }
                acc = {
                  _acc_string_text,
                  _acc_string_tokens,
                  _acc_values,
                  acc_state,
                  acc_rest
                } = conc_result r, acc
                concatenation grammar, cs, acc_rest, acc_state, acc
              else
                nil
              end
            else
              nil
            end
          next_r ->
            # Next one matches, we're cool. Go on, and pass on the next match
            # so it's not parsed again.
            acc = {
              _acc_string_text,
              _acc_string_tokens,
              _acc_values,
              acc_state,
              acc_rest
            } = conc_result r, acc
            concatenation grammar, cs, acc_rest, acc_state, acc, next_r
        end
        [] ->
          acc = conc_result r, acc
          prep_result acc
      end
    end
  end

  defp prep_result({
    r_string_text,
    r_string_tokens,
    r_values,
    r_state,
    r_rest
  }) do
    {
      :lists.flatten(Enum.reverse(r_string_text)),
      (for t <- Enum.reverse(r_string_tokens), do: :lists.flatten(t)),
      Enum.reverse(r_values),
      r_state,
      r_rest
    }
  end

  defp conc_result({
    r_string_text,
    _r_string_tokens,
    r_values,
    r_state,
    r_rest
  }, {
    acc_string_text,
    acc_string_tokens,
    acc_values,
    _acc_state,
    _acc_rest
  }) do
    m = Enum.reverse r_string_text
    {
      [m|acc_string_text],
      [m|acc_string_tokens],
      [Enum.reverse(r_values)|acc_values],
      r_state,
      r_rest
    }
  end
end