;;; auto-tangle-mode.el --- Minor mode for tangling literate files on save

;;; Commentary:
;; A simple mode for tangling literate org files on save.

;;; Code:
(require 'org)
(require 'ob-tangle)

(defvar-local auto-tangle-predicates '(auto-tangle-org-mode-p org-in-src-block-p)
  "List of predicates checked before tangling.
Any predicate returning a nil value prevents tangling and hooks from being run.")

(defvar-local auto-tangle-after-tangle-hook ()
  "Hooks run after tangling.")

(defvar-local auto-tangle-before-tangle-hook ()
  "Hooks run before tangling.")

(defun auto-tangle-org-mode-p ()
  "Non-nil if current buffer's `major-mode' is `org-mode'."
  (equal major-mode 'org-mode))

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
            (org-babel-tangle)
            (run-hooks 'auto-tangle-after-tangle-hook)))))))

;;###autoload
(define-minor-mode auto-tangle-mode
  "Auto tangle Org src blocks on file save."
  :lighter " atm"
  (if auto-tangle-mode
      (add-hook 'after-save-hook 'auto-tangle-maybe-tangle nil t)
    (remove-hook 'after-save-hook 'auto-tangle-maybe-tangle t)))

(provide 'auto-tangle-mode)

;;; auto-tangle-mode.el ends here
