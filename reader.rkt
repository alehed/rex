#lang br/quicklang

(require "parser.rkt" "tokenizer.rkt")
(require racket/contract)

(define (read-syntax path port)
  (datum->syntax #f `(module rex-mod rex/expander
                       ,(parse path (tokenize port)))))
(provide (contract-out
  [read-syntax (any/c input-port? . -> . syntax?)]))


