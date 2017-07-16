#lang racket/base

(require rackunit
         racket/contract
         rex/expander)

(define/contract (contains-range range char)
  ((listof (listof char?)) char? . -> . boolean?)
  (and (char>=? char (car (car range)))
       (char<=? char (cadr (car range)))))

(check-true (contains-range GLOB #\a))
(check-true (contains-range GLOB #\null))
(check-true (contains-range GLOB (integer->char 256)))
;; don't support unicode yet
(check-false (contains-range GLOB (integer->char 1000)))
