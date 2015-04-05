defmodule ABNF do
  alias ABNF.Grammar, as: Grammar
  alias ABNF.Interpreter, as: Interpreter

  @moduledoc """
  The RFC 4234 that can be found at https://tools.ietf.org/html/rfc4234 and
  the RFC 5234 that can be found at https://tools.ietf.org/html/rfc5234
  """

  @doc """
  Loads a set of abnf rules from a file.
  """
  @spec load_file(String.t) :: Grammar.grammar
  def load_file(file) do
    data = File.read! file
    load to_char_list(data)
  end

  @doc """
  Returns the abnf rules found in the given char list.
  """
  @spec load([byte]) :: Grammar.grammar
  def load(input) do
    case Grammar.rulelist input do
      {%{rulelist: rules}, ''} -> rules
      {_rlist, rest} -> throw {:incomplete_parsing, rest}
      _ -> throw {:invalid_grammar, input}
    end
  end

  @doc """
  Parses an input given a gramar, looking for the given rule.
  """
  @spec apply(Grammar.grammar, String.t, [byte], term) :: Grammar.result
  def apply(grammar, rule, input, state \\ nil) do
    Interpreter.run grammar, rule, input, state
  end
end
