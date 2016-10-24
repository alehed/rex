#lang br/quicklang

(require data/gvector)

;; module begin

(define-macro (rex-module-begin PARSE-TREE)
  #'(#%module-begin
     (display "Welcome to rex!\n")
     (display 'PARSE-TREE)
     (display "\n")
     PARSE-TREE
     (display (gvector->list node-vector))
     (display "\n")
     (match-input (string->list (vector-ref (current-command-line-arguments) 0)) 0)))
(provide (rename-out [rex-module-begin #%module-begin]))

;; Expression Generation

(define (fold-funcs apl funcs)
  (for/fold ([current-apl apl])
            ([func (in-list funcs)])
    (apply func current-apl)))

(define node-vector (make-gvector #:capacity 20))

(define (update-node index #:name [name void] #:transitions [transitions void] #:fallback [fallback void] #:accepting-state? [accepting void])
  (let ([current-node (gvector-ref node-vector index)])
    (gvector-set! node-vector index `(,(if (string? name) name (car current-node))
                                      ,(if (list? transitions) transitions (cadr current-node))
                                      ,(if (integer? fallback) fallback (caddr current-node))
                                      ,(if (boolean? accepting) accepting (cadddr current-node))))))

(define (add-node name #:transitions [transitions void] #:fallback [fallback void] #:accepting-state? [accepting void])
  (gvector-add! node-vector `(,name
                              ,(if (list? transitions) transitions '())
                              ,(if (integer? fallback) fallback -1)
                              ,(if (boolean? accepting) accepting #f))))

;; A vector containing the following global state flags:
;; 0: iff the last node should be accepting by default
(define flags (make-vector 1 #t))

;; Parse Tree Functions

(define (rex implicit-part [separator ":"] [explicit-part (void)])
  implicit-part
  explicit-part
  (resolve-refs (map (lambda (node)
                       (car node))
                     (gvector->list node-vector)))
  (if (vector-ref flags 0)
      (let ([index (sub1 (gvector-count node-vector))])
        (update-node index #:accepting-state? #t))
      (void)))
(provide rex)

;; we pass around one index and two stacks
;; index 1: The current node it is at (index into node-vector)
;; stack 1: stack of first nodes
;; stack 2: the current fallback node
(define-macro (implicit-expression LIMITED-EXP ...)
  #'(begin
      (add-node "0")
      (void (fold-funcs '(0 () -1) (list LIMITED-EXP ...)))))
(provide implicit-expression)

(define-macro (limited-expression CONTENT)
  #'(lambda (index first-nodes fallback)
      (apply CONTENT `(,index ,first-nodes ,fallback))))
(provide limited-expression)

(define-macro (sub-expression EXPR-CONTENT ...)
  #'(lambda (index first-nodes fallback)
      ;; TODO: STUB
      `(,index ,first-nodes ,fallback))
(provide sub-expression)

(define-macro (loop LOOP-CONTENT ...)
  #'(lambda (index first-nodes fallback)
      ;; TODO: STUB
      `(,index ,first-nodes ,fallback))
(provide loop)

(define (or pipe)
  ;; TODO: STUB
  void)
(provide or)

(define-macro (transition CHAR)
  #'(lambda (index [first-nodes void] [fallback void])
      (let ([current-node (gvector-ref node-vector index)])
        (if (integer? fallback)
            (begin ;; in implicit expression
              (update-node index #:transitions (append (map (lambda (pair)
                                                            `(,pair ,(add1 index))) CHAR)
                                                     (cadr current-node)))
              (add-node (number->string (add1 index)) #:fallback fallback)
              `(,(add1 index) ,first-nodes ,fallback))
            (begin ;; else (explicit expression)
              (update-node index #:transitions (append (map (lambda (pair)
                                                              `(,pair)) CHAR) (cadr current-node)))
              `(,index))))))
(provide transition)

(define (character char)
    `((,(string-ref char (sub1 (string-length char))) ,(string-ref char (sub1 (string-length char))))));; BUG: \t and \n escape sequences not recognized
(provide character)

(define-macro (range SPAN ...)
  #'(filter list? (list SPAN ...)))
(provide range)

(define (span from-char [to "-"] [to-char void])
  (if (list? to-char) `(,(caar from-char) ,(caar to-char))
      (car from-char)))
(provide span)

(define-macro (explicit-expression NODE-LINE ...)
  #'(void (fold-funcs '(0) (filter procedure? (list NODE-LINE ...)))))
(provide explicit-expression)

(define-macro (node-line TRANSITIONS ...)
    #'(lambda (index)
        (if (<= (gvector-count node-vector) index)
              (add-node (number->string index))
            (void))
        (if (string? (car (list TRANSITIONS ...)))
            (begin
              (vector-set! flags 0 #f)
              (update-node index #:accepting-state? #t))
            (void))
        (void (fold-funcs `(,index) (filter procedure? (list TRANSITIONS ...))))
        `(,(add1 index))))
(provide node-line)

(define-macro (node-identifier IDENT ...)
  #'(lambda (index)
      (let ([current-transitions (cadr (gvector-ref node-vector index))])
        (if (empty? current-transitions) (update-node index #:name (string-append IDENT ...))
            (update-node index #:transitions (map (lambda (transition)
                                                    (if (equal? 2 (length transition)) transition
                                                        `(,(car transition) ,(string-append IDENT ...))))
                                                  current-transitions))))
      `(,index)))
(provide node-identifier)

(define GLOB
  `((,(integer->char 0) ,(integer->char 256))))
(provide GLOB)

(define-macro STAR
  #'(lambda (index first-nodes fallback)
      (update-node index #:fallback index)
      `(,index ,first-nodes ,index)))
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
              (begin (error "Non-deterministic expression")
                     -1))))))

(define (resolve-refs names)
  (for/list ([i (in-range (gvector-count node-vector))])
    (let ([element (gvector-ref node-vector i)])
      (update-node i #:transitions (resolved-transitions (cadr element) names)))))

(define (resolved-transitions transitions names)
  (if (empty? transitions) '()
      (cons (resolve-transition (car transitions) names) (resolved-transitions (cdr transitions) names))))

(define (resolve-transition transition names)
  (if (string? (cadr transition)) `(,(car transition) ,(index-of (cadr transition) names))
      transition))

(define (index-of elem list)
  (if (empty? list) -1
      (if (equal? elem (car list)) 0
          (let ([index (index-of elem (cdr list))])
            (if (equal? -1 index) -1
                (add1 index))))))
