#lang scribble/manual

@title{rex: deterministic regular expressions}

@author{Alexander Hedges}

@defmodulelang[rex]

@section{Introduction}

This language resulted out of a rant on regular expressions. The first point was
that some implementations allow backreferences and stuff that takes regular
expressions out of the domain of regular languages. This defies the whole point
of using regular expressions, since you lose all the benefits of regular
languages like linear running time. The second criticism was that regular
expressions specify non-deterministic finite automata (NFA). While this is
mathematically equivalent to a deterministic finite automata (DFA), the
resulting DFA has O(2@superscript{n}) states where n is the amount of states in the
NFA. In other words, large regular expressions that are not carefully crafted
can be memory hogs.

@tt{rex} tries to solve this problem by specifying a syntax that directly
describes deterministic finite automata. That said, in order to be useful for
text matching it allows a very limited set of wildcards. These will be directly
translated to a DFA where possible and otherwise return an error. For details on
this behavior, please have a look at @secref{Caveats}.

@section{Getting started}

A DFA is essentially a directed graph with edges that are labeled with characters. It is
executed by starting at the start state and by moving along the edges that are
labeled with the next encountered character. If we are at vertex n in the graph
and there is no outgoing edge that is labeled with the character we currently have to
match in the string we enter the fail-state and are finished returning false. If
the string has been consumed and we are at a vertex that is labeled as an
"accepting state" we return true, otherwise false.

A rex consists out of two parts separated by a colon @tt{:}. The first
part looks like a regular expression without any of the fancy features (allowed
are character ranges, not (!), branches and loops). There are also the following
wildcards: "\*" and "." but some caveats apply (see @secref{Caveats}).

From this part a basic (more or less) linear graph is constructed. For instance
the string "abcde" would result in six vertexes connected to each other by each
one edge labeled with the corresponding letter and pointing from vertex n to
vertex n+1.

In ascii art the graph would look like this:
@verbatim{
  a    b    c    d    e    f
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6
}

The last vertex is implicitly assumed to be the accepting state, but you can
change that. The implicit fail state is also not shown.

The second part can be used to modify the graph from part one by adding edges.
Lets say we wanted to allow "abcdef" followed by an arbitrary spaces amount of
spaces like "abcdef@hspace[1]" and "abcdef@hspace[3]" to be matched (we
still want to allow our original "abcdef").

To do that we need to add a loop from state 6 back to state 6 that is labeled
with a space.

The second part is a comma-separated list of states (vertexes) and the
transitions (edges) you want to add separated by spaces. So to add the loop the
second part would be @tt{0, 1, 2, 3, 4, 5, 6 \ -> 6}. This means that we don't
change the states 0 to 5 and add one extra edge going from 6 to 6 that is
labeled with " ".

Our ascii art graph is now:
@verbatim{
                                " "
  a    b    c    d    e    f   /--|
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 <-|
}

The complete rex looks like this:
@codeblock|{
  #lang rex
  ;; Our first rex program
  abcdef:
  0, 1, 2, 3, 4, 5, 6 \ -> 6
}|

Note that whitespace is not relevant for the second part. Comments start with
@tt{;} and go to the next linebreak.

We could also use the second part to rename the states. @tt{start, 1, 2} would
rename the state "0" to "start" and leave states 1-6 unchanged. This allows us
to specify @tt{start, 1 x -> start}. By default the states are named with their
number.

The second part is optional so if we leave away the colon or write nothing
after the colon, the graph from part 1 is used unmodified. If we name less states
that the graph has that is also fine, the remaining states will still be
addressable with their number. If on the other hand we name more states in the
second part than existed in the first part the new states will be added to
the graph with only the edges from part 2. This can be for instance used to
construct graphs entirely from the second part:

@codeblock|{
  #lang rex
  :=even .->odd, odd .-> even
}|
This recognizes strings of even length. Note that the @tt{.} matches any character.
To match the character "@tt{.}" you can escape it with a backslash (@tt{\.}).

Also note how we used the equal sign before "even" to make it the accepting state.
By placing one or more equal signs in part two the last vertex from part 1 is not
assumed to be accepting any more! Without the equal sign above the rex would
match odd strings.


@section{More examples}

This expression matches any string starting with banana:
@codeblock|{
  #lang rex
  banana*
}|

You can use @tt{!} to say all characters except the one following.
@codeblock|{
  #lang rex
  !test
}|
This would match "best" or "Nest", but not "test".

This expression is equivalent to the regex @tt{ana[na]+s*}:
@codeblock|{
  #lang rex
  ananas*:0, 1, 2, 3, 4, 5 n->4
}|
By default the states are named 0 through n. You can override the names in the
second part.

Structures like branches are also allowed, but they have to be grouped by parens:
@codeblock|{
  #lang rex
  (a|b)(a|(bc|d))
}|

You can also use loops to express a one-or-more-times pattern:
@codeblock|{
  #lang rex
  a{b}a
}|
This would match "abbbbbba" and any other number of b's but not "aa"

@section{Caveats}

The @tt{*} and @tt{.} were added to provide short useful expressions, but as opposed
to real regexes, they don't work the way you would expect them to. The @tt{.} does
what you would think but it has to be the only transition going out of the state,
otherwise it will complain about a non-deterministic expression and fail.

The problem of the @tt{*} is more subtle. It controls the fail-state. Instead of
failing, the fail-transition simply points to the last @tt{*}. This seems reasonable but
is not the same behavior as a normal wildcard. For instance @tt{*banana*} will not
match "bbanana"! The problem is that wildcards are inherently non-deterministic
and this is the only way I see to include support for them.

Also the @tt{*} can only be applied at the topmost scope, never inside of loops and
branches.

Currently, if you want the looping behavior you have to add the back-edges yourself.
For example if you want the regex behavior of @tt{*banana*} you could write the following
program.

@codeblock|{
  #lang rex
  *banana*:
  0, 1 b->1, 2 b->1, 3 b->1, 4 b->1, 5 b->1
}|
