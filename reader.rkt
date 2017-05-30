#lang br/quicklang

(require "parser.rkt" "tokenizer.rkt")
(require racket/contract)

(define (read-syntax path port)
  (datum->syntax #f `(module rex-mod rex/expander
                       ,(parse path (tokenize port)))))
(provide (contract-out
  [read-syntax (any/c input-port? . -> . syntax?)]))

(define-tokens value-tokens (ALPHA NUMBER PUNCTUATION ESCAPED-CHAR))
(define-empty-tokens op-tokens (STAR GLOB))

