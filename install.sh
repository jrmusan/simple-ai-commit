#!/usr/bin/env bash
# install.sh — installs sac to ~/.local/bin and creates a starter config
#
# Usage:
#   bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SAC_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/simple-ai-commit"
CONFIG_FILE="$CONFIG_DIR/config"

# ── Install binary ─────────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/sac.sh" "$BIN_DIR/sac"
chmod +x "$BIN_DIR/sac"
printf '✅  Installed: %s/sac\n' "$BIN_DIR"

# ── Create config if missing ───────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"
if [[ ! -f "$CONFIG_FILE" ]]; then
  cp "$SCRIPT_DIR/config.example" "$CONFIG_FILE"
  printf '📝  Config created: %s\n' "$CONFIG_FILE"
  printf '    Edit the file and set OPENROUTER_API_KEY.\n'
else
  printf 'ℹ️   Config already exists: %s (not overwritten)\n' "$CONFIG_FILE"
fi

# ── PATH reminder ──────────────────────────────────────────────────────────────
if ! command -v sac &>/dev/null; then
  printf '\n⚠️   %s is not in your PATH.\n' "$BIN_DIR"
  printf '    Add the following line to your ~/.bashrc or ~/.zshrc:\n\n'
  printf '      export PATH="%s:$PATH"\n\n' "$BIN_DIR"
fi

# ── Alias suggestions ──────────────────────────────────────────────────────────
cat <<'EOF'

─────────────────────────────────────────────────
 Suggested aliases for ~/.bashrc or ~/.zshrc
─────────────────────────────────────────────────
  alias aic='sac'                         # default style
  alias aic-funny='sac --funny'           # funny style
  alias aic-detail='sac --detailed'       # detailed style
─────────────────────────────────────────────────

Run 'sac --help' to get started.
EOF
