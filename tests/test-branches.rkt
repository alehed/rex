#lang racket/base

(require rackunit)
(require rex/expander
         rex/parser
         rex/tokenizer)
(require "helper.rkt")

(check-equal? (eval-rex "(a|b|c)" '("a" "b" "c" "" "d" "ab"))
              '(#t #t #t #f #f #f))

(check-equal? (eval-rex "a(b|g|)" '("a" "ab" "ag" "aa" "ba"))
              '(#t #t #t #f #f))

(check-equal? (eval-rex "(a|b)(c|d)" '("ac" "ad" "bc" "bd" "cd" "da"))
              '(#t #t #t #t #f #f))

(check-equal? (eval-rex "a(b|c)d" '("abd" "acd" "aed" "aad"))
              '(#t #t #f #f))
