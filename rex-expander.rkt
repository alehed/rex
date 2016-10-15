#lang br/quicklang

(define-macro (rex-module-begin PARSE-TREE)
  #'(#%module-begin
     PARSE-TREE))
(provide (rename-out [rex-module-begin #%module-begin]))

