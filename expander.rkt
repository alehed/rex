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

(define node-vector (make-vector 1 '("1" () -1 #f)))

(define (fold-funcs apl funcs)
  (for/fold ([current-apl apl])
            ([func (in-list funcs)])
    (apply func current-apl)))

;; Parse Tree Functions

(define (rex test1 [separator ":"] [test3 (void)])
  test1
  test3)
(provide rex)

;; we pass around one index and two stacks
;; index 1: The current node it is at (index into node-vector)
;; stack 1: stack of first nodes
;; stack 2: stack of fallback nodes
(define initial-arg '(0 '() '()))
(define-macro (implicit-expression TRANSITION ...)
  #'(begin
      (void (fold-funcs initial-arg (list TRANSITION ...)))))
(provide implicit-expression)

(define-macro (explicit-expression NODE-LINE ...)
  (void))
(provide explicit-expression)

(define-macro (transition CHAR)
  #`(lambda (index first-nodes fallbacks)
      (display CHAR)
      '((add1 index) first-nodes fallbacks)))
(provide transition)

(define (character char)
  char)
(provide character)

(define node-identifier
  void)
(provide node-identifier)

(define node-line
  void)
(provide node-line)

(define GLOB
  #'(lambda (index first-nodes fallbacks)
      (display "the glob!\n")
      '(index first-nodes fallbacks)))
(provide GLOB)

(define-macro STAR
  #'(lambda (index first-nodes fallbacks)
      (display "Hello World!")
      '(index first-nodes fallbacks)))
(provide STAR)


;; Expression Matching

(define (match-input string state-index)
  (display string)
  #f)
