;;; Commentary:
;;
;; mu4e configurations.
;;

;;; Code:

(use-package mu4e
  :straight t
  :commands (mu4e mu4e-compose-new)
  :config
  (use-package mu4e-maildirs-extension
    :straight t
    :init (with-eval-after-load 'mu4e (mu4e-maildirs-extension-load)))

  ;; Try to display images in mu4e
  (setq
   mu4e-view-show-images t
   mu4e-view-image-max-width 800)

  (setq mu4e-maildir "~/Mail"
        mu4e-attachment-dir "/Files"
        mu4e-get-mail-command "offlineimap"
        mu4e-update-interval nil
        mu4e-compose-signature-auto-include nil
        mu4e-view-show-images t
        mu4e-view-show-addresses t)

  (setq mu4e-headers-date-format "%y-%m-%d %H:%M")
  (setq mu4e-headers-fields
        '( (:human-date    .   20)
           (:flags         .    6)
           (:mailing-list  .   10)
           (:from          .   22)
           (:subject       .   nil)))
  (setq mu4e-html2text-command "w3m -dump -T text/html")

  ;;; Mail directory shortcuts
  (setq mu4e-maildir-shortcuts
        '(("/work/INBOX" . ?w)
          ("/personal/Inbox" . ?p)))

;;; Bookmarks
  (setq mu4e-bookmarks
        `(("flag:unread AND NOT flag:trashed" "Unread messages" ?u)
          ("date:today..now" "Today's messages" ?t)
          (,(mapconcat 'identity
                       (mapcar
                        (lambda (maildir)
                          (concat "maildir:" (car maildir)))
                        mu4e-maildir-shortcuts) " OR ")
           "All inboxes" ?i)))
  ;; multiple accounts
  (defvar my-mu4e-account-alist
    '(("work"
       (mu4e-sent-folder "/work/Sent")
       (mu4e-drafts-folder "/work/Drafts")
       (mu4e-trash-folder "/work/Trash")
       (user-mail-address "w.dai@imperial.ac.uk"))
      ("personal"
       (mu4e-sent-folder "/personal/Sent")
       (mu4e-drafts-folder "/personal/Drafts")
       (mu4e-trash-folder "/personal/Trash")
       (user-mail-address "dai.wzero@hotmail.com"))))

  (setq mu4e-contexts
        `( ,(make-mu4e-context
             :name "Work"
             :enter-func (lambda () (mu4e-message "Switch to the Work context"))
             :leave-func (lambda () (mu4e-message "Leaving Work context"))
             ;; leave-fun not defined
             :match-func (lambda (msg)
                           (when msg
                             (mu4e-message-contact-field-matches msg
                                                                 :to "w.dai@imperial.ac.uk")))
             :vars '( (user-mail-address . "w.dai@imperial.ac.uk")
                      (user-full-name . "Wang-Zhou Dai")
                      (mu4e-sent-folder . "/work/Sent")
                      (mu4e-drafts-folder . "/work/Drafts")
                      (mu4e-trash-folder . "/work/Trash")))
           ,(make-mu4e-context
             :name "Private"
             :enter-func (lambda () (mu4e-message "Switch to the Private context"))
             :leave-func (lambda () (mu4e-message "Leaving Work context"))
             ;; leave-func not defined
             :match-func (lambda (msg)
                           (when msg
                             (mu4e-message-contact-field-matches msg
                                                                 :to "dai.wzero@hotmail.com")))
             :vars '( (user-mail-address . "dai.wzero@hotmail.com")
                      (user-full-name . "Wang-Zhou Dai")
                      (mu4e-sent-folder . "/personal/Sent")
                      (mu4e-drafts-folder . "/personal/Drafts")
                      (mu4e-trash-folder . "/personal/Trash")))))

  ;; set `mu4e-context-policy` and `mu4e-compose-policy` to tweak when mu4e should
  ;; guess or ask the correct context, e.g.
  ;; start with the first (default) context;
  ;; default is to ask-if-none (ask when there's no context yet, and none match)
  (setq mu4e-context-policy 'pick-first)
  ;; compose with the current context if no context matches;
  ;; default is to ask
  ;; '(setq mu4e-compose-context-policy nil)

  ;; sending mail
  (setq message-send-mail-function 'message-send-mail-with-sendmail
        sendmail-program "/usr/bin/msmtp")

  ;; Borrowed from http://ionrock.org/emacs-email-and-mu.html
  ;; Choose account label to feed msmtp -a option based on From header
  ;; in Message buffer; This function must be added to
  ;; message-send-mail-hook for on-the-fly change of From address before
  ;; sending message since message-send-mail-hook is processed right
  ;; before sending message.
  (defun choose-msmtp-account ()
    (if (message-mail-p)
        (save-excursion
          (let*
              ((from (save-restriction
                       (message-narrow-to-headers)
                       (message-fetch-field "from")))
               (account
                (cond
                 ((string-match "dai.wzero@hotmail.com" from) "personal")
                 ((string-match "w.dai@imperial.ac.uk" from) "work"))))
            (setq message-sendmail-extra-arguments (list '"-a" account))))))
  (setq message-sendmail-envelope-from 'header)
  (add-hook 'message-send-mail-hook 'choose-msmtp-account)

  ;; set account automatically
  (defun my-mu4e-set-account ()
    "Set the account for composing a message."
    (let* ((account
            (if mu4e-compose-parent-message
                (let ((maildir (mu4e-message-field mu4e-compose-parent-message :maildir)))
                  (string-match "/\\(.*?\\)/" maildir)
                  (match-string 1 maildir))
              (completing-read (format "Compose with account: (%s) "
                                       (mapconcat #'(lambda (var) (car var))
                                                  my-mu4e-account-alist "/"))
                               (mapcar #'(lambda (var) (car var)) my-mu4e-account-alist)
                               nil t nil nil (caar my-mu4e-account-alist))))
           (account-vars (cdr (assoc account my-mu4e-account-alist))))
      (if account-vars
          (mapc #'(lambda (var)
                    (set (car var) (cadr var)))
                account-vars)
        (error "No email account found"))))
  (add-hook 'mu4e-compose-pre-hook 'my-mu4e-set-account)

  ;; send attachment directly from dired
  (require 'gnus-dired)
  ;; make the `gnus-dired-mail-buffers' function also work on
  ;; message-mode derived modes, such as mu4e-compose-mode
  (defun gnus-dired-mail-buffers ()
    "Return a list of active message buffers."
    (let (buffers)
      (save-current-buffer
        (dolist (buffer (buffer-list t))
          (set-buffer buffer)
          (when (and (derived-mode-p 'message-mode)
                     (null message-sent-message-via))
            (push (buffer-name buffer) buffers))))
      (nreverse buffers)))

  (setq gnus-dired-mail-mode 'mu4e-user-agent)
  (add-hook 'dired-mode-hook 'turn-on-gnus-dired-mode)

  ;; use C-1 c for add cc if already in composition mode
  (define-key mu4e-compose-mode-map (kbd "C-1 c") 'message-goto-cc)

  ;; signature
  (defun my-mu4e-choose-signature ()
    "Insert one of a number of sigs"
    (interactive)
    (let ((message-signature
           (mu4e-read-option "Signature:"
                             '(("formal" .
                                (concat
                                 "-----\n"
                                 "Wang-Zhou DAI, PhD\n"
                                 "Research Associate\n"
                                 "Department of Computing, Imperial College London.\n"
                                 "W: http://www.example.com\n"))
                               ("informal" .
                                "Wang-Zhou.\n")))))
      (message-insert-signature)))

  (add-hook 'mu4e-compose-mode-hook
            (lambda () (local-set-key (kbd "C-c C-w") #'my-mu4e-choose-signature)))

  ;; insert signature here
  (defun insert-mu4e-sig-here ()
    "Insert the mu4e signature here, assuming it is a string."
    (interactive)
    (save-excursion
      (when (stringp mu4e-compose-signature)
        (insert mu4e-compose-signature))))

  (add-hook 'mu4e-compose-mode-hook 'insert-mu4e-sig-here))

(provide 'init-mail)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-mail.el ends here
