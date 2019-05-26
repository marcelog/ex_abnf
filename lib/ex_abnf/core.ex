defmodule ABNF.Core do
  @moduledoc """
  Core rules found in the [Apendix B](https://tools.ietf.org/html/rfc4234#appendix-B) of the ABNF RFC.

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
  ALPHA = %x41-5A / %x61-7A ; A-Z / a-z
  """
  @spec alpha?(char) :: boolean
  def alpha?(char) do
    (char >= 0x41 and char <= 0x5A) or
      (char >= 0x61 and char <= 0x7A)
  end

  @doc """
  BIT = "0" / "1"
  """
  @spec bit?(char) :: boolean
  def bit?(char) do
    char === 0x30 or char === 0x31
  end

  @doc """
  CHAR = %x01-7F ; any 7-bit US-ASCII character, excluding NUL
  """
  @spec char?(char) :: boolean
  def char?(char) do
    char >= 0x01 and char <= 0x7F
  end

  @doc """
  CR = %x0D ; carriage return
  """
  @spec cr?(char) :: boolean
  def cr?(char) do
    char === 0x0D
  end

  @doc """
  CTL = %x00-1F / %x7F ; controls
  """
  @spec ctl?(char) :: boolean
  def ctl?(char) do
    char >= 0x00 and char <= 0x1F
  end

  @doc """
  DIGIT = %x30-39; 0-9
  """
  @spec digit?(char) :: boolean
  def digit?(char) do
    char >= 0x30 and char <= 0x39
  end

  @doc """
  DQUOTE = %x22 ; " (Double Quote)
  """
  @spec dquote?(char) :: boolean
  def dquote?(char) do
    char === 0x22
  end

  @doc """
  HEXDIG = DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
  """
  @spec hexdig?(char) :: boolean
  def hexdig?(char) do
    digit?(char) or
      (char >= 0x41 and char <= 0x46) or
      (char >= 0x61 and char <= 0x66)
  end

  @doc """
  HTAB = %x09 ; horizontal tab
  """
  @spec htab?(char) :: boolean
  def htab?(char) do
    char === 0x09
  end

  @doc """
  LF = %x0A ; linefeed
  """
  @spec lf?(char) :: boolean
  def lf?(char) do
    char === 0x0A
  end

  @doc """
  OCTET = %x00-FF ; 8 bits of data
  """
  @spec octet?(char) :: boolean
  def octet?(char) do
    char >= 0x00 and char <= 0xFF
  end

  @doc """
  SP = %x20
  """
  @spec sp?(char) :: boolean
  def sp?(char) do
    char === 0x20
  end

  @doc """
  VCHAR = %x21-7E ; visible (printing) characters
  """
  @spec vchar?(char) :: boolean
  def vchar?(char) do
    char >= 0x21 and char <= 0x7E
  end

  @doc """
  WSP = SP / HTAB ; white space
  """
  @spec wsp?(char) :: boolean
  def wsp?(char) do
    sp?(char) or htab?(char)
  end
end
