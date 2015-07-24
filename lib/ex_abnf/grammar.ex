defmodule ABNF.Grammar do
  @moduledoc """
  Parses an ABNF Grammar.

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

  alias ABNF.Core, as: Core
  alias ABNF.Util, as: Util

  @type t :: Map

  # rulelist = 1*( rule / (*WSP c-nl) )
  # As described in the Errata #3076
  @doc """
  Builds a Grammar.t from the given input (an ABNF text grammar). You should
  never use this one directly but use the ones in the ABNF module instead.
  """
  @spec rulelist(char_list, t, Map) :: t
  def rulelist(input, acc \\ %{}, last \\ nil) do
    case rule input do
      nil ->
        rest = zero_or_more_wsp input
        case c_nl rest do
          nil -> {acc, input}
          {comments, rest} -> case last do
            nil -> rulelist rest, acc
            last ->
              last = add_comments last, comments
              rulelist rest, Map.put(acc, last.name, last)
          end
        end
      {r, rest} -> rulelist rest, Map.put(acc, r.name, r)
    end
  end

  # rule = rulename defined-as elements c-nl
  # ; continues if next line starts with white space
  defp rule(input) do
    case rulename input do
      nil -> nil
      {name, rest} -> case defined_as rest do
        nil -> nil
        {das, rest} -> case elements rest do
          nil -> nil
          {es, rest} ->
            {c, rest} = case code rest do
              nil -> {nil, rest}
              r -> r
            end
            case c_nl rest do
              nil -> nil
              {comments, rest} ->
                r = %{
                  name: Util.rulename(name.value),
                  defined_as: das,
                  element: :rule,
                  value: es,
                  code: c,
                  comments: comments
                }
                {r, rest}
            end
        end
      end
    end
  end

  # defined-as = *c-wsp ("=" / "=/") *c-wsp
  # ; basic rules definition and incremental alternatives
  defp defined_as(input) do
    case zero_or_more_cwsp input do
      {_, [?=, ?/|rest]} ->
        {_, rest} = zero_or_more_cwsp rest
        {:not_equal, rest}
      {_, [?=|rest]} ->
        {_, rest} = zero_or_more_cwsp rest
        {:equal, rest}
      _ -> nil
    end
  end

  # code = !!! octet !!!
  defp code(input) do
    case input do
      [?!,?!,?!|rest] -> code_tail rest
      _ -> nil
    end
  end

  defp code_tail(input, acc \\ []) do
    case input do
      [?!,?!,?!|rest] -> {Enum.reverse(acc), rest}
      [char|rest] -> code_tail rest, [char|acc]
      _ -> nil
    end
  end

  # alternation = concatenation *(*c-wsp "/" *c-wsp concatenation)
  defp alternation(input) do
    case concatenation input do
      nil -> nil
      {c, rest} ->
        {as, rest} = alternation_tail rest, [c]
        {token(:alternation, as), rest}
    end
  end

  defp alternation_tail(input, [last_e|next_e] = acc) do
    case zero_or_more_cwsp input do
      {comments1, [?/|rest]} ->
        {comments2, rest} = zero_or_more_cwsp rest
        case concatenation rest do
          nil -> {Enum.reverse(acc), input}
          {c, rest} ->
            c = add_comments c, comments2
            last_e = add_comments last_e, comments1
            alternation_tail rest, [c, last_e|next_e]
        end
      _ -> {Enum.reverse(acc), input}
    end
  end

  # repetition = [repeat] element
  defp repetition(input) do
    {from, to, rest} = case repeat input do
      nil -> {1, 1, input}
      r -> r
    end
    case element rest do
      nil -> nil
      {e, rest} -> {token(:repetition, %{from: from, to: to, value: e}), rest}
    end
  end

  # concatenation = repetition *(1*c-wsp repetition)
  defp concatenation(input) do
    case repetition input do
      nil -> nil
      {e, rest} ->
        {es, rest} = concatenation_tail rest, [e]
        {token(:concatenation, es), rest}
    end
  end

  defp concatenation_tail(input, [last_e|next_e] = acc) do
    {match, rest} = zero_or_more_cwsp input
    if length(match) === 0 do
      {Enum.reverse(acc), input}
    else
      case repetition rest do
        nil -> {Enum.reverse(acc), input}
        {e, rest} ->
          last_e = add_comments last_e, match
          concatenation_tail rest, [e, last_e|next_e]
      end
    end
  end

  # elements = alternation *WSP
  # As described in the Errata #2968
  defp elements(input) do
    case alternation input do
      nil -> nil
      {a, rest} ->
        rest = zero_or_more_wsp rest
        {a, rest}
    end
  end

  # element = rulename / group / option / char-val / num-val / prose-val
  defp element(input) do
    case rulename input do
      nil -> case group input do
        nil -> case option input do
          nil -> case char_val input do
            nil -> case num_val input do
              nil -> prose_val input
              r -> r
            end
            r -> r
          end
          r -> r
        end
        r -> r
      end
      r -> r
    end
  end

  # group = "(" *c-wsp alternation *c-wsp ")"
  defp group(input) do
    case input do
      [?(|rest] ->
        {comments1, rest} = zero_or_more_cwsp rest
        case alternation rest do
          nil -> nil
          {a, rest} ->
            case zero_or_more_cwsp rest do
              {comments2, [?)|rest]} ->
                a = add_comments a, (comments1 ++ comments2)
                {token(:group, a), rest}
              _ -> nil
            end
          _ -> nil
        end
      _ -> nil
    end
  end

  # option = "[" *c-wsp alternation *c-wsp "]"
  defp option(input) do
    case input do
      [?[|rest] ->
        {comments1, rest} = zero_or_more_cwsp rest
        case alternation rest do
          nil -> nil
          {a, rest} ->
            case zero_or_more_cwsp rest do
              {comments2, [?]|rest]} ->
                a = add_comments a, (comments1 ++ comments2)
                {token(:option, a), rest}
              _ -> nil
            end
          _ -> nil
        end
      _ -> nil
    end
  end

  # rulename = ALPHA *(ALPHA / DIGIT / "-")
  # Rule names are case-insensitive
  # The names <rulename>, <Rulename>, <RULENAME>, and <rUlENamE> all
  # refer to the same rule.
  defp rulename(input) do
    case input do
      [char|rest] -> if Core.alpha?(char) do
        rulename_tail rest, [char]
      else
        nil
      end
      _ -> nil
    end
  end

  defp rulename_tail(input, acc) do
    case input do
      [char|rest] -> if Core.alpha?(char) or Core.digit?(char) or (char === ?-) do
        rulename_tail rest, [char|acc]
      else
        {token(:rulename, Util.rulename(Enum.reverse(acc))), input}
      end
      _ -> {token(:rulename, Util.rulename(Enum.reverse(acc))), input}
    end
  end

  # repeat = 1*DIGIT / (*DIGIT "*" *DIGIT)
  defp repeat(input) do
    case num input, 10 do
      {from, [?*|rest]} -> case num rest, 10 do
        {to, rest} -> {from, to, rest}
        _ -> {from, :infinity, rest}
      end
      {from, rest} -> {from, from, rest}
      nil -> case input do
        [?*|rest] -> case num rest, 10 do
          nil -> {0, :infinity, rest}
          {to, rest} -> {0, to, rest}
        end
        _ -> nil
      end
    end
  end

  # *WSP
  defp zero_or_more_wsp(input) do
    case input do
      [char|rest] -> if Core.wsp?(char) do
        zero_or_more_wsp rest
      else
        input
      end
      _ -> input
    end
  end

  # *c-wsp
  defp zero_or_more_cwsp(input, acc \\ []) do
    case c_wsp input do
      nil -> {:lists.flatten(Enum.reverse(acc)), input}
      {match, rest} -> zero_or_more_cwsp rest, [match|acc]
    end
  end

  # c-wsp = WSP / (c-nl WSP)
  defp c_wsp(input) do
    case input do
      [char|rest] -> if Core.wsp? char do
        {[char], rest}
      else
        c_nl_wsp input
      end
      _ -> nil
    end
  end

  # c-nl WSP
  defp c_nl_wsp(input) do
    case c_nl input do
      nil -> nil
      {match, [char|rest]} -> if Core.wsp? char do
        {match ++ [char], rest}
      else
        nil
      end
      _ -> nil
    end
  end

  # c-nl = comment / CRLF ; comment or newline
  defp c_nl(input) do
    case comment input do
      nil -> case crlf input do
        nil -> nil
        r -> r
      end
      r -> r
    end
  end

  # comment = ";" *(WSP / VCHAR) CRLF
  defp comment(input) do
    case input do
      [?;|rest] -> comment_tail rest
      _ -> nil
    end
  end

  defp comment_tail(input, acc \\ []) do
    case crlf(input) do
      nil -> case input do
        [char|rest] -> if Core.wsp?(char) or Core.vchar?(char) do
          comment_tail rest, [char|acc]
        else
          nil
        end
        _ -> nil
      end
      {match, rest} -> {Enum.reverse(acc) ++ match, rest}
    end
  end

  # char-val = DQUOTE *(%x20-21 / %x23-7E) DQUOTE
  # ; quoted string of SP and VCHAR without DQUOTE
  #
  # ABNF permits the specification of literal text strings directly,
  # enclosed in quotation-marks.  Hence:
  #
  #       command     =  "command string"
  #
  # Literal text strings are interpreted as a concatenated set of
  # printable characters.
  #
  # NOTE: ABNF strings are case-insensitive and the character set for these
  # strings is us-ascii.
  #
  # Hence: rulename = "abc" and: rulename = "aBc" will match "abc", "Abc",
  # "aBc", "abC", "ABc", "aBC", "AbC", and "ABC".
  # To specify a rule that IS case SENSITIVE, specify the characters
  # individually.
  defp char_val(input) do
    case input do
      [char|rest] -> if Core.dquote? char do
        char_val_tail rest
      end
      _ -> nil
    end
  end

  defp char_val_tail(input, acc \\ []) do
    case input do
      [char|rest] ->
        if((char >= 0x20 and char <= 0x21) or (char >= 0x23 and char <= 0x7E)) do
          char_val_tail rest, [char|acc]
        else
          if Core.dquote? char do
            s = String.downcase to_string(Enum.reverse(acc))
            {
              token(:char_val, %{
                string: s,
                length: String.length(s)
              }),
              rest
            }
          else
            nil
          end
        end
      _ -> nil
    end
  end

  # num-val = "%" (bin-val / dec-val / hex-val)
  #
  # bin-val = "b" 1*BIT [ 1*("." 1*BIT) / ("-" 1*BIT) ]
  # ; series of concatenated bit values or single ONEOF range
  #
  # dec-val = "d" 1*DIGIT [ 1*("." 1*DIGIT) / ("-" 1*DIGIT) ]
  #
  # hex-val = "x" 1*HEXDIG [ 1*("." 1*HEXDIG) / ("-" 1*HEXDIG) ]
  defp num_val(input) do
    case input do
      [?%, type|rest] -> cond do
        (type === ?b or type === ?B) -> num_val_tail rest, 2
        (type === ?d or type === ?D) -> num_val_tail rest, 10
        (type === ?x or type === ?X) -> num_val_tail rest, 16
        true -> nil
      end
      _ -> nil
    end
  end

  defp num_val_tail(input, base) do
    case num input, base do
      nil -> nil
      {n, [?.|_] = rest} -> num_concat_tail rest, base, [n]
      {from, [?-|rest]} -> case num rest, base do
        nil -> nil
        {to, rest} -> {token(:num_range, %{from: from, to: to}), rest}
      end
      {n, rest} -> {token(:num_range, %{from: n, to: n}), rest}
    end
  end

  defp num_concat_tail(input, base, acc) do
    case input do
      [?.|rest] -> case num rest, base do
        nil -> {token(:num_concat, Enum.reverse(acc)), input}
        {n, rest} -> num_concat_tail rest, base, [n|acc]
      end
      _ -> {token(:num_concat, Enum.reverse(acc)), input}
    end
  end

  defp num(input, base) do
    case input do
      [char|rest] -> if is_num? char, base do
        num_tail rest, base, [char]
      else
        nil
      end
      _ -> nil
    end
  end

  defp num_tail(input, base, acc) do
    case input do
      [char|rest] -> if is_num? char, base do
        num_tail rest, base, [char|acc]
      else
        {to_i(Enum.reverse(acc), base), input}
      end
      _ -> {to_i(Enum.reverse(acc), base), input}
    end
  end

  # prose-val = "<" *(%x20-3D / %x3F-7E) ">"
  # bracketed string of SP and VCHAR without ">" prose description,
  # to be used as last resort
  defp prose_val(input) do
    case input do
      [?<|rest] -> case prose_val_tail rest do
        nil -> nil
        {value, rest} -> {token(:rulename, Util.rulename(value)), rest}
      end
      _ -> nil
    end
  end

  defp prose_val_tail(input, acc \\ []) do
    case input do
      [?>|rest] -> {Enum.reverse(acc), rest}
      [char|rest] ->
        if((char >= 0x20 and char <= 0x3D) or (char >= 0x3F and char <= 0x7E)) do
          prose_val_tail rest, [char|acc]
        else
          nil
        end
      _ -> nil
    end
  end

  defp add_comments(t, comments) do
    Map.put t, :comments, (t.comments ++ comments)
  end

  defp token(type, value, comments \\ []) do
    %{
      element: type,
      value: value,
      code: nil,
      comments: comments
    }
  end

  defp crlf(input) do
    case input do
      [char1, char2|rest] -> if Core.cr?(char1) and Core.lf?(char2) do
        {[char1, char2], rest}
      else
        nil
      end
      _ -> nil
    end
  end

  defp to_i(input, base) do
    String.to_integer to_string(input), base
  end

  defp is_num?(char, base) do
    case base do
      2 -> Core.bit? char
      10 -> Core.digit? char
      16 -> Core.hexdig? char
    end
  end
end
