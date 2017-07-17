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

### For regular usage

1. Install [Racket](https://racket-lang.org)
1. Install the package using raco: `raco pkg install rex`
1. Enjoy

### For development

1. Install [Racket](https://racket-lang.org)
1. Clone this repository
1. Install it as a local package using raco: `raco pkg install ./rex`
1. Enjoy

## Usage

Create a file that has `#lang rex` as the first line.

The initial line is followed by the actual expression.

A basic rex that matches the string "abc" but nothing else looks like this.
```
#lang rex
abc
```

This file would be executed by running: `racket abc.rkt "abc" "abcd"`. This should print `(#t #f)` since the first expression was matched successfully while the second one was not.

For other options and flags consult `racket filename.rkt --help`.

### Syntax

For a detailed documentation of the syntax, please consult the [documentation](http://docs.racket-lang.org/rex).

## Contributing

> “On the internet nothing ever happens by asking permission.” – Don't remember

Just fork away, PRs welcome.

The test-suite is run with `raco test -p rex`. Make sure it runs before every
commit. New features should preferably add a corresponding file in `tests/`.

### Development

Once you added your changes you have to recompile the package using
`raco setup --pkgs rex` otherwise racket will complain with:

```
link: module mismatch;
 possibly, bytecode file needs re-compile because dependencies changed
```

## Future

In the long term if this turns out to be useful, probably a fast implementation
in C is desirable.
