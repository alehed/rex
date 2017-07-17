#lang racket/base

(require (for-syntax racket/base))

(require racket/cmdline
         racket/contract
         racket/list
         data/gvector)

;; module begin

(define-syntax (rex-module-begin stx)
  (syntax-case stx ()
    [(_ PARSE-TREE)
     #'(#%module-begin
        (let ([to-match (command-line #:program "rex"
                                      #:once-each
                                      [("--debug" "-d") "show debugging ouput" (set-debug-mode! #t)]
                                      #:args string-to-parse string-to-parse)])
          (if (empty? to-match)
              (error "Please give a string to match or consult the help using --help\n")
              (displayln (match-strings PARSE-TREE to-match)))))]))
(provide (rename-out [rex-module-begin #%module-begin]))

(define-syntax (match-strings stx)
  (syntax-case stx ()
    [(_ TREE STRINGS)
     #'(begin
         (set-last-node-accepting! #f)
         (clear-vector node-vector)
         TREE
         (map (lambda (curr-string)
                (match-input (string->list curr-string) 0))
              STRINGS))]))
(provide match-strings)

;; Expression Generation Helpers

(define last-node-accepting #f)

(define/contract (set-last-node-accepting! accepting)
  (boolean? . -> . void?)
  (set! last-node-accepting accepting))
(provide set-last-node-accepting!)

(define debug-mode #f)

(define/contract (set-debug-mode! mode)
  (boolean? . -> . void?)
  (set! debug-mode mode))
(provide set-debug-mode!)

;; A vector containing all the states from the dfa
;; Each node (state) is a 4-tuple of the following format:
;; Unique Name (string)
;; Transitions: a list of pairs of char-range and integer eg. (((a z) 2) ((A Z) 4))
;; Fail destination: place to go when no outgoing node matched (integer)
;; Accepting state (boolean)
(define node-vector (make-gvector #:capacity 20))

(define (clear-vector vect)
  (if (eq? (gvector-count vect) 0) (void)
      (begin (gvector-remove-last! vect)
             (clear-vector vect))))

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

(define state-list
  (gvector->list node-vector))
(provide state-list)

(define/contract (fold-funcs apl funcs)
  (list? (listof procedure?) . -> . list?)
  (for/fold ([current-apl apl])
            ([func funcs])
    (if debug-mode (display current-apl)
        (void))
    (apply func current-apl)))


;; Parse Tree Functions

(define (rex implicit-part [separator ":"] [explicit-part (void)])
  (let ([last-first-nodes (cadr implicit-part)])
    explicit-part
    (resolve-refs (map (lambda (node)
                         (car node))
                       (gvector->list node-vector)))
    (if (not last-node-accepting)
        (for ([i (car last-first-nodes)])
          (update-node i #:accepting-state? #t))
        (void))))
(provide rex)

;; for creation we pass around two indexes and two stacks:
;; index: The current node it is at
;; stack of tuple: stack of first nodes
;; stack of tuple: stack of last nodes
;; index: the current fallback node
(define-syntax (implicit-expression stx)
  (syntax-case stx ()
    [(_ LIMITED-EXP ...)
     #'(begin
         (add-node "0")
         (fold-funcs '(0 ((0)) () -1) (list LIMITED-EXP ...)))]))
(provide implicit-expression)

(define-syntax (limited-expression stx)
  (syntax-case stx ()
    [(_ CONTENT)
     #'(lambda (index first-nodes last-nodes fallback)
         (apply CONTENT `(,index ,first-nodes ,last-nodes ,fallback)))]))
(provide limited-expression)

(define-syntax (sub-expression stx)
  (syntax-case stx ()
    [(_ EXPR-CONTENT ...)
     #'(lambda (index first-nodes last-nodes fallback)
      (let ([new-data
             (fold-funcs `(,index ,(cons (car first-nodes) first-nodes) ,(cons '() last-nodes) ,fallback)
                         (filter procedure? (list EXPR-CONTENT ...)))])
        `(,(car new-data)
          ,(cons (append (caadr new-data) (caaddr new-data)) (cdaddr new-data))
          ,(cdaddr new-data)
          ,(cadddr new-data))))]))
(provide sub-expression)

(define-syntax (loop stx)
  (syntax-case stx ()
    [(_ LOOP-CONTENT ...)
     #'(lambda (index first-nodes last-nodes fallback)
      (let ([new-data
             (fold-funcs `(,index ,first-nodes ,last-nodes ,fallback)
                         (filter procedure? (list LOOP-CONTENT ...)))])
        (let ([transitions-at-start (cadr (gvector-ref node-vector (caar first-nodes)))])
          (for ([i (caadr new-data)])
            (update-node i #:transitions (append transitions-at-start (cadr (gvector-ref node-vector i)))))
          new-data)))]))
(provide loop)

(define-syntax (branch stx)
  (syntax-case stx ()
    [(_ bar)
     #'(lambda (index first-nodes last-nodes fallback)
      `(,index
        ,(cons (cadr first-nodes) (cdr first-nodes))
        ,(cons (append (car first-nodes) (car last-nodes)) (cdr last-nodes))
        ,fallback))]))
(provide branch)

(define-syntax (STAR stx)
  #'(lambda (index first-nodes last-nodes fallback)
      (update-node index #:fallback index)
      `(,index ,first-nodes ,last-nodes ,index)))
(provide STAR)

;; expects its subfunctions (range, span, glob etc.) to return a list of ranges
;; a range is a pair of characters: (start end).
;; a character is in the range if char >= start and char <= end
(define-syntax (transition stx)
  (syntax-case stx ()
    [(_ CHAR)
     #'(lambda (index [first-nodes void] [last-nodes void] [fallback void])
      (let ([current-node (gvector-ref node-vector index)])
        (if (integer? fallback)
            (begin ;; in implicit expression
              (for ([i (car first-nodes)])
                (update-node i #:transitions (append (map (lambda (pair)
                                                            `(,pair ,(add1 index))) CHAR)
                                                     (cadr (gvector-ref node-vector i)))))
              (add-node (number->string (add1 index)) #:fallback fallback)
              `(,(add1 index) ,(cons `(,(add1 index)) (cdr first-nodes)) ,last-nodes ,fallback))
            (begin ;; in explicit expression
              (update-node index #:transitions (append (map (lambda (pair)
                                                              `(,pair)) CHAR) (cadr current-node)))
              `(,index)))))]))
(provide transition)

(define GLOB
  `((,(integer->char 0) ,(integer->char 256))))
(provide GLOB)

(define (character char)
  (let ([actual-char (effective-char char)])
    `((,actual-char ,actual-char))))
(provide character)

(define-syntax (range stx)
  (syntax-case stx ()
    [(_ SPAN ...)
     #'(filter list? (list SPAN ...))]))
(provide range)

(define (span from-char [to "-"] [to-char void])
  (if (list? to-char) `(,(caar from-char) ,(caar to-char))
      (car from-char)))
(provide span)

(define (except bang excluded-char)
  `((,(integer->char 0) ,(integer->char (sub1 (char->integer (caar excluded-char)))))
    (,(integer->char (add1 (char->integer (caar excluded-char)))) ,(integer->char 256))))
(provide except)

;; returns the char that describes the given string.
;; example: returns 'a' for "a" and '\' for "\\"
(define/contract (effective-char char-string)
  (string? . -> . char?)
  (let ([last-char (string-ref char-string
                               (sub1 (string-length char-string)))])
    (if (and (char=? (string-ref char-string 0) #\\) (or (char=? last-char #\n) (char=? last-char #\t)))
        (if (char=? last-char #\n) #\newline #\tab)
        last-char)))

(define-syntax (explicit-expression stx)
  (syntax-case stx ()
    [(_ NODE-LINE ...)
     #'(void (fold-funcs '(0) (filter procedure? (list NODE-LINE ...))))]))
(provide explicit-expression)

(define-syntax (node-line stx)
  (syntax-case stx ()
    [(_ TRANSITIONS ...)
     #'(lambda (index)
      (if (<= (gvector-count node-vector) index)
          (add-node (number->string index))
          (void))
      (if (string? (car (list TRANSITIONS ...)))
          (begin
            (set-last-node-accepting! #t)
            (update-node index #:accepting-state? #t))
          (void))
      (void (fold-funcs `(,index) (filter procedure? (list TRANSITIONS ...))))
      `(,(add1 index)))]))
(provide node-line)

(define-syntax (node-identifier stx)
  (syntax-case stx ()
    [(_ IDENT ...)
     #'(lambda (index)
      (let ([current-transitions (cadr (gvector-ref node-vector index))])
        (if (empty? current-transitions) (update-node index #:name (string-append IDENT ...))
            (update-node index #:transitions (map (lambda (transition)
                                                    (if (equal? 2 (length transition)) transition
                                                        `(,(car transition) ,(string-append IDENT ...))))
                                                  current-transitions))))
      `(,index))]))
(provide node-identifier)


;; Expression Matching

(define/contract (match-input string-list state-index)
  ((listof char?) integer? . -> . boolean?)
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
  (if (string? (cadr transition)) `(,(car transition) ,(index-of names (cadr transition)))
      transition))


;; Unit tests
;; Everything that is not testable from the outside

(module+ test
  (require rackunit))

;; effective-char
(module+ test
  (check-equal? (effective-char "a") #\a)
  (check-equal? (effective-char "\\!") #\!)
  (check-equal? (effective-char "\\\\") #\\)
  (check-equal? (effective-char "\\n") #\newline)
  (check-equal? (effective-char "\\t") #\tab)
  (check-exn exn:fail:contract? (lambda () (effective-char #\a))))
