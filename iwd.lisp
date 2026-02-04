(defpackage :iwd
  (:use #:cl #:stumpwm #:alexandria))
(in-package :iwd)

(defvar *check-interval* 3)
(defvar *destination* "net.connman.iwd")
(defvar *connected-network* nil)

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

(defun get-device-property (bus prop)
  (dbus:with-introspected-object (device bus
                                         *station-path*
                                         *destination*)
    (device "org.freedesktop.DBus.Properties" "Get"
            "net.connman.iwd.Station" prop)))

(defun get-network-property (bus network-path prop)
  (dbus:with-introspected-object (station bus
                                          network-path
                                          *destination*)
    (station "org.freedesktop.DBus.Properties" "Get"
             "net.connman.iwd.Network" prop)))

(defun get-station-ordered-networks (bus path)
  (dbus:with-introspected-object (station bus
                                          path
                                          *destination*)
    (station "net.connman.iwd.Station" "GetOrderedNetworks")))

(defun get-all-objects (bus)
  (dbus:get-managed-objects bus *destination* "/"))

(defun get-objects-with-connected-stations (bus)
  (remove-if (lambda (obj)
               (let ((station (assql-value (cadr obj) "net.connman.iwd.Station")))
                 (or (not station)
                     (not (equal (assql-value station "State")
                                 "connected")))))
             (get-all-objects bus)))

(defun get-info ()
  (dbus:with-open-bus (bus (dbus:system-server-addresses))
    (when-let ((connected-obj (car (get-objects-with-connected-stations bus))))
      (let* ((station (assql-value (cadr connected-obj) "net.connman.iwd.Station"))
             (connected-network-path (assql-value station "ConnectedNetwork"))
             (networks (get-station-ordered-networks bus (car connected-obj))))
        (cons (get-network-property bus connected-network-path "Name")
              (dbm-to-quality-percent (/ (assql-value networks connected-network-path) 100)))))))

(defun update-info ()
  (setf *connected-network* (get-info)))

(defun init ()
  (update-info)
  (run-with-timer 0 *check-interval* #'update-info))

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
