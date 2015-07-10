[![Build Status](https://travis-ci.org/marcelog/ex_abnf.svg)](https://travis-ci.org/marcelog/ex_abnf)

## About

A parser and interpreter for ABNF grammars. ABNF is defined in:
[https://tools.ietf.org/html/rfc4234](https://tools.ietf.org/html/rfc4234),
which is updated in [https://tools.ietf.org/html/rfc5234](https://tools.ietf.org/html/rfc5234).

## Use example

    iex(1)> grammar = ABNF.load_file "samples/ipv4.abnf"
    iex(2)> ABNF.apply grammar, "ipv4address", '250.246.192.34', %{}
    {['250', '.', '246', '.', '192', '.', '34'], [], %{ipv4address: '250.246.192.34'}}

The result can be read as a tuple where the elements are:
 1. All tokens that matched (in this case, [octet, dot, octet, dot, octet, dot, octet]).
 2. The rest of the input that didn't match (empty in this case, since the whole input could be parsed).
 3. The state. The last argument of ABNF.apply/4 indicates an initial state passed through all the rules that
 is filled in the [grammar itself](https://github.com/marcelog/ex_abnf/blob/master/samples/ipv4.abnf#L5).

## More complex examples

The [unit tests](https://github.com/marcelog/ex_abnf/blob/master/test/ex_abnf_test.exs)
use different [sample RFCs](https://github.com/marcelog/ex_abnf/tree/master/samples) to test the
[grammar parser](https://github.com/marcelog/ex_abnf/blob/master/lib/grammar.ex) and
[the interpreter](https://github.com/marcelog/ex_abnf/blob/master/lib/interpreter.ex)

## How it works
This is not a parser generator, but an interpreter. It will load up an ABNF grammar,
and generate an (kind of) [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree) for it. Then
you can apply any of the rules to an input and the interpreter will parse the input according to
the rule.

## Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:ex_abnf, "~> 0.1.4"}]
end
```
Then run mix deps.get to install it.

## Adding custom code to reduce rules
After a rule, you can add your own code, for example:
```
userinfo      = *( unreserved / pct-encoded / sub-delims / ":" ) !!!
  state = Map.put state, :userinfo, userinfo
  {:ok, state}
!!!
```

Your code will be called with the following bindings:
 * state: This is the state that you can pass when calling the initial **ABNF.apply**
 function, and is a way to keep state through the whole match, it can be whatever you
 like and can mutate through calls as long as your code can handle it.

 * tokens: When a rule is composed of different tokens (e.g: path = SEGMENT "/" SEGMENT) this
 contains a list with all the values of those tokens in order. In YACC terms, this would be
 the equivalent of using $1, $2, $3, etc.

And can return:
 * {:ok, state}: The match continues, and the new state is used for
 future calls.

 * {:ok, state, rule_value}: The match continues, and the new state is used for
 future calls. Also, the **rule_value** is used as the result of the match (but it **must** be
 a char list). In YACC terms, rule_value would be the equivalent of $$ = ...

 * {:error, error}: The whole match is aborted and this error is thrown.

**NOTE**: All rules are lowercased and all dashes are replaced with "_". See
[this example](https://github.com/marcelog/ex_abnf/blob/master/samples/RFC3986.abnf#L76) for
more details.

## TODO
 * Implement [RFC7405](https://tools.ietf.org/html/rfc7405)

## License
The source code is released under Apache 2 License.

Check [LICENSE](https://github.com/marcelog/ex_abnf/blob/master/LICENSE) file for more information.
