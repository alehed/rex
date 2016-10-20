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

(define (rex implicit-part [separator ":"] [explicit-part (void)])
  implicit-part
  (resolve-refs (map (lambda (node)
                       (car node))
                     (gvector->list node-vector)))
  explicit-part)
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
      (let ([current-node (gvector-ref node-vector index)])
        (if (list? fallbacks)
            (begin ;; in implicit expression
              (gvector-set! node-vector index `(,(car current-node)
                                                ,(cons `(,CHAR ,(add1 index)) (cadr current-node)) ;; BUG: modify due to *
                                                ,(caddr current-node)
                                                ,(cadddr current-node)))
              (gvector-add! node-vector `(,(number->string (add1 index))
                                          ()
                                          ,(car fallbacks);; BUG: find first number that is not nil 
                                          #f))
              `(,(add1 index) ,first-nodes ,fallbacks))
            (begin ;; else (explicit expression)
              (gvector-set! node-vector index `(,(car current-node)
                                                ,(cons `(,CHAR) (cadr current-node))
                                                ,(caddr current-node)
                                                ,(cadddr current-node)))
              `(,index))))))
(provide transition)

(define (character char)
  `(,(string-ref char 0) ,(string-ref char 0)))
(provide character)

(define-macro (explicit-expression NODE-LINE ...)
  #'(begin
      (void (fold-funcs '(0) (filter procedure? (list NODE-LINE ...))))))
(provide explicit-expression)

(define-macro (node-line TRANSITIONS ...)
    #'(lambda (index)
        (void (fold-funcs `(,index) (cdr (filter procedure? (list TRANSITIONS ...)))))
        `(,(add1 index))))
(provide node-line)

(define-macro (node-identifier IDENT-LIST)
  #'(lambda (index)
      (let ([current-node (gvector-ref node-vector index)])
        (let ([current-transition (caadr current-node)])
          (if (equal? 1 (length current-transition))
              (begin
                (gvector-set! node-vector index `(,(car current-node)
                                                  ,(cons `(,(car current-transition) ,(string-append IDENT-LIST)) (cdadr current-node))
                                                  ,(caddr current-node)
                                                  ,(cadddr current-node))))
              (begin ;; otherwise we are looking at node naming
                (gvector-set! node-vector index `(,(string-append IDENT-LIST)
                                                  ,(cadr current-node)
                                                  ,(caddr current-node)
                                                  ,(cadddr current-node)))))))
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
  (display state-index)
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

(define (resolve-refs names)
  (for/list ([i (in-range (sub1 (gvector-count node-vector)))])
    (let ([element (gvector-ref node-vector i)])
      (gvector-set! node-vector i `(,(car element)
                                    ,(resolved-transitions (cadr element) names)
                                    ,(caddr element)
                                    ,(cadddr element))))))

(define (resolved-transitions transitions names)
  (if (empty? transitions) '()
      (cons (resolve-transition (car transitions) names) (resolved-transitions (cdr transitions) names))))

(define (resolve-transition transition names)
  (if (not (string? cadr)) `(,(car transition) ,(index-of (cadr transition) names))
      transition))

(define (index-of elem list)
  (if (empty? list) -1
      (if (equal? elem (car list)) 0
          (let ([index (index-of elem (cdr list))])
            (if (equal? -1 index) -1
                (add1 index))))))
