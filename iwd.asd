(asdf:defsystem #:iwd
  :description "WiFi IWD information module for StumpWM"
  :author "Dmitrii Kosenkov"
  :license  "GPLv3"
  :version "0.1.0"
  :serial t
  :depends-on (#:stumpwm #:dbus)
  :components ((:file "iwd")))
