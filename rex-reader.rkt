#lang br/quicklang

(require "rex-parser.rkt")

(define (read-syntax path port)
  (datum->syntax #f `(module rex-mod "rex-expander.rkt"
                       ,(parse path (tokenize port)))))
(provide read-syntax)

(require parser-tools/lex brag/support)
(define (tokenize port)
  (define (next-token)
    ((lexer
      [(eof) eof]
      [(concatenation #\; (repetition 0 +inf.0 (char-complement #\newline)) #\newline) (next-token)]
      [(char-set ":*.,{}[]|->") lexeme]
      [(union (char-range "a" "z") (char-range "A" "Z")) 'ALPHA]
      [(char-range "0" "9") 'NUMBER]
      [(union #\tab #\space) 'WHITESPACE]
      [(char-set "!\"#$%&'+/<=>?@^_`~") 'PUNCTUATION]
      [(concatenation "\\" (char-set ";:*.,{}[]|\\-n0abtvfre")) 'ESCAPED-CHAR]
      [any-char (next-token)])
     port))
  next-token)
