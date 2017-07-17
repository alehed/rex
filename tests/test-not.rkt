#lang racket/base

(require rackunit)
(require "helper.rkt")

(check-equal? (eval-rex "!abc" '(" bc" "nbc" "bc" "abc" "cbcc"))
              '(#t #t #f #f #f))

(check-equal? (eval-rex "(password!s|!p1234)(!\\-|)" '("password!" "012345" "passwords!" "01234-" "01234"))
              '(#t #t #f #f #t))

(check-equal? (eval-rex "{!a}" '("hello" "dfsd fsdf jksl" "asdfghjkl" "bca" "aaaaaa"))
              '(#t #t #f #f #f))

(define prog4 #<<EOF
1010
:
  0 0  -> 2,
= 1 !0 -> 1,
  2 0  -> 2,
= 3 !0 -> 3,
  4 .  -> 4
EOF
)

(check-equal? (eval-rex prog4 '("10001111" "0001" "10" "1111"))
              '(#t #t #f #t))
