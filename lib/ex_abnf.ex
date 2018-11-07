defmodule ABNF do
  @moduledoc """
  Main module. ABNF parser as described in [RFC4234](https://tools.ietf.org/html/rfc4234)
  and [RFC5234](https://tools.ietf.org/html/rfc5234)

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

  alias ABNF.Grammar, as: Grammar
  alias ABNF.Interpreter, as: Interpreter
  alias ABNF.CaptureResult, as: CaptureResult
  require Logger
  @doc """
  Loads a set of abnf rules from a file.
  """
  @spec load_file(String.t) :: Grammar.t | no_return
  def load_file(file) do
    data = File.read! file
    load to_charlist(data)
  end

  @doc """
  Returns the abnf rules found in the given char list.
  """
  @spec load([byte]) :: Grammar.t | no_return
  def load(input) do
    case Grammar.rulelist input do
      {rules, ''} -> rules
      {_rlist, rest} -> throw {:incomplete_parsing, rest}
      _ -> throw {:invalid_grammar, input}
    end
  end

  @doc """
  Parses an input given a gramar, looking for the given rule.
  """
  @spec apply(Grammar.t, String.t, [byte], term) :: CaptureResult.t
  def apply(grammar, rule, input, state \\ nil) do
    Interpreter.apply grammar, rule, input, state
  end
end
