#lang brag

;; A parser for R-Expressions

rex                 : implicit-expression [ ":" explicit-expression ]
implicit-expression : [star] (transition [star])*
explicit-expression : node-line ("," node-line)*

node-line           : WHITESPACE* node-identifier (WHITESPACE+ transition WHITESPACE* "-" ">" WHITESPACE* node-identifier)*
node-identifier     : (NUMBER | ALPHA | PUNCTUATION)+

transition          : character | range | glob
range               : "[" span ("," span)* "]"
span                : character ["-" character]

;; In addition to the regular ascii escape sequences
;; the following characters are reserved and have to be escaped with \:
;; ;:*.,{}[]|\-
character           : NUMBER | ALPHA | WHITESPACE | PUNCTUATION | ESCAPED-CHAR
glob                : "."
star                : "*"
