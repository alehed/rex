#lang racket/base

(require brag/support
         rackunit
         rex/parser
         rex/tokenizer)


(define prog1 #<<EOF
hello;; test test!
hi:1   2->alpha  4->alpha, beta 3->beta
EOF
)

(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker tokenize prog1))
 '(rex
   (implicit-expression
    (limited-expression (transition (character "h")))
    (limited-expression (transition (character "e")))
    (limited-expression (transition (character "l")))
    (limited-expression (transition (character "l")))
    (limited-expression (transition (character "o")))
    (limited-expression (transition (character "h")))
    (limited-expression (transition (character "i"))))
   ":"
   (explicit-expression
    (node-line (node-identifier "1")
               (transition (character "2")) "-" ">" (node-identifier "a" "l" "p" "h" "a")
               (transition (character "4")) "-" ">" (node-identifier "a" "l" "p" "h" "a"))
    ","
    (node-line (node-identifier "b" "e" "t" "a")
               (transition (character "3")) "-" ">" (node-identifier "b" "e" "t" "a")))))

(check-equal?
 (parse-to-datum
  (apply-tokenizer-maker tokenize "a{(b|c)}!d"))
 '(rex
   (implicit-expression
    (limited-expression (transition (character "a")))
    (limited-expression
     (loop "{"
           (limited-expression
            (sub-expression "("
                            (limited-expression (transition (character "b")))
                            (branch "|")
                            (limited-expression (transition (character "c")))
                            ")"))
           "}"))
    (limited-expression (transition (except "!" (character "d")))))))
