(el4r-debug-ruby-eval-report "nil")
(el4r-debug-ruby-eval-report "true")
(el4r-debug-ruby-eval-report "false")
(el4r-debug-ruby-eval-report "1 + 6")
(el4r-debug-ruby-eval-report "\"String\"")

(put 'test-error
     'error-conditions                        
     '(error test-error))
(put 'test-error 'error-message "Test Error")

(condition-case err
    (el4r-ruby-eval "el4r_lisp_eval(\"(signal 'test-error '(123))\")")
  (test-error (insert-string (format "Error is passed: %s" err))
              ))

