#lang racket/base

(require rackunit)
(require rex/expander
         rex/parser
         rex/tokenizer)
(require "helper.rkt")

(check-equal? (eval-rex "a{bb}c" '("abbc" "abbbbbbc" "abc" "abbbc" "ac"))
              '(#t #t #f #f #f))

(check-equal? (eval-rex "a{(bc)}" '("abcbc" "abc" "acc"))
              '(#t #t #f))

(check-equal? (eval-rex "({a}|{b})" '("a" "b" "" "aaaaaaa" "bb" "aaabbaaba"))
              '(#t #t #f #t #t #f))

(check-equal? (eval-rex "(c|d){(a|b)}{(c|d)}" '("cabababbcdccd" "dad" "cacc" "cca" "acc"))
              '(#t #t #t #f #f))
