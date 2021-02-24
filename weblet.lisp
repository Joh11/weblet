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
	       (setf json (ignore-errors (cl-json:decode-json (getf env :raw-body))))
	       (format t "~a~%" json)
	       (awhen json ;; make sure it was correct first
		 (viz-handle-event it))
	       (finish-output)
	       (http-ok () "{}"))))))

(defun main-page ()
  (with-page (:head ((:style (alexandria:read-file-into-string "style.css"))))
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
	(chain console (log obj))
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
      
      (chain console (log "bojour"))
      (chain document (add-event-listener "DOMContentLoaded" startup)))

    (:canvas :id "canvas"
	     :width 600
	     :height 300
	     :style "border: solid black 1px;"
	     "Your browser does not support canvas element")
    (:button :type "button"
	     :onclick (ps (fullscreen-canvas))
	     "Full screen")))

;; Visualization tool

(defun cdr-assoc (item alist)
  (cdr (assoc item alist)))

(defun to-keyword (x)
  (intern (string-upcase (string x))
	  :keyword))

(defparameter *pointers* (make-hash-table))

(defun viz-clear-pointers ()
  (setf *pointers* (make-hash-table)))

(defun viz-update-pointers (touches)
  (dolist (touch touches)
    (setf (gethash (cdr-assoc :identifier touch)
		   *pointers*)
	  `(,(cdr-assoc :x touch)
	    ,(cdr-assoc :y touch)))))

(defun viz-draw-pointers (render)
  (maphash (lambda (k v)
	     (case (rem k 6)
	       (0 (sdl2:set-render-draw-color render 255 0 0 255))
	       (1 (sdl2:set-render-draw-color render 0 255 0 255))
	       (2 (sdl2:set-render-draw-color render 0 0 255 255))
	       (3 (sdl2:set-render-draw-color render 255 255 0 255))
	       (4 (sdl2:set-render-draw-color render 0 255 255 255))
	       (5 (sdl2:set-render-draw-color render 255 0 255 255)))
	     (destructuring-bind (x y) v
	       (sdl2:with-rects ((rect x y 10 10))
		 (sdl2:render-fill-rect render rect))))
	   *pointers*))

(defun viz-handle-event (event)
  (case (to-keyword (cdr-assoc :type event))
    (:touchstart
     ;; Clear the previous things
     (viz-clear-pointers)
     (viz-update-pointers (cdr-assoc :touches event)))
    (:touchmove
     ;; Update the pointers
     (viz-update-pointers (cdr-assoc :touches event)))
    (:touchend
     (viz-clear-pointers))))

(defun viz ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (win :title "Weblet")
      (sdl2:with-renderer (render win)
	(sdl2:with-event-loop (:method :poll)
	  (:quit () t)
	  (:idle ()
		 (sdl2:set-render-draw-color render 255 255 255 255)
		 (sdl2:render-clear render)

		 ;; Draw the pointers
		 (viz-draw-pointers render)
		 
		 (sdl2:render-present render)
		 (swank.live:update-swank)))))))
