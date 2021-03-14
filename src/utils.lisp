(in-package #:weblet)

(defun drop-multiple-values (v)
  "I know this is dumb, but it works"
  v)

(defun cdr-assoc (item alist)
  (cdr (assoc item alist)))

(defun to-keyword (x)
  (intern (string-upcase (string x))
	  :keyword))
