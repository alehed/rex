#lang br/quicklang

(require brag/support)

(define (tokenize port)
  (define (next-token)
    ((lexer
      [(eof) eof]
      [(concatenation #\; (repetition 0 +inf.0 (char-complement #\newline)) #\newline) (next-token)]
      [#\. 'GLOB]
      [#\* 'STAR]
      [(char-set "!:,(){}[]|->=") lexeme]
      [(union (char-range "a" "z") (char-range "A" "Z")) (token-ALPHA lexeme)]
      [(char-range "0" "9") (token-NUMBER lexeme)]
      [(char-set "\"#$%&'+/<>?@^_`~") (token-PUNCTUATION lexeme)]
      [(concatenation "\\" (union #\tab #\space (char-set "!;:*.,(){}[]|\\-n0abtvfre"))) (token-ESCAPED-CHAR lexeme)]
      [any-char (next-token)])
     port))
  next-token)
(provide tokenize)
