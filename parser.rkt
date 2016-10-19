#lang brag

;; A parser for R-Expressions

rex                 : implicit-expression [ ":" explicit-expression ]
implicit-expression : [star] (transition [star])*
explicit-expression : node-line ("," node-line)*

node-line           : node-identifier (transition "-" ">" node-identifier)*
node-identifier     : (NUMBER | ALPHA | PUNCTUATION)+

transition          : character | range | glob
range               : "[" span ("," span)* "]"
span                : character ["-" character]

;; In addition to the regular ascii escape sequences
;; the following characters are reserved and have to be escaped with \:
;; space;:*.,{}[]|\-
character           : NUMBER | ALPHA | PUNCTUATION | ESCAPED-CHAR
glob                : "."
star                : "*"
