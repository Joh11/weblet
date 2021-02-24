;; Moving the cursor using xlib

(in-package #:weblet/cffi)

(define-foreign-library :libx11
  (t "libX11.so"))

(define-foreign-library :libxtst
  (t "libXtst.so"))

(use-foreign-library :libx11)
(use-foreign-library :libxtst)

(defcfun ("XOpenDisplay" open-display) :pointer
  (display-name :pointer))

(defcfun ("XTestFakeRelativeMotionEvent" test-fake-relative-motion-event) :int
  (display :pointer)
  (x :int) (y :int)
  (delay :unsigned-long))

(defcfun ("XFlush" flush) :int
  (display :pointer))

(in-package #:weblet)

(defmacro xmove-with-open-display (display &body body)
  `(let ((,display (weblet/cffi:open-display (cffi:null-pointer))))
     ,@body))

(defun xmove-mouse-relative (display x y)
  ;; Because the CurrentTime is = 0L in <X11/X.h>
  (weblet/cffi:test-fake-relative-motion-event display x y 0)
  (weblet/cffi:flush display))
