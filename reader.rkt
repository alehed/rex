#lang br/quicklang

(require "parser.rkt")

(define (read-syntax path port)
  (datum->syntax #f `(module rex-mod "expander.rkt"
                       ,(parse path (tokenize port)))))
(provide read-syntax)

(require parser-tools/lex brag/support)

(define-tokens value-tokens (ALPHA NUMBER PUNCTUATION ESCAPED-CHAR))

(define (tokenize port)
  (define (next-token)
    ((lexer
      [(eof) eof]
      [(concatenation #\; (repetition 0 +inf.0 (char-complement #\newline)) #\newline) (next-token)]
      [(char-set ":*.,{}[]|->") lexeme]
      [(union (char-range "a" "z") (char-range "A" "Z")) (token-ALPHA lexeme)]
      [(char-range "0" "9") (token-NUMBER lexeme)]
      [(union #\tab #\space) (next-token)]
      [(char-set "!\"#$%&'+/<=>?@^_`~") (token-PUNCTUATION lexeme)]
      [(concatenation "\\" (union #\tab #\space (char-set ";:*.,{}[]|\\-n0abtvfre"))) (token-ESCAPED-CHAR lexeme)]
      [any-char (next-token)])
     port))
  next-token)
