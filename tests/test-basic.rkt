#lang racket/base

(require rackunit)
(require "helper.rkt")

(check-equal? (eval-rex "banana" '("banana" "" "a" "bananas"))
              '(#t #f #f #f))

(check-equal? (eval-rex "*bana.na*" '("bana na" "banafana" "banannaaaaa" "bbbanafna" "bbanafna" "1234banagna5678"))
              '(#t #f #t #t #f #t))

(check-equal? (eval-rex ":=even .->odd, odd .-> even" '("asdf" "" "142"))
              '(#t #t #f))

(check-equal? (eval-rex "ananas*:0, 1, 2, 3, 4, 5 n->4" '("ananananas" "anananaas"))
              '(#t #f))

(check-equal? (eval-rex "passwor[d,t][0-9,A-Z]" '("password9" "passworg1" "passwort!" "passwortN"))
              '(#t #f #f #t))

(check-equal? (eval-rex "Hello\\ World\\!" '("Hello World!" "HelloWorld!"))
              '(#t #f))

(check-equal? (eval-rex "1010: 0 0->2,= 1 1 -> 1, 2 0->2,= 3 1->3,4 .->4" '("10001111" "0001" "10" "1111"))
              '(#t #t #f #t))

(check-equal? (eval-rex "a{(b|c)}d" '("abcbcccbbbbd" "acbccbcccbbd" "abcbbccbb" "ad"))
              '(#t #t #f #f))
