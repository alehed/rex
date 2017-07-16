#lang racket/base

(require (for-syntax racket/base))
(require (for-syntax racket/match))

(define-syntax (eval-rex stx)
  (match (syntax->list stx)
    [(list _ program input-list)
     (datum->syntax stx `(match-strings
                          (eval
                           (parameterize ([current-namespace (module->namespace 'rex/expander)])
                             (expand
                              (parse "" (tokenize (open-input-string ,program))))))
                          ,input-list))]))
(provide eval-rex)
