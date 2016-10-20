#lang br/quicklang

(require data/gvector)

;; module begin

(define-macro (rex-module-begin PARSE-TREE)
  #'(#%module-begin
     (display "Welcome to rex!\n")
     (display 'PARSE-TREE)
     (display "\n")
     PARSE-TREE
     (display "\n")
     (display (gvector->list node-vector))
     ;;(match-input (vector-ref (current-command-line-arguments) 0) 0)
     ))
(provide (rename-out [rex-module-begin #%module-begin]))

;; Expression Generation

(define (fold-funcs apl funcs)
  (for/fold ([current-apl apl])
            ([func (in-list funcs)])
    (display current-apl)
    (apply func current-apl)))

(define node-vector (make-gvector #:capacity 20))

;; Parse Tree Functions

(define (rex test1 [separator ":"] [test3 (void)])
  test1
  ;; Resolve references
  test3)
(provide rex)

;; we pass around one index and two stacks
;; index 1: The current node it is at (index into node-vector)
;; stack 1: stack of first nodes
;; stack 2: stack of fallback nodes
(define-macro (implicit-expression TRANSITION ...)
  #'(begin
      (gvector-add! node-vector '("0" () -1 #f))
      (void (fold-funcs '(0 '() '()) (list TRANSITION ...)))))
(provide implicit-expression)

(define-macro (explicit-expression NODE-LINE ...)
  (void))
(provide explicit-expression)

(define-macro (transition CHAR)
  #'(lambda (index first-nodes fallbacks)
      (display CHAR)
      (let ([current-node (gvector-ref node-vector index)])
        (gvector-set! node-vector index `(,(car current-node)
                                          ,(cons `(,CHAR ,(add1 index)) (cadr current-node))
                                          ,(caddr current-node)
                                          ,(cadddr current-node))))
      (gvector-add! node-vector `(,(number->string (add1 index))
                                  ()
                                  ,(car fallbacks);;TODO first number that is not nil 
                                  #f))
      `(,(add1 index) ,first-nodes ,fallbacks)));; TODO Bug here
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
      (display "*")
      (let ([current-node (gvector-ref node-vector index)])
        (gvector-set! node-vector index `(,(car current-node)
                                          ,(cadr current-node)
                                          ,index
                                          ,(cadddr current-node))))
      `(,index ,first-nodes ,`(,index))))
(provide STAR)


;; Expression Matching

(define (match-input string state-index)
  (display string)
  #f)
