defmodule ABNF.Grammar do
  alias ABNF.Core, as: Core
  alias ABNF.Util, as: Util

  @type grammar :: Map

  # rulelist = 1*( rule / (*c-wsp c-nl) )
  @spec rulelist([byte]) :: Map
  def rulelist(input) do
    case rule input do
      {{name, elements, reduce_code}, rest} ->
        rulelist_tail rest, (Map.put %{}, name, %{elements: elements, code: reduce_code})
      _ ->
        {_wsps, rest} = c_wsps input
        case c_nl rest do
          {_c, rest} -> rulelist_tail rest, %{}
          _ -> nil
        end
    end
  end

  # rule = rulename defined-as elements [code] c-nl
  #  ; continues if next line starts with white space
  defp rule(input) do
    case rulename input do
      {name, rest} -> case defined_as rest do
        {_defas, rest} -> case elements rest do
          {e, rest} ->
            {reduce_code, rest} = case code rest do
              nil -> {nil, rest}
              r -> r
            end
            case c_nl rest do
              {_c, rest} -> {{name.rulename, e.elements, reduce_code}, rest}
              _ -> nil
            end
          _ -> nil
        end
        _ -> nil
      end
      _ -> nil
    end
  end

  # !!! *OCTET !!! CRLF
  defp code(input) do
    case input do
      [?!, ?!, ?!|rest] -> code_tail rest
      _ -> nil
    end
  end

  # rulename = ALPHA *(ALPHA / DIGIT / "-")
  defp rulename(input) do
    case input do
      [char|rest] -> if Core.alpha? char do
        rulename_tail rest, [char]
      else
        nil
      end
      _ -> nil
    end
  end


  # defined-as = *c-wsp ("=" / "=/") *c-wsp
  #  ; basic rules definition and incremental alternatives
  defp defined_as(input) do
    case c_wsps input do
      {_wsps1, [?=, ?/|rest]} ->
        {_wsps2, rest} = c_wsps rest
        {token(:defined_as, nil), rest}
      {_wsps1, [?=|rest]} ->
        {_wsps2, rest} = c_wsps rest
        {token(:defined_as, nil), rest}
      _ -> nil
    end
  end

  # elements = alternation *c-wsp
  defp elements(input) do
    case alternation input do
      {a, rest} ->
        {_wsps, rest} = c_wsps rest
        {token(:elements, a.alternation), rest}
      _ -> nil
    end
  end

  # alternation = concatenation *(*c-wsp "/" *c-wsp concatenation)
  defp alternation(input) do
    case concatenation input do
      {c, rest} -> alternation_tail rest, [c]
      _ -> nil
    end
  end

  # *(*c-wsp "/" *c-wsp concatenation)
  defp alternation_tail(input, acc) do
    case c_wsps input do
      {_wsps1, [?/|rest]} ->
        {_wsps2, rest} = c_wsps rest
        case concatenation rest do
          {c, rest} ->
            alternation_tail rest, [c|acc]
          _ -> {token(:alternation, Enum.reverse(acc)), input}
        end
      _ -> {token(:alternation, Enum.reverse(acc)), input}
    end
  end

  # concatenation = repetition *(1*c-wsp repetition)
  defp concatenation(input) do
    case repetition input do
      {r, rest} -> concatenation_tail rest, [r]
      _ -> nil
    end
  end

  # 1*c-wsp repetition
  defp concatenation_tail(input, acc) do
    case c_wsps input do
      {[], input} -> {token(:concatenation, Enum.reverse(acc)), input}
      {_wsps, rest} -> case repetition rest do
        {r, rest} -> concatenation_tail rest, [r|acc]
        nil -> {token(:concatenation, Enum.reverse(acc)), input}
      end
    end
  end

  # group = "(" *c-wsp alternation *c-wsp ")"
  defp group(input) do
    case input do
      [?(|rest] ->
        {_wsps1, rest} = c_wsps rest
        case alternation rest do
          {a, rest} -> case c_wsps rest do
            {_wsps2, [?)|rest]} -> {
              token(:group, a.alternation),
              rest
            }
            _ -> nil
          end
          _ -> nil
        end
      _ -> nil
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

  # option = "[" *c-wsp alternation *c-wsp "]"
  defp option(input) do
    case input do
      [?[|rest] ->
        {_wsps1, rest} = c_wsps rest
        case alternation rest do
          {a, rest} -> case c_wsps rest do
            {_wsps2, [?]|rest]} -> {
              token(:option, a.alternation),
              rest
            }
            _ -> nil
          end
          _ -> nil
        end
      _ -> nil
    end
 end

  # repetition     =  [repeat] element
  defp repetition(input) do
    {r, rest} = case repeat input do
      nil -> {%{from: 1, to: 1}, input}
      r -> r
    end
    case element rest do
      {%{option: o}, rest} -> {token(:repetition, %{repeat: %{from: 0, to: 1}, element: %{option: g}}), rest}
      {e, rest} -> {token(:repetition, %{repeat: r, element: e}), rest}
      nil -> nil
    end
  end

  # repeat = 1*DIGIT / (*DIGIT "*" *DIGIT)
  defp repeat(input) do
    case nums input, '' do
      nil -> case input do
        [?*|rest] -> case nums rest, '' do
          {to, rest} -> {%{from: 0, to: to}, rest}
          _ -> {%{from: 0, to: :infinity}, rest}
        end
        _ -> nil
      end
      {from, [?*|rest]} -> case nums rest, '' do
        {to, rest} -> {%{from: from, to: to}, rest}
        nil -> {%{from: from, to: :infinity}, rest}
      end
      {from, rest} -> {%{from: from, to: from}, rest}
    end
  end

  # c-wsp = WSP / (c-nl WSP)
  defp c_wsp(input) do
    case input do
      [char|rest] -> if Core.wsp? char do
        {token(:c_wsp, [char]), rest}
      else
        case c_nl input do
          {r, [char|rest]} -> if Core.wsp? char do
            {token(:c_wsp, r), rest}
          else
            nil
          end
          _ -> nil
        end
      end
      _ -> nil
    end
  end

  # c-nl = comment / CRLF ; comment or newline
  defp c_nl(input) do
    case comment input do
      nil -> case input do
        [13,10|rest] -> {token(:c_nl, token(:crlf, '\r\n')), rest}
        [10|rest] -> {token(:c_nl, token(:crlf, '\n')), rest}
        _ -> nil
      end
      {r, rest} -> {token(:c_nl, r), rest}
    end
  end

  # comment = ";" *(WSP / VCHAR) CRLF
  defp comment(input) do
    case input do
      [?;|rest] -> case comment_tail rest, '' do
        {result, [13,10|rest]} -> {result, rest}
        {result, [10|rest]} -> {result, rest}
        _ -> nil
      end
      _ -> nil
    end
  end

  # char-val = DQUOTE *(%x20-21 / %x23-7E) DQUOTE
  # ; quoted string of SP and VCHAR without DQUOTE
  defp char_val(input) do
    case input do
      [?"|rest] -> case char_val_tail rest, '' do
        {result, [?"|rest]} -> {result, rest}
        _ -> nil
      end
      _ -> nil
    end
  end

  # num-val = "%" (bin-val / dec-val / hex-val)
  defp num_val(input) do
    case input do
      [?%|rest] -> case bin_val rest do
        nil -> case dec_val rest do
          nil -> hex_val rest
          r -> r
        end
        r -> r
      end
      _ -> nil
    end
  end

  # bin-val = "b" 1*BIT [ 1*("." 1*BIT) / ("-" 1*BIT) ]
  # ; series of concatenated bit values or single ONEOF range
  defp bin_val(input) do
    case input do
      [b, digit|rest] -> if((b == ?b or b == ?B) and (digit? digit, 2)) do
        num_val_tail rest, 2, [digit]
      else
        nil
      end
      _ -> nil
    end
  end

  # dec-val = "d" 1*DIGIT [ 1*("." 1*DIGIT) / ("-" 1*DIGIT) ]
  defp dec_val(input) do
    case input do
      [d, digit|rest] -> if((d == ?d or d == ?D) and (digit? digit, 10)) do
        num_val_tail rest, 10, [digit]
      else
        nil
      end
      _ -> nil
    end
  end

  # hex-val = "x" 1*HEXDIG [ 1*("." 1*HEXDIG) / ("-" 1*HEXDIG) ]
  defp hex_val(input) do
    case input do
      [x, digit|rest] -> if((x == ?x or x == ?X) and (digit? digit, 16)) do
        num_val_tail rest, 16, [digit]
      else
        nil
      end
      _ -> nil
    end
  end

  # prose-val = "<" *(%x20-3D / %x3F-7E) ">"
  #  ; bracketed string of SP and VCHAR without angles
  #  ; prose description, to be used as last resort
  defp prose_val(input) do
    case input do
      [?<|rest] -> case prose_val_content rest, '' do
        {c, [?>|rest]} -> {token(:prose, c), rest}
        _ -> nil
      end
      _ -> nil
    end
  end

  # ( rule / (*c-wsp c-nl) )
  defp rulelist_tail(input, acc) do
    case rule input do
      {{name, value, reduce_code}, rest} ->
        rulelist_tail rest, (Map.put acc, name, %{elements: value, code: reduce_code})
      _ ->
        {_wsps, rest} = c_wsps input
        case c_nl rest do
          {_c, rest} -> rulelist_tail rest, acc
          _ -> {token(:rulelist, acc), input}
        end
    end
  end

  # *OCTET --- CRLF
  defp code_tail(input, acc \\ '') do
    case input do
      [?!, ?!, ?!, 13, 10|rest] -> {to_string(Enum.reverse(acc)), [13, 10|rest]}
      [?!, ?!, ?!, 10|rest] -> {to_string(Enum.reverse(acc)), [10|rest]}
      [char|rest] -> code_tail rest, [char|acc]
      _ -> nil
    end
  end

  # Rule names are case-insensitive
  # The names <rulename>, <Rulename>, <RULENAME>, and <rUlENamE> all
  # refer to the same rule.
  # *(ALPHA / DIGIT / "-")
  defp rulename_tail(input, acc) do
    case input do
      [char|rest] -> if (Core.alpha? char) or (Core.digit? char) or (char === ?-) do
        rulename_tail rest, [char|acc]
      else
        n = Util.normalize_rule_name Enum.reverse(acc)
        {token(:rulename, n), input}
      end
      _ ->
        n = Util.normalize_rule_name Enum.reverse(acc)
        {token(:rulename, n), input}
    end
  end

  # *(WSP / VCHAR) Reduces consecutive wsp's to just 1.
  defp comment_tail(input, acc) do
    case input do
      [char|rest] -> if Core.wsp? char do
        case acc do
          [acc_c|_] -> if Core.wsp? acc_c do
            comment_tail rest, acc
          else
            comment_tail rest, [char|acc]
          end
          _ -> comment_tail rest, [char|acc]
        end
      else
        if Core.vchar? char do
          comment_tail rest, [char|acc]
        else
          {token(:comment, Enum.reverse(acc)), input}
        end
      end
      _ -> {token(:comment, Enum.reverse(acc)), input}
    end
  end

  # 1*DIGIT
  defp nums(input, acc) do
    case input do
      [char|rest] -> if Core.digit? char do
        nums rest, [char|acc]
      else
        case acc do
          '' -> nil
          _ -> {Util.to_num(Enum.reverse(acc)), input}
        end
      end
      _ -> case acc do
        '' -> nil
        _ -> {Util.to_num(Enum.reverse(acc)), input}
      end
    end
  end

  defp num_val_tail(input, base, acc) do
    case input do
      [?., digit|rest] -> if digit? digit, base do
        num_concat_tail rest, base, [digit], [acc]
      else
        {token(token_value(base), Util.to_num(Enum.reverse(acc), base)), input}
      end
      [?-, digit|rest] -> if digit? digit, base do
        num_range_tail rest, base, [digit], acc
      else
        {token(token_value(base), Util.to_num(Enum.reverse(acc), base)), input}
      end
      [digit|rest] -> if digit? digit, base do
        num_val_tail rest, base, [digit|acc]
      else
        {token(token_value(base), Util.to_num(Enum.reverse(acc), base)), input}
      end
      _ -> {token(token_value(base), Util.to_num(Enum.reverse(acc), base)), input}
    end
  end

  # 1*("." 1*HEXDIG) also 1*("." 1*DIGIT) and 1*("." 1*BIT)
  defp num_concat_tail(
    [?., digit|rest] = input, base, current_num_acc, nums_so_far_acc
  ) do
    if digit? digit, base do
      num_concat_tail rest, base, [digit], [current_num_acc|nums_so_far_acc]
    else
      new_acc = Enum.reverse([current_num_acc|nums_so_far_acc])
      nums = for n <- new_acc, do: Util.to_num(Enum.reverse(n), base)
      {token(token_concat(base), nums), input}
    end
  end

  defp num_concat_tail([digit|rest] = input, base, current_num_acc, nums_so_far_acc) do
    if digit? digit, base do
      num_concat_tail rest, base, [digit|current_num_acc], nums_so_far_acc
    else
      new_acc = Enum.reverse([current_num_acc|nums_so_far_acc])
      nums = for n <- new_acc, do: Util.to_num(Enum.reverse(n), base)
      {token(token_concat(base), nums), input}
    end
  end

  defp num_concat_tail(input, base, current_num_acc, nums_so_far_acc) do
    new_acc = Enum.reverse([current_num_acc|nums_so_far_acc])
    nums = for n <- new_acc, do: Util.to_num(Enum.reverse(n), base)
    {token(token_concat(base), nums), input}
  end

  # ("-" 1*HEXDIG) also ("-" 1*DIGIT) and ("-" 1*BIT)
  defp num_range_tail([digit|rest] = input, base, max, min) do
    if digit? digit, base do
      num_range_tail rest, base, [digit|max], min
    else
      max = Util.to_num Enum.reverse(max), base
      min = Util.to_num Enum.reverse(min), base
      {token(token_range(base), {min, max}), input}
    end
  end

  defp num_range_tail(input, base, max, min) do
    max = Util.to_num Enum.reverse(max), base
    min = Util.to_num Enum.reverse(min), base
    {token(token_range(base), {min, max}), input}
  end

  # *(%x20-21 / %x23-7E)
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
  defp char_val_tail(input, acc) do
    case input do
      [char|rest] ->
        if (char >= 0x20 and char <= 0x21) or (char >= 0x23 and char <= 0x7E) do
          char_val_tail rest, [char|acc]
        else
          {token(:char_val, String.downcase(to_string(Enum.reverse(acc)))), input}
        end
      _ -> {token(:char_val, String.downcase(to_string(Enum.reverse(acc)))), input}
    end
  end

  defp prose_val_content('', acc) do
    {Enum.reverse(acc), ''}
  end

  defp prose_val_content([?>|_] = input, acc) do
    {Enum.reverse(acc), input}
  end

  defp prose_val_content([char|rest], acc) do
    if (char >= 0x20 and char <= 0x3D) or (char >= 0x3F and char <= 0x7E) do
      prose_val_content rest, [char|acc]
    else
      nil
    end
  end

  # *c-wsp
  defp c_wsps(input, acc \\ []) do
    case c_wsp input do
      nil -> {Enum.reverse(acc), input}
      {r, rest} -> c_wsps rest, [r|acc]
    end
  end

  defp token(name, value) do
    Map.put %{}, name, value
  end

  defp token_value(base) do
    case base do
      2 -> :bit_val
      10 -> :dec_val
      16 -> :hex_val
    end
  end

  defp token_concat(base) do
    case base do
      2 -> :bit_concat
      10 -> :dec_concat
      16 -> :hex_concat
    end
  end

  defp token_range(base) do
    case base do
      2 -> :bit_range
      10 -> :dec_range
      16 -> :hex_range
    end
  end

  # DIGIT = %x30-39 ; 0-9
  defp digit?(char, base) do
    case base do
      2 -> Core.bit? char
      10 -> Core.digit? char
      16 -> Core.hexdig? char
    end
  end


end
