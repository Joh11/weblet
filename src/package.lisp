(uiop:define-package #:weblet
  (:use #:cl
	#:anaphora
	#:spinneret
	#:parenscript)
  (:export #:main))

(uiop:define-package #:weblet/cffi
  (:use #:cl
	#:anaphora
	#:cffi)
  (:export #:init-threads
	   #:open-display
	   #:test-fake-relative-motion-event
	   #:test-fake-button-event
	   #:flush))
