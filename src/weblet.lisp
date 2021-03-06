(in-package #:weblet)

(defun get-ip-address ()
  "Returns the (LAN) IP address of the computer"
  (drop-multiple-values
   (ppcre:scan-to-strings
    "\\S*"
    (with-output-to-string (s)
      (sb-ext:run-program "/bin/hostname" (list "-I") :output s)))))

;; Server starting / closing stuff

(defparameter *clack-server* nil)

(defun stop-server ()
  (prog1 (clack:stop *clack-server*)
    (setf *clack-server* nil)))

(defun start-server ()
  (when *clack-server*
    (restart-case (error "Server is already running")
      (restart-server ()
	:report "Restart the server"
	(stop-server))))
  (setf *clack-server*
	(clack:clackup (lambda (env) (handler env))
		       :address (get-ip-address)
		       :port 8000)))

;; Request stuff

(defun http-ok (headers &rest body)
  `(200 ,headers (,@body)))

;; HTML / JS stuff

(defmacro with-page ((&key head) &body body)
  `(with-html-string
     (:doctype)
     (:html
      (:head
       (:title "Weblet")
       ,@head)
      (:body ,@body))))

(defmacro with-script (&rest body)
  `(with-html (:script (:raw (parenscript:ps ,@body)))))

;; Main page of the web app

(defun handler (env)
  (destructuring-bind (&key request-method &allow-other-keys)
      env
    (case request-method
      (:get (http-ok () (main-page)))
      (:post (progn
	       (alexandria:when-let
		   (event (ignore-errors (cl-json:decode-json (getf env :raw-body))))
		 ;; (viz-handle-event event)
		 (xmove-handle-event event))
	       (http-ok () "{}"))))))

(defun main-page ()
  (with-page ()
    (with-script
	(defun process-touches (touches)
	  (unless touches
	    (return-from process-touches "failed"))
	  (loop for i from 0 below (@ touches length)
		collect
		(create
		 :x (chain touches (item i) client-x)
		 :y (chain touches (item i) client-y)
		 :identifier (chain touches (item i) identifier))))
      
      (defun send-object (obj)
	(chain obj (prevent-default))
	
	(chain (fetch ""
		      (create :method "POST"
			      :body 
			      (chain *json* (stringify (create
							:type (@ obj type)
							:touches (process-touches (@ obj changed-touches))
							)))))
	       (then (lambda (response) (chain response (json))))
	       (then (lambda (data)))))
      
      (defun startup ()
	(let ((el (chain document (get-element-by-id "canvas"))))
	  
	  (chain el (add-event-listener "touchstart" send-object false))
	  (chain el (add-event-listener "touchend" send-object false))
	  (chain el (add-event-listener "touchcancel" send-object false))
	  (chain el (add-event-listener "touchmove" send-object false))))

      (defun fullscreen-canvas ()
	(let ((el (chain document (get-element-by-id "canvas"))))
	  (when (@ el request-fullscreen)
	    (chain el (request-fullscreen)))))
      
      (chain document (add-event-listener "DOMContentLoaded" startup)))

    (:canvas :id "canvas"
	     :width 600
	     :height 300
	     :style "border: solid black 1px;"
	     "Your browser does not support canvas element")
    (:button :type "button"
	     :onclick (ps (fullscreen-canvas))
	     "Full screen")))


;; Entry point of the program

(defun main ()
  ;; Load xlib stuff
  (xmove-open-display)

  ;; Server stuff
  (start-server)

  (format t "Press ENTER to quit...~%")
  (read-line)

  (stop-server))
