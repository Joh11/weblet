(in-package #:weblet)

(defparameter *clack-server*
  (clack:clackup (lambda (env) (handler env))))

(defun stop-server ()
  (clack:stop *clack-server*))

(defun http-ok (headers &rest body)
  `(200 ,headers (,@body)))

(defmacro with-page (&body body)
  `(with-html-string
     (:doctype)
     (:html
      (:head
       (:title "Weblet"))
      (:body ,@body))))

(defun handler (env)
  (destructuring-bind (&key request-method &allow-other-keys)
      env
    (if (eq request-method :get)
	(http-ok () (with-page
		      (:h1 "je suis un titre !")
		      (:h2 "je suis un sous titre")))
	(progn
	  (print env)
	  (http-ok () "")))))
