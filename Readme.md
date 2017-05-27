# rex

A proof of concept implementation of a language to describe DFAs.


## What is wrong with regexes?

Regular expressions are used in a lot of places where they are clearly not the
best tool for the job. For example take syntax highlighting, where we should
use parsers instead. If you take a look at some source code written in a
language with built in support for regular expressions (Perl, Ruby, etc.)
you'll likely find other atrocious uses.

The problem is that regular expressions make it very easy to write expressions
that generate a lot of code and are slow (see theoretical background info).

This approach makes it really hard to write inefficient expressions. Execution
time and memory usage of a rex is roughly proportional to the length of the
expression.

Is this approach better? I don't know, decide for yourself if you like it.

### Theoretical Background

From a mathematical standpoint the problems with regular expressions are the
following:

Regular expressions are easily translated into non-deterministic finite
automata (NFA), while a computer can only execute deterministic finite state
machines (DFA). The two are mathematically equivalent and can be converted into
one another, but at a price: To convert an NFA into a DFA the number of states
in the DFA will be O(2^(n)) in the worst case. This makes execution times
unpredictable for the person writing the expression. So conversion from a NFA
to a DFA is hard and expensive.

The other way around is similar: if we have an arbitrary DFA and we want to get
a regular expression from it, conversion is also hard and the length of the
regular expression is O(2^(n)) in the worst case (where n is the number of
states in the DFA). This time you probably get a fast regex but it's really
hard to write it.

And there are extensions to regular expressions that are implemented by some
engines that take them into the area of context-sensitive languages which makes
execution times even worse.

The solution here is that if you try to specify anything other than what
directly generates a DFA, it will complain and fail.

> Note: Strictly speaking the automata generated are not DFAs because they
> don't include an explicit fail state, but adding one is cheap so that is what
> is done here.


## Installation

1. Install [Racket](https://racket-lang.org)
1. Install the beautiful-racket packet using raco: `raco pkg install beautiful-racket`
1. Clone this repository
1. Install it as a package using raco: `raco pkg install rex/`
1. Enjoy

## Usage

Create a file that has `#lang rex` as the first line.

The initial line is followed by the actual expression. Lets take a look at what
you can do.

A file is executed by running:
```
racket filename.rkt "String to match"
```

For other options and flags consult `racket filename.rkt --help`.

### Syntax

The expression is composed of two parts separated by a colon ":". The first
part looks like a regular expression without any of the fancy features (allowed
are character ranges, not (!), branches and loops). There are also the following
wildcards: "\*" and "." but some caveats apply (see that section).

The second part explicitly defines the remaining transitions in the following
format:
```
no_one_recognized 1->one_recognized 0->no_one_recognized, = one_recognized .-> one_recognized
```
States are separated by a comma. The state name is followed by zero or more
transitions that have the format `character -> next_state_name`. States that are
omitted in the end of the list will have the state number as their name. The
equal sign preceding the state name denotes an accepting state. The last state
is always accepting if there are no equal signs present.

This expression matches any string that contains a "1". The equal sign denotes
an accepting state (if no equal sign is given, the last state will
automatically be the accepting state).

Whitespace is ignored by default, comments start with ; and last to the end of
the line.

### Examples

This expression matches any string starting with banana:
```
#lang rex
banana*
```

You can use `!` to say all characters except the one following.
```
#lang rex
!test
```
This would match "best" or "Nest", but not "test".

This expression is equivalent to the regex ana[na]+s*:
```
#lang rex
ananas*:0, 1, 2, 3, 4, 5 n->4
```
By default the states are named 0 through n. You can override the names in the
second part.

Or you can only construct an expression using only the second part:
```
#lang rex
:=even .->odd, odd .-> even
```
This recognizes strings of even length.

Structures like branches are also allowed, but they have to be grouped by parens:
```
#lang rex
(a|b)(a|(bc|d))
```

You can also use loops to express a one-or-more-times pattern:
```
#lang rex
a{b}a
```
This would match "abbbbbba" and any other number of b's but not "aa"

### Caveats

The \* and . were added to provide short useful expressions, but as opposed
to real regexes, they don't work the way you would expect them to. The . does
what you would think but it has to be the only transition going out of the state,
otherwise it will complain about a non-deterministic expression and fail.

The problem of the \* is more subtle. It controls the fail-state. Instead of
failing, the expression simply goes to the last \*. This seems reasonable but
is not the same behavior as a normal wildcard. For instance `*banana*` will not
match "bbanana"! The problem is that wildcards are inherently non-deterministic
and this is the only way I see to include support for them.

Also the \* can only be applied at the topmost scope, never inside of loops and
branches.

I am not sure whether it is a good idea or not to make the default behavior
match single character loops (like in bbbbanana), but not multiple character
loops (like in anananas with `*ananas`). Right now, I'm leaning towards not
**really** surprising the user vs. making the default case easy.


## Contributing

> On the internet nothing ever happens by asking permission." – Don't remember

Just fork away, PRs welcome.

There is a test suite as a python script that can be executed with
`cd tests && ./integration.py`.
Be sure to run the full test suite before every commit and always introduce new
tests with new features.

### Development

Reinstall the package with `raco pkg remove rex && raco pkg install` if it
complains about module mismatch.

## Future

In the long term if this turns out to be useful, probably a fast implementation
in C or C++ is desirable.
