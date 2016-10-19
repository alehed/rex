#lang br/quicklang

;; module begin

(define-macro (rex-module-begin PARSE-TREE)
  #'(#%module-begin
     (display "Welcome to rex!\n")
     (display 'PARSE-TREE)
     (display "\n")
     PARSE-TREE
     ;;(match-input (vector-ref (current-command-line-arguments) 0) 0)
     ))
(provide (rename-out [rex-module-begin #%module-begin]))

;; Expression Generation

(define node-vector (make-vector 1))

(define (fold-funcs apl funcs)
  (for/fold ([current-apl apl])
      ([func (in-list funcs)])
    (apply func current-apl)))

;; Parse Tree Functions

(define (rex test1 [separator ":"] [test3 (void)])
  test1
  test3)
(provide rex)

(define implicit-expression
  void)
(provide implicit-expression)

(define explicit-expression
  void)
(provide explicit-expression)

(define transition
  void)
(provide transition)

(define character
  void)
(provide character)

(define node-identifier
  void)
(provide node-identifier)

(define node-line
  void)
(provide node-line)

(define (GLOB)
  (display "the glob!\n"))
(provide GLOB)

(define (STAR)
  (display "Star!\n"))
(provide STAR)

;; we pass around one index and two stacks
;; index 1: The current node it is at (index into node-vector)
;; stack 1: stack of first nodes
;; stack 2: stack of fallback nodes
;; (define-macro (implicit-expression TRANSITION ...)
;;   #'(
;;       (display (fold-funcs '(0 () ()) (list TRANSITION ...))
;;       (void))))
;; (provide implicit-expression)

;; Expression Matching

(define (match-input string state-index)
  (display string)
  #f)
