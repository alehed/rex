#lang br/quicklang

(define-macro (rex-module-begin PARSE-TREE)
  #'(#%module-begin
     (display "Welcome to rex!\n")
     (void PARSE-TREE)
     (match-input (vector-ref (current-command-line-arguments) 0) 0)))
(provide (rename-out [rex-module-begin #%module-begin]))

(define (fold-funcs apl funcs)
  (for/fold ([current-apl apl])
      ([func (in-list funcs)])
    (apply func current-apl)))

(define (rex test1 [separator ";"] [test3 void])
  (display separator)
  (display test3))
(define implicit-expression
  void)
(define explicit-expression
  void)
(define transition
  void)
(define character
  void)
(define ALPHA
  void)
(define WHITESPACE
  void)
(define NUMBER
  void)
(define node-identifier
  void)
(define node-line
  void)
(define (glob dot)
  void)

(provide rex)
(provide implicit-expression)
(provide explicit-expression)
(provide transition)
(provide character)
(provide ALPHA)
(provide WHITESPACE)
(provide NUMBER)
(provide node-identifier)
(provide node-line)
(provide glob)
;; (define (implicit-expression)
;;   (void))
;; (provide implicit-expression)

;; (define (explicit-expression ARGS ...)
;;   (void))
;; (provide explicit-expression)

;; we pass around one index and two stacks
;; index 1: The current node it is at (index into node-vector)
;; stack 1: stack of first nodes
;; stack 2: stack of fallback nodes
;; (define-macro (implicit-expression TRANSITION ...)
;;   #'(
;;       (display (fold-funcs '(0 () ()) (list TRANSITION ...))
;;       (void))))
;; (provide implicit-expression)

;; (define-macro (explicit-expression LINE ...)
;;   #'(void))

;; (define-macro (transition CHARACTERS ...)
;;   #'(lambda (index first fallback)
;;       (list ((add1 index) first fallback))))


;; (define node-vector (make-vector 1))

(define (match-input string state-index)
  (display string)
  #f)
