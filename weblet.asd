(asdf:defsystem #:weblet
  :description "Weblet, a way to turn your phone into a tablet from the web"
  :author "Johan Felisaz <johan.felisaz@protonmail.com>"
  :license  "MIT License"
  :version "0.0.1"

  ;; Build options
  :build-operation "asdf:program-op"
  :build-pathname "weblet"
  :entry-point "weblet:main"

  :serial t
  :depends-on (clack
	       alexandria
	       anaphora
	       spinneret
	       parenscript
	       cl-ppcre
	       cl-json
	       ;; for viz
	       sdl2)
  
  :components ((:module "src"
		:serial t
		:components ((:file "package")
			     (:file "utils")
			     (:file "viz")
			     (:file "xmove")
			     (:file "weblet")))))
