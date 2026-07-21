#!/bin/bash
# Wipes any existing Emacs/Doom config and installs a fresh Doom Emacs
# setup with rustic (Rust IDE support) and claude-code-ide.
#
# Usage: ./install_editor.sh [--yes]
#   --yes   skip the destructive-wipe confirmation prompt

set -euo pipefail

ASSUME_YES=0
[ "${1:-}" = "--yes" ] || [ "${1:-}" = "-y" ] && ASSUME_YES=1

DOOM_EMACS_DIR="$HOME/.config/emacs"
DOOM_DIR="$HOME/.config/doom"

echo "=== Doom Emacs + Rust + claude-code-ide installer ==="

# ---------------------------------------------------------------------------
# 1. Wipe any previous Emacs/Doom config
# ---------------------------------------------------------------------------
OLD_PATHS=(
    "$HOME/.emacs.d"
    "$HOME/.doom.d"
    "$HOME/.emacs"
    "$DOOM_EMACS_DIR"
    "$DOOM_DIR"
    "$HOME/.cache/doom"
)

if [ "$ASSUME_YES" -ne 1 ]; then
    echo "This will permanently delete any existing Emacs/Doom config:"
    printf '  %s\n' "${OLD_PATHS[@]}"
    read -r -p "Continue? [y/N] " REPLY
    case "$REPLY" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
fi

echo "--- Removing previous config ---"
rm -rf "${OLD_PATHS[@]}"

# ---------------------------------------------------------------------------
# 2. System dependencies
# ---------------------------------------------------------------------------
echo "--- Installing system dependencies ---"
sudo apt-get update
sudo apt-get install -y \
    git \
    curl \
    emacs \
    ripgrep \
    fd-find \
    build-essential \
    cmake \
    libtool \
    libtool-bin \
    pkg-config \
    libvterm-dev

# Doom expects `fd`, Debian/Ubuntu ships it as `fdfind`
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# ---------------------------------------------------------------------------
# 3. Rust toolchain + language server
# ---------------------------------------------------------------------------
echo "--- Installing Rust toolchain ---"
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"

rustup component add rust-analyzer rustfmt clippy rust-src

# ---------------------------------------------------------------------------
# 4. Doom Emacs
# ---------------------------------------------------------------------------
echo "--- Installing Doom Emacs ---"
git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_EMACS_DIR"

export PATH="$DOOM_EMACS_DIR/bin:$PATH"
if ! grep -q "$DOOM_EMACS_DIR/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo "export PATH=\"$DOOM_EMACS_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

doom install --force

# ---------------------------------------------------------------------------
# 5. Enable the rust and vterm modules, and lsp support, in init.el
# ---------------------------------------------------------------------------
echo "--- Configuring Doom modules (lsp, rust, vterm) ---"
INIT_EL="$DOOM_DIR/init.el"

sed -i -E 's/^[[:space:]]*;;[[:space:]]*lsp([[:space:]].*)?$/  lsp/' "$INIT_EL"
sed -i -E 's/^[[:space:]]*;;[[:space:]]*\(?rust\)?([[:space:]].*)?$/  (rust +lsp)/' "$INIT_EL"
sed -i -E 's/^[[:space:]]*;;[[:space:]]*vterm([[:space:]].*)?$/  vterm/' "$INIT_EL"

for mod in "  lsp" "(rust +lsp)" "  vterm"; do
    grep -qF "$mod" "$INIT_EL" || echo "WARNING: could not auto-enable '$mod' in $INIT_EL - add it manually"
done

# ---------------------------------------------------------------------------
# 6. claude-code-ide package + config + leader keybinding (SPC o c)
# ---------------------------------------------------------------------------
echo "--- Adding claude-code-ide ---"
PACKAGES_EL="$DOOM_DIR/packages.el"
CONFIG_EL="$DOOM_DIR/config.el"

if ! grep -q "claude-code-ide" "$PACKAGES_EL" 2>/dev/null; then
    cat >> "$PACKAGES_EL" <<'EOF'

(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))
EOF
fi

if ! grep -q "claude-code-ide-menu" "$CONFIG_EL" 2>/dev/null; then
    cat >> "$CONFIG_EL" <<'EOF'

;; Claude Code IDE
(use-package! claude-code-ide
  :commands claude-code-ide-menu
  :config
  (claude-code-ide-emacs-tools-setup))

(map! :leader
      (:prefix ("o" . "open")
       :desc "Claude Code IDE" "c" #'claude-code-ide-menu))

(after! claude-code-ide
  ;; 1. Disable the package's internal side-window management
  (setq claude-code-ide-use-side-window nil)

  ;; 2. Direct Doom Emacs to treat Claude buffers as a bottom popup
  (set-popup-rule! "^\\*claude-code\\[.*\\]\\*"
    :side 'bottom
    :size 0.35      ; Height of the window (35% of the screen)
    :ttl nil        ; Keep the buffer alive when closed
    :quit nil       ; Prevent accidental closing via ESC
    :select t))     ; Move your cursor focus to it automatically upon opening
EOF
fi

# ---------------------------------------------------------------------------
# 7. Sync Doom
# ---------------------------------------------------------------------------
echo "--- Running doom sync ---"
doom sync

echo
echo "=== Done ==="
echo "Restart your shell (or 'source ~/.bashrc') to pick up the doom CLI on PATH."
echo "Launch Emacs, then use SPC o c to open the Claude Code IDE menu."
echo "Run 'doom doctor' to check for any environment issues."
