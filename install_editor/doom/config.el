;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-laserwave)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Always start Emacs fullscreen (applies to new frames too, e.g. emacsclient).
;; (add-to-list 'default-frame-alist '(fullscreen . maximized))

(defun build-and-deploy ()
  "Compile and then deploy your project."
  (interactive)
  (compile "npm run deploy -- --server mmo"))

;; Claude Code IDE
(use-package! claude-code-ide
  :commands claude-code-ide-menu
  :config
  (claude-code-ide-emacs-tools-setup))

;; NOTE: all "SPC o" bindings must live in ONE map! call. Each separate
;; `(:prefix ("o" . "open") ...)` block creates a fresh prefix keymap and
;; rebinds "o" to it wholesale, wiping out entries added by earlier blocks.
(map! :leader
      (:prefix ("o" . "open")
       :desc "Build and Deploy" "D" #'build-and-deploy
       :desc "Claude Code IDE" "c" #'claude-code-ide-menu))

(after! claude-code-ide
  ;; 1. Disable the package's internal side-window management
  (setq claude-code-ide-use-side-window nil)

  ;; 2. Direct Doom Emacs to treat Claude buffers as a bottom popup
  (set-popup-rule! "^\\*claude-code\\[.*\\]\\*"
    :side 'bottom
    :size 0.20      ; Height of the window (35% of the screen)
    :ttl nil        ; Keep the buffer alive when closed
    :quit nil       ; Prevent accidental closing via ESC
    :select t))     ; Move your cursor focus to it automatically upon opening

;; Override the rust module's tree-sitter grammar pin (default v0.23.2 for
;; ABI < 15): that revision fails to build/load, so pin v0.23.3 instead.
(set-tree-sitter! 'rust-mode 'rustic-mode
  `((rust :url "https://github.com/tree-sitter/tree-sitter-rust"
     :rev "v0.23.3")))

;; Must be set before `rust-mode' is required, so it can't go in an `after!'
;; block: makes rustic-mode derive its font-lock/indentation from rust-ts-mode
;; instead of classic regex-based rust-mode.
(setq rust-mode-treesitter-derive t)

;; Evil's normal-state map shadows the global `M-.' -> `+lookup/definition'
;; remap with `evil-repeat-pop-next'. Restore the conventional jump-to-def
;; binding (same as `gd').
(map! :n "M-." #'+lookup/definition)

;; Format-on-save (rustfmt) for Rust ONLY — the `(not ...)` form turns the
;; disabled-modes list into an allowlist, so other languages (python/json in
;; embedded-apps) are never surprise-reformatted on save.
(setq +format-on-save-disabled-modes
      '(not rust-mode rust-ts-mode rustic-mode))

;; Bare rustfmt (what apheleia runs) doesn't read Cargo.toml, so tell it the
;; workspace's edition explicitly — otherwise edition-2024 syntax (let-chains)
;; fails to parse and format-on-save silently no-ops on those files. The CLI
;; --edition flag matches how `cargo fmt` invokes rustfmt, so editor output
;; is byte-identical to what CI checks.
(after! apheleia
  (setf (alist-get 'rustfmt apheleia-formatters)
        '("rustfmt" "--quiet" "--emit" "stdout" "--edition" "2024")))

(add-hook 'window-setup-hook #'toggle-frame-maximized)
