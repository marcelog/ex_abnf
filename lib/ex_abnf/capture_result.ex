defmodule ABNF.CaptureResult do
  @moduledoc """
  Capture result, used when returning a result after applying a grammar to an
  input.

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

  # original input before match
  defstruct input: '',
            # text that didn't match
            rest: '',
            # full text that matched
            string_text: '',
            # contains string parts that matched (usually 1)
            string_tokens: [],
            # real rule value
            values: nil,
            # state after match
            state: nil

  @type t :: %ABNF.CaptureResult{}
end
