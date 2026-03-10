(defpackage :iwd
  (:use #:cl
        #:stumpwm
        #:alexandria)
  (:export #:init
           #:*check-interval*
           #:*modeline-fmt*))
(in-package :iwd)

(defvar *dbus-conn* nil)
(defvar *dbus-bus* nil)
(defvar *dbus-destination* "net.connman.iwd")
(defvar *connected-network* nil)
(defvar *update-lock* (bt:make-lock))

(defparameter *check-interval* 3)
(defparameter *modeline-fmt* "%e - %p%"
  "The default value for displaying wifi information on the modeline")

(defparameter *formatters-alist*
  '((#\p  ml-signal-quality)
    (#\e  ml-name)))

(defun assql-value (alist key)
  (car (assoc-value alist key :test 'equal)))

(defun dbm-to-quality-percent (dbm)
  (cond
    ((>= dbm -50) 100)
    ((<= dbm -100) 0)
    (t (* 2 (+ 100 dbm)))))

(defun get-network-property (network-path prop)
  (dbus:with-introspected-object (station *dbus-bus*
                                          network-path
                                          *dbus-destination*)
    (station "org.freedesktop.DBus.Properties" "Get"
             "net.connman.iwd.Network" prop)))

(defun get-station-ordered-networks (path)
  (dbus:with-introspected-object (station *dbus-bus*
                                          path
                                          *dbus-destination*)
    (station "net.connman.iwd.Station" "GetOrderedNetworks")))

(defun get-all-objects ()
  (dbus:get-managed-objects *dbus-bus* *dbus-destination* "/"))

(defun get-objects-with-connected-stations ()
  (remove-if (lambda (obj)
               (let ((station (assql-value (cadr obj) "net.connman.iwd.Station")))
                 (or (not station)
                     (not (equal (assql-value station "State")
                                 "connected")))))
             (get-all-objects)))

(defun get-info ()
  (when-let ((connected-obj (car (get-objects-with-connected-stations))))
    (let* ((station (assql-value (cadr connected-obj) "net.connman.iwd.Station"))
           (connected-network-path (assql-value station "ConnectedNetwork"))
           (networks (get-station-ordered-networks (car connected-obj))))
      (cons (get-network-property connected-network-path "Name")
            (dbm-to-quality-percent (/ (assql-value networks connected-network-path) 100))))))

(defun update-info ()
  (setf *connected-network* (get-info)))

(defun init ()
  (setf *dbus-conn*
	      (dbus:open-connection
	       (make-instance 'iolib.multiplex:event-base) (dbus:system-server-addresses)))
  (dbus:authenticate (dbus:supported-authentication-mechanisms *dbus-conn*)
                     *dbus-conn*)
  (setf *dbus-bus* (make-instance 'dbus::bus
                                  :name (dbus:hello *dbus-conn*)
                                  :connection *dbus-conn*))
  (update-info)
  (run-with-timer 0 *check-interval*
                  (lambda ()
                    (bt:make-thread (lambda ()
                                      (bt:with-lock-held (*update-lock*)
                                        (update-info)))
                                    :name "iwd-update-info"))))

(defun modeline (ml)
  (declare (ignore ml))
  (format-expand *formatters-alist*
                 *modeline-fmt*
                 *connected-network*))

(defun ml-name (network)
  (or (car network) "no link"))

(defun ml-signal-quality (network)
  (or (cdr network) "-"))

;; modeline formatter.
(add-screen-mode-line-formatter #\I #'modeline)
