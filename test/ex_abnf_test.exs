defmodule ABNF_Test do
  use ExUnit.Case
  doctest ABNF
  doctest ABNF.Util
  alias ABNF

  test "ipv4" do
    grammar = ABNF.load_file "samples/ipv4.abnf"

    {'1.2.3.4', 'rest', %{ipv4address: '1.2.3.4'}} =
      ABNF.apply grammar, "ipv4address", '1.2.3.4rest', %{}

    {'192.168.0.1', 'rest', %{ipv4address: '192.168.0.1'}} =
      ABNF.apply grammar, "ipv4address", '192.168.0.1rest', %{}

    {'255.255.255.255', 'rest', %{ipv4address: '255.255.255.255'}} =
      ABNF.apply grammar, "ipv4address", '255.255.255.255rest', %{}

    nil = ABNF.apply grammar, "ipv4address", '255.255.256.255rest', %{}
  end
end
