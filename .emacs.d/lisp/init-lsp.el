;;; Commentary:
;;
;; Language Server Protocol (LSP) configurations.
;;

;;; Code:

(use-package lsp-mode
  :straight t
  :diminish lsp-mode
  :hook (prog-mode . lsp)
  :bind (:map lsp-mode-map
              ("C-c C-d" . lsp-describe-thing-at-point))
  :init
  (setq lsp-auto-guess-root t)       ; Detect project root
  (setq lsp-prefer-flymake nil)      ; Use lsp-ui and flycheck
  (setq flymake-fringe-indicator-position 'right-fringe)
  :config
  ;; Configure LSP clients
  (use-package lsp-clients
    :init
    (setq lsp-clients-python-library-directories '("/usr/local/" "/usr/"))))

(use-package lsp-ui
  :straight t
  :custom-face
  (lsp-ui-doc-background ((t (:background nil))))
  (lsp-ui-doc-header ((t (:inherit (font-lock-string-face italic)))))
  :bind (:map lsp-ui-mode-map
              ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
              ([remap xref-find-references] . lsp-ui-peek-find-references)
              ("C-c u" . lsp-ui-imenu))
  :init (setq lsp-ui-doc-enable t
              lsp-ui-doc-header t
              lsp-ui-doc-include-signature t
              lsp-ui-doc-position 'top
              lsp-ui-doc-use-webkit t
              lsp-ui-doc-border (face-foreground 'default)

              lsp-ui-sideline-enable nil
              lsp-ui-sideline-ignore-duplicate t)
  :config
  ;; WORKAROUND Hide mode-line of the lsp-ui-imenu buffer
  ;; https://github.com/emacs-lsp/lsp-ui/issues/243
  (defadvice lsp-ui-imenu (after hide-lsp-ui-imenu-mode-line activate)
    (setq mode-line-format nil)))

(use-package company-lsp
  :straight t
  :init (setq company-lsp-cache-candidates 'auto))

;; C/C++/Objective-C support
(use-package ccls
  :straight t
  :defines projectile-project-root-files-top-down-recurring
  :hook ((c-mode c++-mode objc-mode cuda-mode) . (lambda ()
                                                   (require 'ccls)
                                                   (lsp)))
  :config
  (with-eval-after-load 'projectile
    (setq projectile-project-root-files-top-down-recurring
          (append '("compile_commands.json"
                    ".ccls")
                  projectile-project-root-files-top-down-recurring))))

(provide 'init-lsp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-lsp.el ends here
