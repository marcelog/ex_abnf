defmodule RFC4234 do
  alias RFC4234.ABNF, as: ABNF
  alias RFC4234.Interpreter, as: Interpreter

  @moduledoc """
  The RFC 4234 that can be found at https://tools.ietf.org/html/rfc4234
  """

  @doc """
  Loads a set of abnf rules from a file.
  """
  @spec load_file(String.t) :: ABNF.grammar
  def load_file(file) do
    data = File.read! file
    load to_char_list(data)
  end

  @doc """
  Returns the abnf rules found in the given char list.
  """
  @spec load([byte]) :: ABNF.grammar
  def load(input) do
    case ABNF.rulelist input do
      {%{rulelist: rules}, ''} -> rules
      {_rlist, rest} -> throw {:incomplete_parsing, rest}
      _ -> throw {:invalid_grammar, input}
    end
  end

  @doc """
  Parses an input given a gramar, looking for the given rule.
  """
  @spec apply(ABNF.grammar, String.t, [byte], term) :: ABNF.result
  def apply(grammar, rule, input, state \\ nil) do
    Interpreter.run grammar, rule, input, state
  end
end
