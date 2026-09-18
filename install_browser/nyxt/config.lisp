;;; config.lisp -*- mode: lisp; -*-

;; Dark theme built from the Doom Emacs "laserwave" palette, to match
;; the editor setup (see ../../install_editor/doom/config.el, which sets
;; `doom-theme' to 'doom-laserwave).
(define-configuration browser
  ((theme (make-instance 'theme:theme
                          :dark-p t
                          :background-color "#27212E"
                          :on-background-color "#FFFFFF"
                          :accent-color "#EB64B9"
                          :on-accent-color "#27212E"
                          :primary-color "#40B4C4"
                          :on-primary-color "#FFFFFF"
                          :secondary-color "#3E3549"
                          :on-secondary-color "#ECEFF4"))))
