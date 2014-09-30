;;; node-resolver.el --- hook to install node modules in background

;; Copyright © 2014 Dave Justice

;; Author: Dave Justice
;; URL: https://github.com/meandavejustice/node-resolver-mode.el
;; Version: 0.1.0
;; Created: 2014-09-29
;; Keywords: convenience, nodejs, javascript, npm

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This package provides a way to start a background process from
;; emacs to install node_modules based on require statements found
;; on file save events.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:


(defvar *node-resolver-project-root* nil
  "Used internally to cache the project root.")

(defvar node-resolver-active-projects ()
  "List of active projects")

(defvar node-resolver-project-roots
  '(".git" ".hg" "Rakefile" "Makefile" "README" "build.xml" ".emacs-project"
    ".emacs-project" "node_modules" "package.json" "LICENSE" "bower.json")
  "The presence of any file/directory in this list indicates a project root.")

(defun root-match(root names)
  (member (car names) (directory-files root)))

(defun root-matches(root names)
  (if (root-match root names)
      (root-match root names)
    (if (eq (length (cdr names)) 0)
        'nil
      (root-matches root (cdr names))
      )))

(defun node-resolver-find-project-root (&optional root)
  "Determines the current project root by recursively searching for an indicator."
  (when (null root) (setq root default-directory))
  (cond
   ((root-matches root *node-resolver-project-roots*)
    (expand-file-name root))
   ((equal (expand-file-name root) "/") nil)
   (t (node-resolver-find-project-root (concat (file-name-as-directory root) "..")))))

(defun node-resolver-project-root ()
  "Returns the current project root."
  (when (or
         (null *node-resolver-project-root*)
         (not (string-match *node-resolver-project-root* default-directory)))
    (let ((root (node-resolver-find-project-root)))
      (if root
          (setq *node-resolver-project-root* (expand-file-name (concat root "/")))
        (setq *node-resolver-project-root* nil))))
  *node-resolver-project-root*)

(defun node-resolver-start ()
  (if (not (member (npm-install-project-root) npm-install-active-projects))
      (and (start-process "node-resolver bg process" nil "node-resolver" (node-resolver-project-root))
           (push (npm-install-project-root) npm-install-active-projects))))

(provide 'node-resolver)
;;; node-resolver.el ends here
