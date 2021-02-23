(in-package #:weblet)

(defparameter *clack-server*
  (clack:clackup (lambda (env) (handler env))))

(defun stop-server ()
  (clack:stop *clack-server*))

(defun handler (env)
  `(200 nil (,(prin1-to-string env))))
