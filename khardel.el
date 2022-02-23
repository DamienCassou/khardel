;;; khardel.el --- Integrate with khard              -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://github.com/DamienCassou/khardel
;; Package-requires: ((emacs "27.1") (yaml-mode "0.0.13"))
;; Version: 0.2.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Integrate with khard, a console carddav application to search and
;; edit contacts in carddav/vcard format.

;;; Code:

(require 'map)
(require 'yaml-mode)

(defgroup khardel nil
  "Integrate with khard."
  :group 'external)

(defcustom khardel-command (executable-find "khard")
  "Path to the khard executable file."
  :type 'file)

(defcustom khardel-edit-finished-hook nil
  "Hook run when a contact edition is completed."
  :type 'hook)

(defcustom khardel-vcard-version "3.0"
  "Version of the vcard format used.
This is passed to \"vcard new\".'"
  :type 'string)

(defvar khardel--emails nil
  "Cache a list of strings of the form \"Name <email>\".")

(defun khardel--list-contacts ()
  "Return a map whose keys are names and values are contacts."
  (save-match-data
    (with-temp-buffer
      (call-process khardel-command nil t nil "ls" "--parsable")
      (goto-char (point-min))
      (let ((contacts (make-hash-table :test 'equal)))
        (cl-loop
         while (re-search-forward "^\\([-a-z0-9]*\\)\t\\(.*\\)\t[^\t]*$" nil t)
         do (map-put contacts (match-string 2) (cons (match-string 1) (match-string 2)))
         finally return contacts)))))

(defun khardel--fetch-emails ()
  "Return a list of strings of the form \"Name <email>\" by asking `khardel-command'."
  (save-match-data
    (with-temp-buffer
      (call-process khardel-command nil t nil "email" "--parsable" "--remove-first-line")
      (goto-char (point-min))
      (cl-loop
       while (re-search-forward "^\\([^\t\n]*\\)\t\\([^\t\n]*\\)\t.*$" nil t)
       collect (format "\"%s\" <%s>" (match-string 2) (match-string 1))))))

(defun khardel--list-emails ()
  "Return a list of strings of the form \"Name <email>\"."
  (if khardel--emails
      khardel--emails
    (setq khardel--emails (khardel--fetch-emails))))

(defun khardel-flush-caches ()
  "Delete cached data to force a refresh."
  (interactive)
  (setq khardel--emails nil))

(defun khardel-choose-contact ()
  "Let the user select a contact from a list of all contacts.
Return the contact."
  (let* ((contacts (khardel--list-contacts))
         (contact-name (completing-read "Select a contact: "
                                        (map-keys contacts)
                                        nil
                                        t)))
    (map-elt contacts contact-name)))

(defvar-local khardel-edit-contact nil
  "Store the contact associated with current buffer.
If nil, the buffer represents a new contact.")

;;;###autoload
(defun khardel-edit-contact (contact)
  "Open an editor on CONTACT."
  (interactive (list (khardel-choose-contact)))
  (let ((buffer (generate-new-buffer (format "*khardel<%s>*" (cdr contact)))))
    (with-current-buffer buffer
      (call-process "khard" nil t nil "show" "--format" "yaml" "--uid" (car contact))
      (goto-char (point-min))
      (khardel-edit-mode)
      (setq-local khardel-edit-contact contact))
    (switch-to-buffer buffer)
    (message "Press %s to save the contact and close the buffer."
             (substitute-command-keys "\\[khardel-edit-finish]"))))

;;;###autoload
(defun khardel-new-contact ()
  "Open an editor to creat a new CONTACT."
  (interactive)
  (let ((buffer (generate-new-buffer "*khardel<new>*")))
    (with-current-buffer buffer
      (call-process "khard" nil t nil "template")
      (khardel-edit-mode)
      (setq-local khardel-edit-contact nil))
    (switch-to-buffer buffer)
    (message "Press %s to save the contact and close the buffer."
             (substitute-command-keys "\\[khardel-edit-finish]"))))

(defvar khardel-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'khardel-edit-finish)
    map)
  "Keymap for `khardel-edit-mode'.")

(define-derived-mode khardel-edit-mode yaml-mode "Khardel"
  "Edit a contact through a yaml representation.")

(defun khardel-edit-finish ()
  "Save contact in current buffer with khard."
  (interactive)
  (let* ((filename (make-temp-file "khard"))
         (args (if khardel-edit-contact
                   `("modify"
                     "--uid" ,(car khardel-edit-contact)
                     "--input-file" ,filename)
                 `("new"
                   "--input-file" ,filename
                   "--vcard-version" ,khardel-vcard-version))))
    (write-region (point-min) (point-max) filename)
    (when (equal 0 (apply
                    #'call-process-region
                    "y\n" ;; ⇐ khard asks for confirmation
                    nil
                    "khard"
                    nil t nil
                    args))
      (kill-buffer)
      (run-hooks 'khardel-edit-finished-hook))))

;;;###autoload
(defun khardel-insert-email ()
  "Let the user select an email from a list and insert it."
  (interactive)
  (let* ((emails (khardel--list-emails))
         (email (completing-read "Select email: " emails)))
    (when (stringp email)
      (insert email))))

(provide 'khardel)
;;; khardel.el ends here
