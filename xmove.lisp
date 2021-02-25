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

;; Position from the last event
(defparameter *xmove-pos* '(0 0))
(defparameter *xmove-start-time* nil)

(defparameter *xmove-click-max-duration* 200) ;; Half a second should be enough

(defun xmove-reset-start-time ()
  (setf *xmove-start-time* (get-internal-real-time)))

(defun xmove-click-durationp ()
  "Returns T if the duration of the touch is small enough to be considered a click"
  (< (- (get-internal-real-time) *xmove-start-time*)
     *xmove-click-max-duration*))

(defun xmove-open-display ()
  (unless *xmove-display*
    (weblet/cffi:init-threads)
    (setf *xmove-display* (weblet/cffi:open-display (cffi:null-pointer))))
  *xmove-display*)

(defun xmove-mouse-relative (x y)
  ;; Because the CurrentTime is = 0L in <X11/X.h>
  (weblet/cffi:test-fake-relative-motion-event *xmove-display* x y 0)
  (weblet/cffi:flush *xmove-display*))


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
     (xmove-set-pos (first (cdr-assoc :touches event)))
     (xmove-reset-start-time))
    (:touchmove
     (xmove-move (first (cdr-assoc :touches event))))
    (:touchend
     (when (xmove-click-durationp)
       ;; Send a click !
       (print "CLICK")
       (finish-output)))))
