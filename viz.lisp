(in-package #:weblet)

;; Visualization tool

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
