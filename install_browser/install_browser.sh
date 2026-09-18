#!/bin/bash
# Installs the Nyxt browser via Flatpak (Flathub), applies a dark
# theme using the Doom Emacs "laserwave" palette (matching the editor
# setup in ../install_editor), and sets up a "nyxt" shell alias to
# launch it.
#
# Usage: ./install_browser.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ID="engineer.atlas.Nyxt"
NYXT_CONFIG_DIR="$HOME/.var/app/$APP_ID/config/nyxt"

echo "=== Nyxt browser (Flatpak) installer ==="

# ---------------------------------------------------------------------------
# 1. Flatpak + Flathub
# ---------------------------------------------------------------------------
echo "--- Installing flatpak ---"
if ! command -v flatpak >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm flatpak
fi

flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------------------
# 2. Nyxt
# ---------------------------------------------------------------------------
echo "--- Installing Nyxt ($APP_ID) ---"
flatpak install --user -y flathub "$APP_ID"

# ---------------------------------------------------------------------------
# 3. Symlink checked-in config (dark laserwave theme) over Nyxt's
#    per-user Flatpak config location
# ---------------------------------------------------------------------------
echo "--- Linking Nyxt config from $SCRIPT_DIR/nyxt ---"
mkdir -p "$NYXT_CONFIG_DIR"
ln -sf "$SCRIPT_DIR/nyxt/config.lisp" "$NYXT_CONFIG_DIR/config.lisp"

# ---------------------------------------------------------------------------
# 4. Shell alias
# ---------------------------------------------------------------------------
echo "--- Setting up 'nyxt' alias ---"
ALIAS_LINE="alias nyxt='flatpak run $APP_ID'"
if ! grep -qF "$ALIAS_LINE" "$HOME/.bashrc" 2>/dev/null; then
    echo "$ALIAS_LINE" >> "$HOME/.bashrc"
fi

echo
echo "=== Done ==="
echo "Restart your shell (or 'source ~/.bashrc') to pick up the 'nyxt' alias."
echo "Launch with 'nyxt' — it starts in dark laserwave-themed mode."
