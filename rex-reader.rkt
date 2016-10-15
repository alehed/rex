#lang br/quicklang

(require "rex-parser.rkt")

(define (read-syntax path port)
  (datum->syntax #f '(module rex-mod "rex-module.rkt"
                       ,(parse path (tokenize port)))))
(provide read-syntax)

(require parser-tools/lex brag/support)
(define (tokenize port)
  (define (next-token)
    )
  next-token)
