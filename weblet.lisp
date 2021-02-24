(in-package #:weblet)

(defun drop-multiple-values (v)
  "I know this is dumb, but it works"
  v)

(defun get-ip-address ()
  "Returns the (LAN) IP address of the computer"
  (drop-multiple-values
   (ppcre:scan-to-strings
    "\\S*"
    (with-output-to-string (s)
      (sb-ext:run-program "/bin/hostname" (list "-I") :output s)))))

(defparameter *clack-server*
  (clack:clackup (lambda (env) (handler env))
		 :address (get-ip-address)
		 :port 8000))

(defun stop-server ()
  (clack:stop *clack-server*))

(defun http-ok (headers &rest body)
  `(200 ,headers (,@body)))

(defmacro with-page ((&key head) &body body)
  `(with-html-string
     (:doctype)
     (:html
      (:head
       (:title "Weblet")
       ,@head)
      (:body ,@body))))

(defmacro with-script (&rest body)
  `(with-html (:script (parenscript:ps ,@body))))

(defun main-page ()
  (with-page ()
    (with-script
	(defun send-object (obj)
	  (chain (fetch ""
			(create :method "POST"
				:body 
				(chain *json* (stringify (create
							  :buttons (@ obj buttons)
							  :type (@ obj type)
							  :x (@ obj x)
							  :y (@ obj y)
							  :movement-x (@ obj movement-x)
							  :movement-y (@ obj movement-y))))))
		 (then (lambda (response) (chain response (json))))
		 (then (lambda (data)))))
      
      (defun startup ()
	(let ((el (chain document (get-element-by-id "canvas"))))
	  (setf (@ el onpointerdown) send-object)
	  (setf (@ el onpointerup) send-object)
	  (setf (@ el onpointermove) send-object)))
      
      (chain console (log "bojour"))
      (chain document (add-event-listener "DOMContentLoaded" startup)))
    
    (:h1 "Weblet 0.0.1")
    (:canvas :id "canvas"
	     :width "600"
	     :height "600"
	     :style "border:solid black 1px;"
	     "Your browser does not support canvas element")))

(defun handler (env)
  (destructuring-bind (&key request-method &allow-other-keys)
      env
    (case request-method
      (:get (http-ok () (main-page)))
      (:post (progn
	       (setf json (ignore-errors (cl-json:decode-json (getf env :raw-body))))
	       (print json)
	       (finish-output)
	       (http-ok () "{}"))))))
