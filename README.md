ex_abnf
=======

Parser for ABNF grammars. ABNF is defined in: [https://tools.ietf.org/html/rfc4234](https://tools.ietf.org/html/rfc4234), which is updated in [https://tools.ietf.org/html/rfc5234](https://tools.ietf.org/html/rfc5234)


    iex(1)> grammar = ex_abnf.load_file "samples/ipv4.abnf"
    iex(2)> ABNF.apply grammar, "ipv4address", '250.246.192.34'
    {'250.246.192.34', []}

