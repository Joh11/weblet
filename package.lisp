(defpackage #:weblet
  (:use #:cl
	#:anaphora
	#:spinneret
	#:parenscript)
  (:export #:main))

(defpackage #:weblet/cffi
  (:use #:cl
	#:anaphora
	#:cffi)
  (:export #:open-display
	   #:test-fake-relative-motion-event
	   #:flush))
