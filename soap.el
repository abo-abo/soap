;;; soap.el --- Smart Operator a posteriori

;; Copyright (C) 2015 Oleh Krehel

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Insert spaces around operators, e.g. " += ".
;;
;; Based on smart-operator.el by William Xu.

;;; Code:

(defvar soap-alist
  '("\\+" "-" "\\*" "/" "%" "&" "|" "<" "=" ">"))

(defun soap-in-string-or-comment-p ()
  "Test if point is inside a string or a comment."
  (or
   ;; proper
   (let ((beg (nth 8 (syntax-ppss))))
     (and beg
          (or (eq (char-after beg) ?\")
              (eq (char-after beg) ?\')
              (comment-only-p beg (point)))
          beg))
   ;; works for `matlab-mode'
   (eq (get-text-property (point) 'face)
       'font-lock-string-face)))

(defun soap-default-action (op)
  "Insert OP, possibly with spaces around it."
  (delete-horizontal-space t)
  (let ((op-p nil)
        (one-char-back nil))
    (unless (bolp)
      (backward-char)
      (setq one-char-back t))
    (setq op-p
          (catch 'return
            (dolist (front soap-alist)
              (when (looking-at front)
                (throw 'return t)))))
    (when (and (or op-p (not (and (bolp) (eolp))))
               one-char-back)
      (forward-char))
    (if (or op-p (bolp))
        (insert op)
      (insert " " op)))
  (delete-horizontal-space t)
  (insert " "))

(defun soap-command ()
  "Similar to `self-insert-command', except handles whitespace."
  (interactive)
  (let ((op (this-command-keys)))
    (cond ((and (soap-in-string-or-comment-p)
                (member op (list "+" "-" "*" "/" "%" "&" "|")))
           (insert op))

          ((string= op "+")
           (cond
             ((looking-back " \\+ ")
              (backward-delete-char 3)
              (insert "++"))
             ((looking-back "\\s-\\|=\\|\\+\\|\\([0-9.]+e\\)")
              (insert "+"))
             (t (soap-default-action op))))

          ((string= op "-")
           (cond
             ((looking-back " \\- ")
              (backward-delete-char 3)
              (insert "--"))
             ((looking-at "[\\s-]*>")
              (insert op))
             ((looking-back "\\s-\\|=\\|-\\|this\\|(\\|\\([0-9.]+e\\)")
              (insert op))
             ((looking-back "[[]")
              (insert op))
             (t (soap-default-action op))))

          ((and (string= op "*")
                (or (looking-back "(\\|[\t :.]+")
                    (looking-at ">")
                    (looking-back "^\\sw+")
                    (looking-back "char\\|int\\|double\\|void")))
           (insert op))

          ((and (string= op "/")
                (or (looking-back "\\.")
                    (looking-back "^#.*")))
           (insert op))

          ((and (string= op "%")
                (looking-back "[ \t]+"))
           (insert op))

          ((string= op "&")
           (if (looking-back "&")
               (progn (backward-delete-char 1)
                      (insert "&& "))
             (unless (looking-back " \\|(")
               (insert " "))
             (insert "&")))

          ((string= op ",")
           (if (and (looking-at "[^\n<]*>")
                    (looking-back "<[^\n>]+"))
               (insert op)
             (insert ", ")))

          ((and (string= op ">")
                (looking-back "\\(?:this\\)?\\(-\\| \\- \\)"))
           (delete-region (match-beginning 1)
                          (match-end 1))
           (insert "->"))

          ((and (string= op "=") (looking-back "!"))
           (backward-delete-char 1)
           (insert " != "))

          (t
           (soap-default-action op)))))

(provide 'soap)

;;; soap.el ends here
