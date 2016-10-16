#lang br/quicklang

(define-macro (rex-module-begin PARSE-TREE)
  #'(#%module-begin
     'PARSE-TREE))
(provide (rename-out [rex-module-begin #%module-begin]))



(define node-vector (make-vector 1 '("0" () -1  #f)))

