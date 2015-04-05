RFC4234
=======

Parser for ABNF grammars. ABNF is defined in: [https://tools.ietf.org/html/rfc4234](https://tools.ietf.org/html/rfc4234)


    iex(1)> grammar = RFC4234.load_file "samples/ipv4.abnf"
    iex(2)> RFC4234.apply grammar, "ipv4address", '250.246.192.34'
    {'250.246.192.34', []}

