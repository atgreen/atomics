;;; Run after loading atomics.lisp, or after (asdf:load-system :atomics).
(defpackage #:atomics-egcl-tests (:use #:cl))
(in-package #:atomics-egcl-tests)

(defvar *cell* :global)
(defstruct record value)
(defclass object () ((value :initform nil)))

(defmacro check-cas (place)
  `(progn
     (format t "CAS-CHECK ~S~%" ',place)
     (assert (null ,place))
     (assert (eq t (atomics:cas ,place nil :ready)))
     (assert (eq :ready ,place))
     (assert (null (atomics:cas ,place nil :wrong)))
     (assert (eq :ready ,place))))

(let ((cell (cons nil nil))
      (vector (vector nil))
      (symbol (make-symbol "CELL"))
      (record (make-record))
      (object (make-instance 'object)))
  (check-cas (car cell))
  (check-cas (cdr cell))
  (check-cas (svref vector 0))
  (setf (symbol-value symbol) nil)
  (check-cas (symbol-value symbol))
  (let ((replacement (list :key :value)))
    (assert (atomics:cas (symbol-plist symbol) nil replacement))
    (assert (eq replacement (symbol-plist symbol))))
  (check-cas (record-value record))
  (check-cas (slot-value object 'value)))

(let ((*cell* nil))
  (check-cas *cell*))
(assert (eq *cell* :global))

(let ((events nil)
      (cells (vector nil)))
  (assert (atomics:cas (svref (progn (push :place events) cells)
                             (progn (push :index events) 0))
                       (progn (push :old events) nil)
                       (progn (push :new events) :ready)))
  (assert (equal (reverse events) '(:place :index :old :new)) ()
          "Unexpected evaluation order: ~S" (reverse events))
  (assert (eq (svref cells 0) :ready)))

(let ((cells (vector nil)))
  (symbol-macrolet ((cell (svref cells 0)))
    (check-cas cell)))

(let ((counter (vector 0))
      (threads nil))
  (dotimes (worker 4)
    (declare (ignore worker))
    (push (egcl-thread:make-thread
           (lambda ()
             (dotimes (iteration 100)
               (declare (ignore iteration))
               (loop for old = (svref counter 0)
                     until (atomics:cas (svref counter 0) old (1+ old))))))
          threads))
  (dolist (thread threads) (egcl-thread:join-thread thread))
  (assert (= 400 (svref counter 0))))

(dolist (feature '(:atomics-cas-car :atomics-cas-svref
                   :atomics-cas-symbol-plist :atomics-cas-symbol-value
                   :atomics-cas-slot-value :atomics-cas-struct-slot
                   :atomics-cas-special-var))
  (assert (member feature *features*) () "Missing feature: ~S" feature))
(assert (not (member :atomics-cas-custom *features*)))
(format t "ATOMICS-EGCL-CAS-PASS~%")
