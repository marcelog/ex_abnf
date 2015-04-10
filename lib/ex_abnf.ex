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
