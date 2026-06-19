#!/data/data/com.termux/files/usr/bin/bash
#
# setup-ollama-termux.sh
# One-shot setup of a local Ollama AI server on an Android phone (Termux).
# Target hardware: Samsung Galaxy S24 (or any modern ARM64 Android).
#
# Run inside Termux (installed from F-Droid / GitHub, NOT the Play Store):
#   bash setup-ollama-termux.sh
#
# What it does:
#   - updates Termux packages
#   - installs Ollama
#   - holds a wake-lock so the phone keeps serving while idle
#   - configures Ollama to listen on the whole network (0.0.0.0:11434)
#   - starts the server and pulls a small, S24-appropriate model
#   - prints the URL other devices should use
#
# Safe to re-run: it skips steps that are already done.

set -euo pipefail

# ---- config (override with env vars) ----------------------------------------
MODEL="${MODEL:-llama3.2:3b}"     # set MODEL=gemma2:2b etc. to change
PORT="${PORT:-11434}"
# -----------------------------------------------------------------------------

log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# Sanity: are we actually in Termux?
if [ -z "${PREFIX:-}" ] || [ ! -d "/data/data/com.termux" ]; then
  die "This must be run inside Termux on Android."
fi

log "Updating Termux packages (this can take a few minutes)..."
pkg update -y && pkg upgrade -y

log "Installing prerequisites..."
pkg install -y curl termux-api ollama || {
  warn "Couldn't install 'ollama' from the Termux repo directly."
  warn "Trying again after refreshing repos..."
  pkg update -y
  pkg install -y ollama || die "Ollama install failed. See docs/s24-ai-server.md for the manual fallback."
}

log "Holding a wake-lock so the phone keeps serving while idle..."
termux-wake-lock || warn "Could not acquire wake-lock (install Termux:API app for best results)."

# Configure Ollama to listen on all interfaces so other devices can reach it.
SHELL_RC="$HOME/.bashrc"
if ! grep -q "OLLAMA_HOST" "$SHELL_RC" 2>/dev/null; then
  log "Configuring Ollama to listen on the network (0.0.0.0:${PORT})..."
  {
    echo ""
    echo "# Ollama: serve to the whole LAN"
    echo "export OLLAMA_HOST=0.0.0.0:${PORT}"
  } >> "$SHELL_RC"
fi
export OLLAMA_HOST="0.0.0.0:${PORT}"

# Start the server in the background if it isn't already running.
if ! curl -fsS "http://127.0.0.1:${PORT}/api/version" >/dev/null 2>&1; then
  log "Starting the Ollama server..."
  nohup ollama serve > "$HOME/ollama.log" 2>&1 &
  # wait for it to come up
  for i in $(seq 1 30); do
    if curl -fsS "http://127.0.0.1:${PORT}/api/version" >/dev/null 2>&1; then break; fi
    sleep 1
  done
  curl -fsS "http://127.0.0.1:${PORT}/api/version" >/dev/null 2>&1 \
    || die "Ollama server did not start. Check $HOME/ollama.log"
else
  log "Ollama server already running."
fi

log "Pulling model: ${MODEL} (downloads a couple of GB the first time)..."
ollama pull "${MODEL}"

# Best-effort: set up auto-start on boot.
log "Setting up auto-start on reboot (optional)..."
pkg install -y termux-services 2>/dev/null || warn "Could not install termux-services."
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"
cat > "$BOOT_DIR/start-ollama.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
export OLLAMA_HOST=0.0.0.0:${PORT}
ollama serve
EOF
chmod +x "$BOOT_DIR/start-ollama.sh"
warn "Install the 'Termux:Boot' app from F-Droid for auto-start to take effect."

# Figure out the LAN IP to show the user.
IP="$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1 || true)"
[ -z "$IP" ] && IP="<phone-ip>"

cat <<EOF

============================================================
  ✅  Local AI server is up.
============================================================
  Model:        ${MODEL}
  Server URL:   http://${IP}:${PORT}

  Test it from this phone:
      ollama run ${MODEL}

  Use it from another device (same WiFi):
      OLLAMA_HOST=http://${IP}:${PORT} ollama run ${MODEL}

  Or point any Ollama client / Open WebUI at:
      http://${IP}:${PORT}

  Notes:
   - Keep Termux exempt from battery optimization
     (Android Settings > Apps > Termux > Battery > Unrestricted).
   - Don't expose port ${PORT} to the public internet unprotected.
   - To change models: ollama pull gemma2:2b   (then run it)
============================================================
EOF
