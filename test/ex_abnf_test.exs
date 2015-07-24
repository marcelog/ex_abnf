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
  alias ABNF.CaptureResult, as: Res

  test "ipv4" do
    grammar = load "ipv4"

    %Res{
      input: '1.2.3.4rest',
      rest: 'rest',
      string_text: '1.2.3.4',
      string_tokens: ['1', '.', '2', '.', '3', '.', '4'],
      state: %{ipv4address: '1.2.3.4'},
      values: ["Your ip address is: 1.2.3.4"]
    } = ABNF.apply grammar, "ipv4address", '1.2.3.4rest', %{}

    %Res{
      input: '192.168.0.1rest',
      rest: 'rest',
      string_text: '192.168.0.1',
      string_tokens: ['192', '.', '168', '.', '0', '.', '1'],
      state: %{ipv4address: '192.168.0.1'},
      values: ["Your ip address is: 192.168.0.1"]
    } = ABNF.apply grammar, "ipv4address", '192.168.0.1rest', %{}

    %Res{
      input: '255.255.255.255rest',
      rest: 'rest',
      string_text: '255.255.255.255',
      string_tokens: ['255', '.', '255', '.', '255', '.', '255'],
      state: %{ipv4address: '255.255.255.255'},
      values: ["Your ip address is: 255.255.255.255"]
    } = ABNF.apply grammar, "ipv4address", '255.255.255.255rest', %{}

    nil = ABNF.apply grammar, "ipv4address", '255.255.256.255rest', %{}
  end

  test "medium complexity" do
    grammar = load "path"
    %Res{
      input: 'segment',
      rest: '',
      string_text: 'segment',
      string_tokens: ['s', 'egment'],
      state: ['segment'],
      values: _
    } = ABNF.apply grammar, "segment", 'segment', []

    %Res{
      input: '/a',
      rest: '',
      string_text: '/a',
      string_tokens: ['/a'],
      state: ['a'],
      values: _
    } = ABNF.apply grammar, "path", '/a', []

    %Res{
      input: '/aa/bb',
      rest: '',
      string_text: '/aa/bb',
      string_tokens: ['/aa/bb'],
      state: ['aa', 'bb'],
      values: _
    } = ABNF.apply grammar, "path", '/aa/bb', []
  end

  test "basic repetition and optional" do
    grammar = load "basic"
    %Res{
      input: 'helloworld rest',
      rest: ' rest',
      string_text: 'helloworld',
      string_tokens: ['helloworld'],
      state: nil,
      values: _
    } = ABNF.apply grammar, "string1", 'helloworld rest', nil

    %Res{
      input: 'helloworld rest',
      rest: 'loworld rest',
      string_text: 'hel',
      string_tokens: ['hel'],
      state: nil,
      values: _
    } = ABNF.apply grammar, "string2", 'helloworld rest', nil

    %Res{
      input: 'helloworld rest',
      rest: 'lloworld rest',
      string_text: 'he',
      string_tokens: ['he'],
      state: nil,
      values: _
    } = ABNF.apply grammar, "string3", 'helloworld rest', nil

    %Res{
      input: 'helloworld rest',
      rest: ' rest',
      string_text: 'helloworld',
      string_tokens: ['helloworld'],
      state: nil,
      values: _
    } = ABNF.apply grammar, "string4", 'helloworld rest', nil

    %Res{
      input: '3helloworld rest',
      rest: ' rest',
      string_text: '3helloworld',
      string_tokens: ['3', 'helloworld'],
      state: nil,
      values: _
    } = ABNF.apply grammar, "string5", '3helloworld rest', nil

    %Res{
      input: 'helloworld rest',
      rest: ' rest',
      string_text: 'helloworld',
      string_tokens: ['', 'helloworld'],
      state: nil,
      values: _
    } = ABNF.apply grammar, "string5", 'helloworld rest', nil
  end

  test "ipv6" do
    grammar = load "ipv6"

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
      string = a ++ 'rest'
      %Res{
        input: ^string,
        rest: 'rest',
        string_text: ^a,
        state: %{}
      } = ABNF.apply grammar, "ipv6address", string, %{}
    end
  end

  test "uri" do
    grammar = load "RFC3986"
    url = 'http://user:pass@host.com:421/some/path?k1=v1&k2=v2#one_fragment'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        fragment: 'one_fragment',
        host: 'host.com',
        host_type: :reg_name,
        port: '421',
        query: 'k1=v1&k2=v2',
        scheme: 'http',
        userinfo: 'user:pass',
        segments: ['some', 'path'],
        type: :abempty
      },
      string_text: ^url,
      string_tokens: [
        'http',
        ':',
        '//user:pass@host.com:421/some/path',
        '?k1=v1&k2=v2',
        '#one_fragment'
      ],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http:/path'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        segments: ['path'],
        type: :absolute
      },
      string_text: ^url,
      string_tokens: ['http', ':', '/path', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://a.com'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        host: 'a.com',
        host_type: :reg_name,
        type: :abempty
      },
      string_text: ^url,
      string_tokens: ['http', ':', '//a.com', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://a.com:789'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        host: 'a.com',
        port: '789',
        host_type: :reg_name,
        type: :abempty
      },
      string_text: ^url,
      string_tokens: ['http', ':', '//a.com:789', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://192.168.0.1/path'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        segments: ['path'],
        host: '192.168.0.1',
        host_type: :ipv4,
        type: :abempty
      },
      string_text: ^url,
      string_tokens: ['http', ':', '//192.168.0.1/path', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http:'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        type: :empty
      },
      string_text: ^url,
      string_tokens: ['http', ':', '', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http:path1/path2'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        segments: ['path1', 'path2'],
        type: :rootless
      },
      string_text: ^url,
      string_tokens: ['http', ':', 'path1/path2', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}

    url = 'http://[v1.fe80::a+en1]/path'
    %Res{
      input: ^url,
      rest: '',
      state: %{
        scheme: 'http',
        segments: ['path'],
        host: '[v1.fe80::a+en1]',
        host_type: :ipvfuture,
        type: :abempty
      },
      string_text: ^url,
      string_tokens: ['http', ':', '//[v1.fe80::a+en1]/path', '', ''],
      values: _
    } = ABNF.apply grammar, "uri", url, %{segments: []}
  end

  test "can reduce rule" do
    grammar = load "reduce"
    %Res{
      input: '123asd',
      rest: '',
      state: %{field: true},
      string_text: '123asd',
      string_tokens: ['123', 'asd'],
      values: [%{int: 123, string: "asd"}]
    } = ABNF.apply grammar, "composed", '123asd', %{field: false}
  end

  test "teluri" do
    grammar = load "RFC3966"

    tel = 'tel:+1-201-555-0123'
    %Res{
      input: 'tel:+1-201-555-0123',
      rest: '',
      state: %{},
      string_text: 'tel:+1-201-555-0123',
      string_tokens: ['tel:', '+1-201-555-0123'],
      values: _
    } = ABNF.apply grammar, "telephone-uri", tel, %{}

    tel = 'tel:863-1234;phone-context=+1-914-555'
    %Res{
      input: 'tel:863-1234;phone-context=+1-914-555',
      rest: '',
      state: %{},
      string_text: 'tel:863-1234;phone-context=+1-914-555',
      string_tokens: ['tel:', '863-1234;phone-context=+1-914-555'],
      values: _
    } = ABNF.apply grammar, "telephone-uri", tel, %{}
  end

  test "sdp" do
    grammar = load "RFC4566"
    data = to_char_list(File.read! "test/resources/sdp1.txt")
    %Res{
      input: ^data,
      rest: '',
      state: %{
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
      },
      string_text: ^data,
      string_tokens: [
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
      ],
      values: _
      } = ABNF.apply grammar, "session-description", data, %{}
  end

  test "sip" do
    grammar = load "RFC3261"
    data = to_char_list(File.read! "test/resources/sip1.txt")
    %Res{
      input: ^data,
      rest: '',
      state: %{
        headers: %{
          "from" => %{
            addr: %{
              hostport: %{host: "biloxi.com", port: 5060},
              scheme: "sip",
              userinfo: "bob"
            },
            display_name: "Bob "
          }
        },
        method: :register,
        request: true,
        uri: %{
          hostport: %{
            host: "registrar.biloxi.com",
            port: 1234
          },
          userinfo: "",
          scheme: "sip"
        }
      },
      string_text: ^data,
      string_tokens: [^data]
    } = ABNF.apply grammar, "SIP-message", data, %{
      headers: %{}
    }
  end

  test "email" do
    grammar = load "RFC5322-no-obs"

    email = 'user@domain.com'
    %Res{
      input: ^email,
      rest: '',
      state: %{
        domain: 'domain.com',
        local_part: 'user'
      },
      string_text: ^email,
      string_tokens: ['user@domain.com'],
      values: _
    } = ABNF.apply grammar, "mailbox", email, %{}

    email = '<user@domain.com>'
    %Res{
      input: ^email,
      rest: '',
      state: %{
        domain: 'domain.com',
        local_part: 'user'
      },
      string_text: ^email,
      string_tokens: ['<user@domain.com>'],
      values: _
    } = ABNF.apply grammar, "mailbox", email, %{}

    email = 'Peter Cantropus <user@domain.com>'
    %Res{
      input: ^email,
      rest: '',
      state: %{
        domain: 'domain.com',
        local_part: 'user',
        display_name: 'Peter Cantropus '
      },
      string_text: ^email,
      string_tokens: ['Peter Cantropus <user@domain.com>'],
      values: _
    } = ABNF.apply grammar, "mailbox", email, %{}

    input = '21 Nov 1997 10:01:22 -0600'
    %Res{
      input: ^input,
      rest: '',
      state: %{
        month: 'Nov',
        year: '1997',
        day: '21',
        tz: '-0600',
        hour: '10',
        minute: '01',
        second: '22'
      },
      string_text: ^input,
      string_tokens: [[], '21 Nov 1997 ', '10:01:22 -0600', []],
      values: _
    } = ABNF.apply grammar, "date-time", input, %{}

    input = 'Received: from node.example by x.y.test; 21 Nov 1997 10:01:22 -0600\r\n'
    %Res{
      input: ^input,
      rest: '',
      state: %{
        day: '21',
        domain: 'x.y.test',
        hour: '10',
        minute: '01',
        month: 'Nov',
        second: '22',
        tz: '-0600',
        year: '1997'
      },
      string_text: ^input,
      string_tokens: ['Received:', ' from node.example by x.y.test', ';', ' 21 Nov 1997 10:01:22 -0600', '\r\n'],
      values: _
    } = ABNF.apply grammar, "Received", input, %{}
  end

  defp load(file) do
    ABNF.load_file "test/resources/#{file}.abnf"
  end
end
