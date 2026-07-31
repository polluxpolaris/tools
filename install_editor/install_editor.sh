#!/bin/bash
# Wipes any existing Emacs/Doom config and installs a fresh Doom Emacs
# setup, then symlinks in the checked-in config from doom/ (init.el,
# config.el, packages.el — lsp, rust+tree-sitter, vterm, python,
# claude-code-ide, format-on-save).
#
# Usage: ./install_editor.sh [--yes]
#   --yes   skip the destructive-wipe confirmation prompt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
# 4. Claude Code CLI (native installer, no Node.js required)
# ---------------------------------------------------------------------------
echo "--- Installing Claude Code CLI ---"
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "claude already installed, skipping"
fi

# ---------------------------------------------------------------------------
# 5. Doom Emacs
# ---------------------------------------------------------------------------
echo "--- Installing Doom Emacs ---"
git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_EMACS_DIR"

export PATH="$DOOM_EMACS_DIR/bin:$PATH"
if ! grep -q "$DOOM_EMACS_DIR/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo "export PATH=\"$DOOM_EMACS_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

doom install --force

# ---------------------------------------------------------------------------
# 6. Symlink checked-in config (doom/init.el, config.el, packages.el) over
#    the template Doom just generated in $DOOM_DIR
# ---------------------------------------------------------------------------
echo "--- Linking Doom config from $SCRIPT_DIR/doom ---"
for f in init.el config.el packages.el; do
    ln -sf "$SCRIPT_DIR/doom/$f" "$DOOM_DIR/$f"
done

# ---------------------------------------------------------------------------
# 7. Sync Doom
# ---------------------------------------------------------------------------
echo "--- Running doom sync ---"
doom sync

systemctl --user enable --now emacs
#TODO:  Add to path export PATH="$PATH:$HOME/.config/emacs/bin"
#

echo
echo "=== Done ==="
echo "Restart your shell (or 'source ~/.bashrc') to pick up the doom CLI on PATH."
echo "Launch Emacs, then use SPC o c to open the Claude Code IDE menu."
echo "Run 'doom doctor' to check for any environment issues."
