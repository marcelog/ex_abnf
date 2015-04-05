defmodule ABNF_Test do
  use ExUnit.Case
  doctest ABNF
  doctest ABNF.Util
  alias ABNF
  require Logger

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

  test "uri" do
    grammar = ABNF.load_file "samples/RFC3986.abnf"
    url = 'http://user:pass@host.com:421/some/path?k1=v1&k2=v2#one_fragment'
    {
      'http://user:pass@host.com:421/some/path?k1=v1&k2=v2#one_fragment',
      [],
      %{
        fragment: 'one_fragment',
        host: 'host.com',
        host_type: :reg_name,
        port: '421',
        query: 'k1=v1&k2=v2',
        scheme: 'http',
        userinfo: 'user:pass',
        segments: ['some', 'path'],
        type: :abempty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}
  end
end
