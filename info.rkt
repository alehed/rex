#lang info
(define collection "rex")
(define version "1.0")
(define scribblings '(("scribblings/rex.scrbl")))
(define deps '("base"
               "br-parser-tools-lib"
               "brag"
               "data-lib"))
(define build-deps '("racket-doc"
                     "rackunit-lib"
                     "scribble-lib"))
