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

    addresses = [
      '::',
      '1:2:3:4:5:6:7:8',
      '1:2:3:4:5:6:192.168.0.1',
      'FE80:0000:0000:0000:0202:B3FF:FE1E:8329',
      '::1',
      '1::1:2:3:4:5:6',
      '1:2::3:4:5:6:7',
      '::1:2:3:4:5'
    ]

    Enum.each addresses, fn(a) ->
      Logger.debug "Testing IPv6: #{inspect a}"
      {^a, 'rest', %{}} = ABNF.apply grammar, "ipv6address", a ++ 'rest', %{}
    end

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

    url = 'http://a.com:789'
    {
      'http://a.com:789',
      [],
      %{
        scheme: 'http',
        host: 'a.com',
        port: '789',
        host_type: :reg_name,
        segments: [],
        type: :abempty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://192.168.0.1/path'
    {
      'http://192.168.0.1/path',
      [],
      %{
        scheme: 'http',
        host: '192.168.0.1',
        host_type: :ipv4,
        segments: ['path'],
        type: :abempty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http:'
    {
      'http:',
      [],
      %{
        scheme: 'http',
        segments: [],
        type: :empty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http:path1/path2'
    {
      'http:path1/path2',
      [],
      %{
        scheme: 'http',
        segments: ['path1', 'path2'],
        type: :rootless
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}


    url = 'http://[v1.fe80::a+en1]/path'
    {
      'http://[v1.fe80::a+en1]/path',
      [],
      %{
        scheme: 'http',
        host: '[v1.fe80::a+en1]',
        host_type: :ipvfuture,
        segments: ['path'],
        type: :abempty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}
  end

  test "email" do
    grammar = ABNF.load_file "samples/RFC5322-no-obs.abnf"

    {'user@domain.com', '', %{
      domain: 'domain.com',
      local_part: 'user'
    }} = ABNF.apply grammar, "mailbox", 'user@domain.com', %{}

    {'<user@domain.com>', '', %{
      domain: 'domain.com',
      local_part: 'user'
    }} = ABNF.apply grammar, "mailbox", '<user@domain.com>', %{}

    {'Peter Cantropus <user@domain.com>', '', %{
      domain: 'domain.com',
      local_part: 'user',
      display_name: 'Peter Cantropus '
    }} = ABNF.apply grammar, "mailbox", 'Peter Cantropus <user@domain.com>', %{}

    {'Peter Cantropus <user@domain.com>', '', %{
      domain: 'domain.com',
      local_part: 'user',
      display_name: 'Peter Cantropus '
    }} = ABNF.apply grammar, "mailbox", 'Peter Cantropus <user@domain.com>', %{}

    {'21 Nov 1997 10:01:22 -0600', '', %{
      month: 'Nov',
      year: ' 1997 ',
      day: '21 ',
      tz: ' -0600',
      hour: '10',
      minute: '01',
      second: '22'
    }} = ABNF.apply grammar, "date_time", '21 Nov 1997 10:01:22 -0600', %{}

    {'Received: from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600\r\n', '', %{
      day: ' 21 ',
      domain: 'x.y.test',
      hour: '10',
      minute: '01',
      month: 'Nov',
      second: '22',
      tz: ' -0600',
      year: ' 1997 '
    }} = ABNF.apply grammar, "Received", 'Received: from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600\r\n', %{}
  end
end
