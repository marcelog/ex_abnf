defmodule RFC4234.Core do
  @moduledoc """
  This module includes the core rules (Appendix B).
  """

  # DQUOTE = %x22 ; " (Double Quote)
  @spec dquote?(byte) :: boolean
  def dquote?(char) do
    char === 0x22
  end

  # OCTET = %x00-FF ; 8 bits of data
  @spec octet?(byte) :: boolean
  def octet?(char) do
    char >= 0x00 and char <= 0xFF
  end

  # BIT = "0" / "1"
  @spec bit?(byte) :: boolean
  def bit?(char) do
    char === ?1 or char === ?0
  end

  # DIGIT = %x30-39 ; 0-9
  @spec digit?(byte) :: boolean
  def digit?(char) do
    char >= 0x30 and char <= 0x39
  end

  # HEXDIG = DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
  @spec hexdig?(byte) :: boolean
  def hexdig?(char) do
    digit?(char) or
    (char >= 0x41 and char <= 0x46) or
    (char >= 0x61 and char <= 0x66)
  end

  # SP = %x20
  @spec sp?(byte) :: boolean
  def sp?(char) do
    char === 0x20
  end

  # HTAB = %x09 ; horizontal tab
  @spec htab?(byte) :: boolean
  def htab?(char) do
    char === 0x09
  end

  # VCHAR = %x21-7E ; visible (printing) character
  @spec vchar?(byte) :: boolean
  def vchar?(char) do
    char >= 0x21 and char <= 0x7E
  end

  # WSP = SP / HTAB ; white space
  @spec wsp?(byte) :: boolean
  def wsp?(char) do
    sp?(char) or htab?(char)
  end

  # ALPHA = %x41-5A / %x61-7A   ; A-Z / a-z
  @spec alpha?(byte) :: boolean
  def alpha?(char) do
    (char >= 0x41 and char <= 0x5A) or
    (char >= 0x61 and char <= 0x7A)
  end
end
