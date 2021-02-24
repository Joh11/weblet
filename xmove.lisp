;; Moving the cursor using xlib

(in-package #:weblet/cffi)

(define-foreign-library :libx11
  (t "libX11.so"))

(define-foreign-library :libxtst
  (t "libXtst.so"))

(use-foreign-library :libx11)
(use-foreign-library :libxtst)

(defcfun ("XInitThreads" init-threads) :int)

(defcfun ("XOpenDisplay" open-display) :pointer
  (display-name :pointer))

(defcfun ("XTestFakeRelativeMotionEvent" test-fake-relative-motion-event) :int
  (display :pointer)
  (x :int) (y :int)
  (delay :unsigned-long))

(defcfun ("XFlush" flush) :int
  (display :pointer))

(in-package #:weblet)

(defparameter *xmove-display* nil)

(defun xmove-open-display ()
  (unless *xmove-display*
    (weblet/cffi:init-threads)
    (setf *xmove-display* (weblet/cffi:open-display (cffi:null-pointer))))
  *xmove-display*)

(defun xmove-mouse-relative (x y)
  ;; Because the CurrentTime is = 0L in <X11/X.h>
  (weblet/cffi:test-fake-relative-motion-event *xmove-display* x y 0)
  (weblet/cffi:flush *xmove-display*))

;; Position from the last event
(defparameter *xmove-pos* '(0 0))

(defun xmove-set-pos (touch)
  (setf *xmove-pos*
	(list (cdr-assoc :x touch)
	      (cdr-assoc :y touch))))

(defun xmove-move (touch)
  "Compute the offset, move the mouse and update the stored position"
  (let ((offset-x (- (cdr-assoc :x touch)
		     (first *xmove-pos*)))
	(offset-y (- (cdr-assoc :y touch)
		     (second *xmove-pos*))))
    (xmove-mouse-relative offset-x offset-y)
    (xmove-set-pos touch)))

(defun xmove-handle-event (event)
  (case (to-keyword (cdr-assoc :type event))
    (:touchstart
     ;; Update the last event position
     (xmove-set-pos (first (cdr-assoc :touches event))))
    (:touchmove
     (xmove-move (first (cdr-assoc :touches event))))))
