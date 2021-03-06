;; notmuch-company.el --- Mail address completion for notmuch via company-mode  -*- lexical-binding: t -*-

;; Authors: Trevor Jim <tjim@mac.com>
;; 	    Michal Sojka <sojkam1@fel.cvut.cz>
;;
;; Keywords: mail, completion

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To enable this, install company mode (https://company-mode.github.io/)
;;
;; NB company-minimum-prefix-length defaults to 3 so you don't get
;; completion unless you type 3 characters

;;; Code:

(eval-when-compile (require 'cl))

(defvar notmuch-company-last-prefix nil)
(make-variable-buffer-local 'notmuch-company-last-prefix)
(declare-function company-begin-backend "company")
(declare-function company-grab "company")
(declare-function company-mode "company")
(declare-function company-manual-begin "company")
(defvar company-backends)

(declare-function notmuch-address-harvest "notmuch-address")
(declare-function notmuch-address-harvest-trigger "notmuch-address")
(declare-function notmuch-address-matching "notmuch-address")
(defvar notmuch-address-full-harvest-finished)
(defvar notmuch-address-completion-headers-regexp)

;;;###autoload
(defun notmuch-company-setup ()
  (company-mode)
  (make-local-variable 'company-backends)
  (setq company-backends '(notmuch-company)))

;;;###autoload
(defun notmuch-company (command &optional arg &rest _ignore)
  "`company-mode' completion back-end for `notmuch'."
  (interactive (list 'interactive))
  (require 'company)
  (let ((case-fold-search t)
	(completion-ignore-case t))
    (case command
      (interactive (company-begin-backend 'notmuch-company))
      (prefix (and (derived-mode-p 'message-mode)
		   (looking-back (concat notmuch-address-completion-headers-regexp ".*")
				 (line-beginning-position))
		   (setq notmuch-company-last-prefix (company-grab "[:,][ \t]*\\(.*\\)" 1 (point-at-bol)))))
      (candidates (cond
		   (notmuch-address-full-harvest-finished
		    ;; Update harvested addressed from time to time
		    (notmuch-address-harvest-trigger)
		    (notmuch-address-matching arg))
		   (t
		    (cons :async
			  (lambda (callback)
			    ;; First run quick asynchronous harvest based on what the user entered so far
			    (notmuch-address-harvest
			     (format "to:%s*" arg) nil
			     (lambda (_proc _event)
			       (funcall callback (notmuch-address-matching arg))
			       ;; Then start the (potentially long-running) full asynchronous harvest if necessary
			       (notmuch-address-harvest-trigger))))))))
      (match (if (string-match notmuch-company-last-prefix arg)
		 (match-end 0)
	       0))
      (no-cache t))))


(provide 'notmuch-company)
