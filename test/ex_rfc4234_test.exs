defmodule RFC4234_Test do
  use ExUnit.Case
  doctest RFC4234
  alias RFC4234

  test "ipv4" do
    grammar = RFC4234.load_file "samples/ipv4.abnf"
    {'1.2.3.4', 'rest'} = RFC4234.apply grammar, "ipv4address", '1.2.3.4rest'
    {'192.168.0.1', 'rest'} = RFC4234.apply grammar, "ipv4address", '192.168.0.1rest'
    {'255.255.255.255', 'rest'} = RFC4234.apply grammar, "ipv4address", '255.255.255.255rest'
    nil = RFC4234.apply grammar, "ipv4address", '255.255.256.255rest'
  end
end
