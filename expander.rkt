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
     (display "\n")
     (match-input (string->list (vector-ref (current-command-line-arguments) 0)) 0)))
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
  ;; TODO: Resolve references
  test3)
(provide rex)

;; we pass around one index and two stacks
;; index 1: The current node it is at (index into node-vector)
;; stack 1: stack of first nodes
;; stack 2: stack of fallback nodes
(define-macro (implicit-expression TRANSITION ...)
  #'(begin
      (gvector-add! node-vector '("0" () -1 #f))
      (void (fold-funcs '(0 () (-1)) (list TRANSITION ...)))
      (let ([index (sub1 (gvector-count node-vector))])
        (let ([current-node (gvector-ref node-vector index)])
          (gvector-set! node-vector index `(,(car current-node)
                                            ,(cadr current-node)
                                            ,(caddr current-node)
                                            #t))))))
(provide implicit-expression)

(define-macro (transition CHAR)
  #'(lambda (index [first-nodes void] [fallbacks void])
      (if (list? fallbacks)
          (begin ;; in implicit expression
            (let ([current-node (gvector-ref node-vector index)])
              (gvector-set! node-vector index `(,(car current-node)
                                                ,(cons `(,CHAR ,(add1 index)) (cadr current-node))
                                                ,(caddr current-node)
                                                ,(cadddr current-node))))
            (gvector-add! node-vector `(,(number->string (add1 index))
                                        ()
                                        ,(car fallbacks);;TODO: find first number that is not nil 
                                        #f))
            `(,(add1 index) ,first-nodes ,fallbacks))
          (begin ;; else (explicit expression)
            ;; TODO: stuff
            `(,index)))))
(provide transition)

(define (character char)
  `(,(string-ref char 0) ,(string-ref char 0)))
(provide character)

(define-macro (explicit-expression NODE-LINE ...)
  #'(begin
      (void (fold-funcs '(0) (filter procedure? (list NODE-LINE ...))))))
(provide explicit-expression)

(define-macro (node-line CONTENT ...)
    #'(lambda (index)
        (void (fold-funcs `(,index) (filter procedure? (list CONTENT ...))))
        `(,(add1 index))))
(provide node-line)

(define-macro (node-identifier IDENT-LIST)
  #'(lambda (index)
      (void (display IDENT-LIST))
      `(,index)))
(provide node-identifier)

(define GLOB
  `(,(integer->char 0) ,(integer->char 256)))
(provide GLOB)

(define-macro STAR
  #'(lambda (index first-nodes fallbacks)
      (let ([current-node (gvector-ref node-vector index)])
        (gvector-set! node-vector index `(,(car current-node)
                                          ,(cadr current-node)
                                          ,index
                                          ,(cadddr current-node))))
      `(,index ,first-nodes ,`(,index))))
(provide STAR)


;; Expression Matching

(define (match-input string-list state-index)
  (if (empty? string-list) (if (cadddr (gvector-ref node-vector state-index)) #t
                               #f)
      (let ([new-state (calculate-new-state (car string-list) state-index)])
        (if (equal? -1 new-state) #f
            (match-input (cdr string-list) new-state)))))

(define (calculate-new-state char current-state)
  (let ([current-node (gvector-ref node-vector current-state)])
    (let ([taken-transition (filter (lambda (range)
                                      (and (char>=? char (car (car range))) (char<=? char (cadr (car range)))))
                                    (cadr current-node))])
      (if (equal? 1 (length taken-transition)) (cadar taken-transition)
          (if (equal? 0 (length taken-transition)) (caddr current-node)
              (begin (display "Error: Non-deterministic expression")
              -1))))))
