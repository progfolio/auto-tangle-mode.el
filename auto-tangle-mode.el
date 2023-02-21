;;; auto-tangle-mode.el --- Minor mode for tangling literate files on save  -*- lexical-binding: t; -*-

;; Author: Nicholas Vollmer <progfolio@protonmail.com>
;; URL: https://github.com/progfolio/auto-tangle-mode.el
;; Created: Jun 23, 2019
;; Keywords: org, convenience
;; Package-Requires: ((emacs "27.1"))
;; Version: 0.0.0

;;; Commentary:
;; A simple mode for tangling literate org files on save.

;;; Code:
(require 'org)
(require 'ob-tangle)

;;;; Customizations:
(defgroup auto-tangle nil
  "Minor mode for tangling literate files on save."
  :group 'org
  :prefix "auto-tangle-")

(defcustom auto-tangle-predicates '(auto-tangle-org-mode-p org-in-src-block-p)
  "List of predicates checked before tangling.
Any predicate returning a nil value prevents tangling and hooks from being run."
  :type 'list)

(defcustom auto-tangle-after-tangle-hook '(auto-tangle-process-buffer-contents)
  "Hooks run after tangling."
  :type 'hook)

(defcustom auto-tangle-before-tangle-hook ()
  "Hooks run before tangling."
  :type 'hook)

;;;; Functions:
(defun auto-tangle-org-mode-p ()
  "Non-nil if current buffer's `major-mode' is `org-mode'."
  (derived-mode-p 'org-mode))

(defun auto-tangle-process-buffer-contents ()
  "Message contents of auto-tangle process buffer."
  (when-let ((buffer (get-buffer "*auto-tangle*")))
    (with-current-buffer buffer
      (message "%s" (string-trim (buffer-substring-no-properties (point-min) (point-max))))
      (erase-buffer))))

(defun auto-tangle-process-sentinel (_ event)
  "Sentinel for auto-tangle process EVENT."
  (let ((output (with-current-buffer (get-buffer-create "*auto-tangle*")
                  (buffer-substring-no-properties (point-min) (point-max)))))
    (if (not (equal event "finished\n"))
        (user-error "%S" output)
      (message "%S" output)
      (run-hooks 'auto-tangle-after-tangle-hook)
      (when-let ((buffer (get-buffer "*auto-tangle*"))
                 ((buffer-live-p buffer)))
        (kill-buffer buffer)))))

(defun auto-tangle-maybe-tangle ()
  "Tangle current buffer if `auto-tangle-predicates' are satisified.
Run `auto-tangle-before-tangle-hook' and `auto-tangle-after-tangle-hook'."
  (let ((point (point)))
    (save-excursion
      (save-restriction
        ;;Tangle whether in org-src buffer, or indirect clone of base buffer
        (with-current-buffer (or (buffer-base-buffer)
                                 (ignore-errors (org-src-source-buffer))
                                 (current-buffer))
          ;;Normally, org will only tangle the narrowed
          ;;region when editing in a narrowed buffer.
          (widen)
          (goto-char point)
          (org-reveal)
          (when (seq-every-p #'funcall auto-tangle-predicates)
            (run-hooks 'auto-tangle-before-tangle-hook)
            (make-process :name "auto-tangle"
                          :buffer "*auto-tangle*"
                          :command (list "emacs" "--batch" "--execute"
                                         (format
                                          "(progn (require 'ob-tangle) (setq org-confirm-babel-evaluate nil) (org-babel-tangle-file %S))"
                                          (buffer-file-name)))
                          :sentinel #'auto-tangle-process-sentinel)))))))

(define-minor-mode auto-tangle-mode
  "Tangle Org src blocks on file save."
  :lighter " atm"
  (if auto-tangle-mode
      (add-hook 'after-save-hook 'auto-tangle-maybe-tangle nil t)
    (remove-hook 'after-save-hook 'auto-tangle-maybe-tangle t)))

(provide 'auto-tangle-mode)

;;; auto-tangle-mode.el ends here
