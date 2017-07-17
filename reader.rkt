#lang racket/base

(require racket/contract)
(require "parser.rkt"
         "tokenizer.rkt")

(define (read-syntax path port)
  (datum->syntax #f `(module rex-mod rex/expander
                       ,(parse path (tokenize port)))))
(provide (contract-out
  [read-syntax (any/c input-port? . -> . syntax?)]))
