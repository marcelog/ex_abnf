defmodule ABNF.Util do
  @moduledoc """
  Some utilities used internally.


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

  @doc """
  Normalices a rule name. It will convert it to a String.t and also downcase it.
  """
  @spec rulename(String.t() | charlist) :: String.t()
  def rulename(name) when is_list(name) do
    rulename(to_string(name))
  end

  def rulename(name) when is_binary(name) do
    String.downcase(name)
  end
end
