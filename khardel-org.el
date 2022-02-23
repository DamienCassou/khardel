;;; khardel-org.el --- Support for links to khard contact buffers in org  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022  Nicolas Petton

;; Author: Nicolas Petton <nicolas@petton.fr>
;; Url: https://github.com/DamienCassou/khardel
;; Package-requires: ((emacs "27.1"))
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

;; This file implements org links to khard contact edit buffers.  A query to
;; find a khard contact by its full name is performed when a link is followed.

;;; Code:

(require 'org)
(require 'map)
(require 'khardel)

(defun khardel-org--follow-link (fullname)
  "Follow a khardel link specified by FULLNAME.
FULLNAME is a string to match against a contact name."
  (let ((contact (seq-find (lambda (contact)
			     (string= (cdr contact) fullname))
                           (map-values (khardel--list-contacts)))))
    (khardel-edit-contact contact)))

(defun khardel-org--link-complete (&optional _)
  "Complete a contact name.
Return an `org-mode' link for the completed contact."
  (khardel-org--link (khardel-choose-contact)))

(defun khardel-org--store-link ()
  "Store a link to a khard contact from a khard contact edit buffer."
  (when (eq major-mode 'khardel-edit-mode)
    (org-link-store-props :type "khardel"
			  :description (cdr khardel-edit-contact)
			  :link (khardel-org--link khardel-edit-contact))))

(defun khardel-org--link (contact)
  "Return an `org-mode' khardel link for CONTACT."
  (format "khardel:%s" (cdr contact)))

(org-link-set-parameters "khardel"
                         :complete #'khardel-org--link-complete
                         :follow #'khardel-org--follow-link
			 :store #'khardel-org--store-link)

(provide 'khardel-org)
;;; khardel-org.el ends here

;;; LocalWords:  khardel khard
