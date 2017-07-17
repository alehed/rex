#lang racket/base

(require (for-syntax racket/base))

(require rex/expander
         rex/parser
         rex/tokenizer)

(define-syntax (eval-rex stx)
  (syntax-case stx ()
    [(_ program input-list)
     #'(match-strings
        (eval
         (parameterize ([current-namespace (module->namespace 'rex/expander)])
           (expand
            (parse "" (tokenize (open-input-string program))))))
        input-list)]))
(provide eval-rex)
