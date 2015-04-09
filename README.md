## About

A parser and interpreter for ABNF grammars. ABNF is defined in:
[https://tools.ietf.org/html/rfc4234](https://tools.ietf.org/html/rfc4234),
which is updated in [https://tools.ietf.org/html/rfc5234](https://tools.ietf.org/html/rfc5234).

## Use example

    iex(1)> grammar = ex_abnf.load_file "samples/ipv4.abnf"
    iex(2)> ABNF.apply grammar, "ipv4address", '250.246.192.34'
    {'250.246.192.34', []}

## More complex examples

The [unit tests](https://github.com/marcelog/ex_abnf/blob/master/test/ex_abnf_test.exs)
use different [RFCs](https://github.com/marcelog/ex_abnf/tree/master/samples) to test the
[grammar parser](https://github.com/marcelog/ex_abnf/blob/master/lib/grammar.ex) and
[the interpreter](https://github.com/marcelog/ex_abnf/blob/master/lib/interpreter.ex)

## How it works
This is not a parser generator, but an interpreter. It will load up an ABNF grammar,
and generate an (kind of) [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree) for it. Then
you can apply any of the rules to an input and the interpreter will parse the input according to
the rule.

## TODO
 * Implement [RFC7405](https://tools.ietf.org/html/rfc7405)
