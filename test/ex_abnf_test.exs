defmodule ABNF_Test do
  use ExUnit.Case
  doctest ABNF
  doctest ABNF.Util
  alias ABNF
  require Logger

  test "medium complexity" do
    grammar = ABNF.load_file "samples/path.abnf"
    {'segment', '', ['segment']} =
      ABNF.apply grammar, "segment", 'segment', []

    {'/a', '', ['a']} =
      ABNF.apply grammar, "path", '/a', []

    {'/aa/bb', '', ['aa', 'bb']} =
      ABNF.apply grammar, "path", '/aa/bb', []
  end

  test "basic repetition and optional" do
    grammar = ABNF.load_file "samples/basic.abnf"
    {'helloworld', ' rest', nil} =
      ABNF.apply grammar, "string1", 'helloworld rest', nil

    {'hel', 'loworld rest', nil} =
      ABNF.apply grammar, "string2", 'helloworld rest', nil

    {'he', 'lloworld rest', nil} =
      ABNF.apply grammar, "string3", 'helloworld rest', nil

    {'helloworld', ' rest', nil} =
      ABNF.apply grammar, "string4", 'helloworld rest', nil

    {'3helloworld', ' rest', nil} =
      ABNF.apply grammar, "string5", '3helloworld rest', nil

    {'3helloworld', ' rest', nil} =
      ABNF.apply grammar, "string5", '3helloworld rest', nil

    {'helloworld', ' rest', nil} =
      ABNF.apply grammar, "string5", 'helloworld rest', nil
  end

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

  test "ipv6" do
    grammar = ABNF.load_file "samples/ipv6.abnf"

    {'::', 'rest', %{}} = ABNF.apply grammar, "ipv6address", '::rest', %{}
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

    url = 'http:/path'
    {
      'http:/path',
      [],
      %{
        scheme: 'http',
        segments: ['path'],
        type: :absolute
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://a.com'
    {
      'http://a.com',
      [],
      %{
        scheme: 'http',
        host: 'a.com',
        host_type: :reg_name,
        segments: [],
        type: :abempty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}
  end
end
