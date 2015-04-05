defmodule ABNF.Util do
  @moduledoc """
  Miscelaneous utilities.
  """

  @doc """
  Normalices a rule name giving by a char list or a string, by downcase'ing it
  and replacing "-" with a "_".

  ## Examples:

      iex> ABNF.Util.normalize_rule_name 'Arule-NaME'
      "arule_name"
  """
  @spec normalize_rule_name(String.t | [byte]) :: String.t
  def normalize_rule_name(rule) when is_list(rule) do
    normalize_rule_name to_string(rule)
  end

  def normalize_rule_name(rule) when is_binary(rule) do
    String.replace(String.downcase(rule), "-", "_", global: true)
  end

  @doc """
  Transforms a char list or a string into a number in the given base.

  ## Examples:

      iex> ABNF.Util.to_num '10'
      10

      iex> ABNF.Util.to_num "10", 16
      16
  """
  def to_num(char_list, base \\ 10)

  def to_num(char_list, base) when is_list(char_list) do
    to_num to_string(char_list), base
  end

  def to_num(string, base) when is_binary(string) do
    String.to_integer string, base
  end
end
