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
defmodule ABNF_Test do
  use ExUnit.Case
  doctest ABNF
  doctest ABNF.Util
  alias ABNF
  require Logger

  test "sdp" do
    grammar = ABNF.load_file "samples/RFC4566.abnf"
    data = to_char_list(File.read! "test/resources/sdp1.txt")
    {[
      'v=0\r\n',
      'o=alice 2890844526 2890844526 IN IP4 host.atlanta.example.com\r\n',
      's=description\r\n',
      '',
      '',
      '',
      '',
      'c=IN IP4 host.atlanta.example.com\r\n',
      '',
      't=0 0\r\n',
      '',
      '',
      'm=audio 49170 RTP/AVP 0 8 97\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:97 iLBC/8000\r\nm=video 51372 RTP/AVP 31 32\r\na=rtpmap:31 H261/90000\r\na=rtpmap:32 MPV/90000\r\n'
      ], '', %{
        version: '0',
        session_name: 'description',
        origin: %{
          username: 'alice',
          session_id: '2890844526',
          session_version: '2890844526',
          net_type: 'IN',
          address_type: 'IP4',
          unicast_address: 'host.atlanta.example.com'
        }
      }} = ABNF.apply grammar, "session-description", data, %{}
  end

  test "medium complexity" do
    grammar = ABNF.load_file "samples/path.abnf"
    {['s', 'egment'], '', ['segment']} =
      ABNF.apply grammar, "segment", 'segment', []

    {['/', 'a', ''], '', ['a']} =
      ABNF.apply grammar, "path", '/a', []

    {['/', 'aa', '/bb'], '', ['aa', 'bb']} =
      ABNF.apply grammar, "path", '/aa/bb', []
  end

  test "basic repetition and optional" do
    grammar = ABNF.load_file "samples/basic.abnf"
    {['helloworld'], ' rest', nil} =
      ABNF.apply grammar, "string1", 'helloworld rest', nil

    {['hel'], 'loworld rest', nil} =
      ABNF.apply grammar, "string2", 'helloworld rest', nil

    {['he'], 'lloworld rest', nil} =
      ABNF.apply grammar, "string3", 'helloworld rest', nil

    {['helloworld'], ' rest', nil} =
      ABNF.apply grammar, "string4", 'helloworld rest', nil

    {['3', 'helloworld'], ' rest', nil} =
      ABNF.apply grammar, "string5", '3helloworld rest', nil

    {['3', 'helloworld'], ' rest', nil} =
      ABNF.apply grammar, "string5", '3helloworld rest', nil

    {['', 'helloworld'], ' rest', nil} =
      ABNF.apply grammar, "string5", 'helloworld rest', nil
  end

  test "ipv4" do
    grammar = ABNF.load_file "samples/ipv4.abnf"

    {['1', '.', '2', '.', '3', '.', '4'], 'rest', %{ipv4address: '1.2.3.4'}} =
      ABNF.apply grammar, "ipv4address", '1.2.3.4rest', %{}

    {['192', '.', '168', '.', '0', '.', '1'], 'rest', %{ipv4address: '192.168.0.1'}} =
      ABNF.apply grammar, "ipv4address", '192.168.0.1rest', %{}

    {['255', '.', '255', '.', '255', '.', '255'], 'rest', %{ipv4address: '255.255.255.255'}} =
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
      '::1:2:3:4:5',
      'fe80::200:f8ff:fe21:67cf',
      '2001:db8::1',
      '2001:db8:a0b:12f0::1',
      'fdf8:f53b:82e4::53',
      '2001:db8:85a3::8a2e:370:7334',
      '::ffff:c000:0280',
      '2001:db8::2:1',
      '2001:db8::1:0:0:1',
      'FE80:0:0:0:903A::11E4',
      'FE80::903A:0:0:11E4',
      '2001:db8:122:344::192.0.2.33',
      '2001:db8:122:344:c0:2:2100::',
      '2001:db8:122:3c0:0:221::',
      '2001:db8:122:c000:2:2100::',
      '2001:db8:1c0:2:21::',
      '2001:db8:c000:221::',
      '::1',
      '::',
      '0:0:0:0:0:0:0:1',
      '0:0:0:0:0:0:0:0',
      '2001:DB8:0:0:8:800:200C:417A',
      'FF01:0:0:0:0:0:0:101',
      '2001:DB8::8:800:200C:417A',
      'FF01::101',
      'fe80::217:f2ff:fe07:ed62',
      '2001:0000:1234:0000:0000:C1C0:ABCD:0876',
      '3ffe:0b00:0000:0000:0001:0000:0000:000a',
      'FF02:0000:0000:0000:0000:0000:0000:0001',
      '0000:0000:0000:0000:0000:0000:0000:0001',
      '0000:0000:0000:0000:0000:0000:0000:0000',
      '2::10',
      'ff02::1',
      'fe80::',
      '2002::',
      '2001:db8::',
      '2001:0db8:1234::',
      '::ffff:0:0',
      '::1',
      '1:2:3:4:5:6:7:8',
      '1:2:3:4:5:6::8',
      '1:2:3:4:5::8',
      '1:2:3:4::8',
      '1:2:3::8',
      '1:2::8',
      '1::8',
      '1::2:3:4:5:6:7',
      '1::2:3:4:5:6',
      '1::2:3:4:5',
      '1::2:3:4',
      '1::2:3',
      '1::8',
      '::2:3:4:5:6:7:8',
      '::2:3:4:5:6:7',
      '::2:3:4:5:6',
      '::2:3:4:5',
      '::2:3:4',
      '::2:3',
      '::8',
      '1:2:3:4:5:6::',
      '1:2:3:4:5::',
      '1:2:3:4::',
      '1:2:3::',
      '1:2::',
      '1::',
      '1:2:3:4:5::7:8',
      '1:2:3:4::7:8',
      '1:2:3::7:8',
      '1:2::7:8',
      '1::7:8',
      '1:2:3:4:5:6:1.2.3.4',
      '1:2:3:4:5::1.2.3.4',
      '1:2:3:4::1.2.3.4',
      '1:2:3::1.2.3.4',
      '1:2::1.2.3.4',
      '1::1.2.3.4',
      '1:2:3:4::5:1.2.3.4',
      '1:2:3::5:1.2.3.4',
      '1:2::5:1.2.3.4',
      '1::5:1.2.3.4',
      '1::5:11.22.33.44',
      'fe80::217:f2ff:254.7.237.98',
      '::ffff:192.168.1.26',
      '::ffff:192.168.1.1',
      '0:0:0:0:0:0:13.1.68.3',
      '0:0:0:0:0:FFFF:129.144.52.38',
      '::13.1.68.3',
      '::FFFF:129.144.52.38',
      'fe80:0:0:0:204:61ff:254.157.241.86',
      'fe80::204:61ff:254.157.241.86',
      '::ffff:12.34.56.78',
      '::ffff:192.0.2.128',
      'fe80:0000:0000:0000:0204:61ff:fe9d:f156',
      'fe80:0:0:0:204:61ff:fe9d:f156',
      'fe80::204:61ff:fe9d:f156',
      '::1',
      'fe80::',
      'fe80::1',
      '::ffff:c000:280',
      '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
      '2001:db8:85a3:0:0:8a2e:370:7334',
      '2001:db8:85a3::8a2e:370:7334',
      '2001:0db8:0000:0000:0000:0000:1428:57ab',
      '2001:0db8:0000:0000:0000::1428:57ab',
      '2001:0db8:0:0:0:0:1428:57ab',
      '2001:0db8:0:0::1428:57ab',
      '2001:0db8::1428:57ab',
      '2001:db8::1428:57ab',
      '0000:0000:0000:0000:0000:0000:0000:0001',
      '::1',
      '::ffff:0c22:384e',
      '2001:0db8:1234:0000:0000:0000:0000:0000',
      '2001:0db8:1234:ffff:ffff:ffff:ffff:ffff',
      '2001:db8:a::123',
      'fe80::',
      '1111:2222:3333:4444:5555:6666:7777:8888',
      '1111:2222:3333:4444:5555:6666:7777::',
      '1111:2222:3333:4444:5555:6666::',
      '1111:2222:3333:4444:5555::',
      '1111:2222:3333:4444::',
      '1111:2222:3333::',
      '1111:2222::',
      '1111::',
      '1111:2222:3333:4444:5555:6666::8888',
      '1111:2222:3333:4444:5555::8888',
      '1111:2222:3333:4444::8888',
      '1111:2222:3333::8888',
      '1111:2222::8888',
      '1111::8888',
      '::8888',
      '1111:2222:3333:4444:5555::7777:8888',
      '1111:2222:3333:4444::7777:8888',
      '1111:2222:3333::7777:8888',
      '1111:2222::7777:8888',
      '1111::7777:8888',
      '::7777:8888',
      '1111:2222:3333:4444::6666:7777:8888',
      '1111:2222:3333::6666:7777:8888',
      '1111:2222::6666:7777:8888',
      '1111::6666:7777:8888',
      '::6666:7777:8888',
      '1111:2222:3333::5555:6666:7777:8888',
      '1111:2222::5555:6666:7777:8888',
      '1111::5555:6666:7777:8888',
      '::5555:6666:7777:8888',
      '1111:2222::4444:5555:6666:7777:8888',
      '1111::4444:5555:6666:7777:8888',
      '::4444:5555:6666:7777:8888',
      '1111::3333:4444:5555:6666:7777:8888',
      '::3333:4444:5555:6666:7777:8888',
      '::2222:3333:4444:5555:6666:7777:8888',
      '1111:2222:3333:4444:5555:6666:123.123.123.123',
      '1111:2222:3333:4444:5555::123.123.123.123',
      '1111:2222:3333:4444::123.123.123.123',
      '1111:2222:3333::123.123.123.123',
      '1111:2222::123.123.123.123',
      '1111::123.123.123.123',
      '::123.123.123.123',
      '1111:2222:3333:4444::6666:123.123.123.123',
      '1111:2222:3333::6666:123.123.123.123',
      '1111:2222::6666:123.123.123.123',
      '1111::6666:123.123.123.123',
      '::6666:123.123.123.123',
      '1111:2222:3333::5555:6666:123.123.123.123',
      '1111:2222::5555:6666:123.123.123.123',
      '1111::5555:6666:123.123.123.123',
      '::5555:6666:123.123.123.123',
      '1111:2222::4444:5555:6666:123.123.123.123',
      '1111::4444:5555:6666:123.123.123.123',
      '::4444:5555:6666:123.123.123.123',
      '1111::3333:4444:5555:6666:123.123.123.123',
      '::2222:3333:4444:5555:6666:123.123.123.123',
      '::0:0:0:0:0:0:0',
      '::0:0:0:0:0:0',
      '::0:0:0:0:0',
      '::0:0:0:0',
      '::0:0:0',
      '::0:0',
      '::0',
      '0:0:0:0:0:0:0::',
      '0:0:0:0:0:0::',
      '0:0:0:0:0::',
      '0:0:0:0::',
      '0:0:0::',
      '0:0::',
      '0::',
      '0:a:b:c:d:e:f::',
      '::0:a:b:c:d:e:f',
      'a:b:c:d:e:f:0::'
    ]

    Enum.each addresses, fn(a) ->
      Logger.debug "Testing IPv6: #{inspect a}"
      {ret, 'rest', %{}} = ABNF.apply grammar, "ipv6address", a ++ 'rest', %{}
      ^a = :lists.flatten ret
    end

  end

  test "uri" do
    grammar = ABNF.load_file "samples/RFC3986.abnf"
    url = 'http://user:pass@host.com:421/some/path?k1=v1&k2=v2#one_fragment'
    {
      ['http', ':', '//user:pass@host.com:421/some/path', '?k1=v1&k2=v2', '#one_fragment'],
      '',
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
      ['http', ':', '/path', '', ''],
      '',
      %{
        scheme: 'http',
        segments: ['path'],
        type: :absolute
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://a.com'
    {
      ['http', ':', '//a.com', '', ''],
      '',
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
      ['http', ':', '//a.com:789', '', ''],
      '',
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
      ['http', ':', '//192.168.0.1/path', '', ''],
      '',
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
      ['http', ':', '', '', ''],
      '',
      %{
        scheme: 'http',
        segments: [],
        type: :empty
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http:path1/path2'
    {
      ['http', ':', 'path1/path2', '', ''],
      '',
      %{
        scheme: 'http',
        segments: ['path1', 'path2'],
        type: :rootless
      }
    } = ABNF.apply grammar, "uri", url, %{segments: []}


    url = 'http://[v1.fe80::a+en1]/path'
    {
      ['http', ':', '//[v1.fe80::a+en1]/path', '', ''],
      '',
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

    {['user@domain.com'], '', %{
      domain: 'domain.com',
      local_part: 'user'
    }} = ABNF.apply grammar, "mailbox", 'user@domain.com', %{}

    {['<user@domain.com>'], '', %{
      domain: 'domain.com',
      local_part: 'user'
    }} = ABNF.apply grammar, "mailbox", '<user@domain.com>', %{}

    {['Peter Cantropus <user@domain.com>'], '', %{
      domain: 'domain.com',
      local_part: 'user',
      display_name: 'Peter Cantropus '
    }} = ABNF.apply grammar, "mailbox", 'Peter Cantropus <user@domain.com>', %{}

    {['Peter Cantropus <user@domain.com>'], '', %{
      domain: 'domain.com',
      local_part: 'user',
      display_name: 'Peter Cantropus '
    }} = ABNF.apply grammar, "mailbox", 'Peter Cantropus <user@domain.com>', %{}

    {[[], '21Nov1997', '10:01:22-0600', []], '', %{
      month: 'Nov',
      year: '1997',
      day: '21',
      tz: '-0600',
      hour: '10',
      minute: '01',
      second: '22'
    }} = ABNF.apply grammar, "date_time", '21 Nov 1997 10:01:22 -0600', %{}

    {['Received:', ' from node.example by x.y.test', ';', '21Nov199710:01:22-0600', '\r\n'], '', %{
      day: '21',
      domain: 'x.y.test',
      hour: '10',
      minute: '01',
      month: 'Nov',
      second: '22',
      tz: '-0600',
      year: '1997'
    }} = ABNF.apply grammar, "Received", 'Received: from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600\r\n', %{}
  end
end
