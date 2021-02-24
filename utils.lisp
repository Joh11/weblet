(in-package #:weblet)

(defun cdr-assoc (item alist)
  (cdr (assoc item alist)))

(defun to-keyword (x)
  (intern (string-upcase (string x))
	  :keyword))
