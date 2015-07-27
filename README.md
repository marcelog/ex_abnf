[![Build Status](https://travis-ci.org/marcelog/ex_abnf.svg)](https://travis-ci.org/marcelog/ex_abnf)

## About

A parser and interpreter for ABNF grammars.

ABNF is defined in: [https://tools.ietf.org/html/rfc4234](https://tools.ietf.org/html/rfc4234),
and updated in [https://tools.ietf.org/html/rfc5234](https://tools.ietf.org/html/rfc5234).

## Use example

    iex(1)> grammar = ABNF.load_file "test/resources/ipv4.abnf"
    iex(2)> initial_state = %{}
    iex(2)> ABNF.apply grammar, "ipv4address", '250.246.192.34', initial_state
    %ABNF.CaptureResult{
      input: '250.246.192.34',
      rest: '',
      state: %{ipv4address: '250.246.192.34'},
      string_text: '250.246.192.34',
      string_tokens: ['250', '.', '246', '.', '192', '.', '34'],
      values: ["Your ip address is: 250.246.192.34"]
    }

The result can be read as an [%ABNF.CaptureResult{}](https://github.com/marcelog/ex_abnf/blob/master/lib/ex_abnf/capture_result.ex)
where:
 * **input**: The original input
 * **rest**: The part of the input that **didn't** match.
 * **state**: The state after running all the rules applied to the input.
 * **string_text**: The rule value as a string (this might or might not be the same  as the rule value, since you can return custom values when adding a reduce code to the rule).
 * **string_tokens**: Each one of the values that compose the string (in this case, [octet, dot, octet, dot, octet, dot, octet]).
 * **values**: The rule value. In this case the value comes from the reduce code in the [grammar itself](https://github.com/marcelog/ex_abnf/blob/master/test/resources/ipv4.abnf#L6).

## More complex examples

The [unit tests](https://github.com/marcelog/ex_abnf/blob/master/test/ex_abnf_test.exs)
use different [sample RFCs](https://github.com/marcelog/ex_abnf/tree/master/test/resources) to
test the [grammar parser](https://github.com/marcelog/ex_abnf/blob/master/lib/ex_abnf/grammar.ex)
and [the interpreter](https://github.com/marcelog/ex_abnf/blob/master/lib/ex_abnf/interpreter.ex)

## How it works
This is not a parser generator, but an interpreter. It will load up an ABNF
grammar, and generate an (kind of) [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree)
for it. Then you can apply any of the rules to an input and the interpreter
will parse the input according to the rule.

## Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:ex_abnf, "~> 0.2.1"}]
end
```
Then run mix deps.get to install it.

## Adding custom code to reduce rules
After a rule, you can add your own code, for example:
```
userinfo      = *( unreserved / pct-encoded / sub-delims / ":" ) !!!
  state = Map.put state, :userinfo, rule
  {:ok, state}
!!!
```

Your code can return:
 * **{:ok, state}**: The match continues, and the new state is used for
 future calls.

 * **{:ok, state, rule_value}**: Returns a new state but also the **rule_value**
 is used as the result of the match. In YACC terms, rule_value would be the
 equivalent of $$ = ...

 * **{:error, error}**: The whole match is aborted and this error is thrown.

And your code will be called with the following bindings:

 * **state**: This is the state that you can pass when calling the initial
 **ABNF.apply** function, and is a way to keep state through the whole match,
 it can be whatever you like and can mutate through calls as long as your code
 can handle it.

 * **values**: When a rule is composed of different tokens
 (e.g: path = SEGMENT "/" SEGMENT) this contains a list with all the values of
 those tokens in order. In YACC terms, this would be the equivalent of using
 $1, $2, $3, etc. Note that a value here can be a reduced value returned by
 your own code in a previous rule.

 * **string_values**: Just like `values` but each value is a nested list of
 lists with all the characters that matched (you will usually want to flatten
 the list to get each one of the full strings).

## TODO
 * Implement [RFC7405](https://tools.ietf.org/html/rfc7405)

## Changes from 0.1.x to 0.2.x
 * In the reduce code the rule value is no longer the rule name, but the
 variable `rule`.
 * The grammar text no longer supports `cr` as the newline, one should always
 use `crlf`.
 * In the reduce code there are now available the following variables:
  * `rule`: The rule value
  * `string_values`: Like the old `tokens` variable, but contains a nested list
  of lists with the parsed strings.
  * `values`: Like the old `tokens` variable, but with the reduced values
  (could be a mixed nested list of lists containing char_lists and/or other
  kind of values).
 * Original rule names are now preserverd and only downcased, no replacements
 are done to chars (i.e: `-` to `_`).

## License
The source code is released under Apache 2 License.

Check [LICENSE](https://github.com/marcelog/ex_abnf/blob/master/LICENSE) file
for more information.
