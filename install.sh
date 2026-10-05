#!/bin/bash
# replay-audio — install for the current user (no root needed).
#   ./install.sh            replay buffer + F10 / Shift+F10 + "Transcribe" in Dolphin's right-click menu
#   ./install.sh --models   also download the Whisper model (~1.6 GB) and the voice detector (~1 MB)
set -euo pipefail
cd "$(dirname "$0")"
BIN="$HOME/.local/bin"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
MENUS="${XDG_DATA_HOME:-$HOME/.local/share}/kio/servicemenus"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
MODELS="${XDG_DATA_HOME:-$HOME/.local/share}/replay-audio/models"

missing=()
for c in ffmpeg ffprobe notify-send systemctl; do command -v "$c" >/dev/null || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing: ${missing[*]}"
    echo "Arch / CachyOS: sudo pacman -S --needed ffmpeg libnotify pipewire-pulse"
    exit 1
fi

echo "→ commands in $BIN"
install -Dm755 bin/replay-audio "$BIN/replay-audio"
install -Dm755 bin/transcribe "$BIN/transcribe"

echo "→ service replay-audio.service"
install -Dm644 systemd/replay-audio.service "$UNITS/replay-audio.service"
systemctl --user daemon-reload
systemctl --user enable --now replay-audio.service

echo "→ shortcuts F10 (whole buffer) and Shift+F10 (last 10 min)"
for f in applications/*.desktop; do
    sed "s|^Exec=replay-audio|Exec=$BIN/replay-audio|" "$f" > "$APPS/$(basename "$f")"
done
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kglobalshortcutsrc --group services --group replay-audio-save.desktop --key _launch F10
    kwriteconfig6 --file kglobalshortcutsrc --group services --group replay-audio-save-10.desktop --key _launch Shift+F10
    kbuildsycoca6 >/dev/null 2>&1 || true
    systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
else
    echo "  (not on KDE: bind F10 to '$BIN/replay-audio save' in your desktop's shortcut settings)"
fi

echo "→ \"Transcribe\" in Dolphin's right-click menu"
mkdir -p "$MENUS"
sed "s|^Exec=transcribe|Exec=$BIN/transcribe|" servicemenus/transcribe.desktop > "$MENUS/transcribe.desktop"
chmod +x "$MENUS/transcribe.desktop"

if [ "${1:-}" = "--models" ]; then
    mkdir -p "$MODELS"
    echo "→ Whisper large-v3-turbo + Silero voice detector in $MODELS"
    curl -L --fail -C - -o "$MODELS/ggml-large-v3-turbo.bin" \
        https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
    curl -L --fail -C - -o "$MODELS/ggml-silero-v6.2.0.bin" \
        https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin
fi

command -v whisper-cli >/dev/null || [ -x "$HOME/Applications/whisper.cpp/build/bin/whisper-cli" ] \
    || echo "Note: transcription needs whisper.cpp (sudo pacman -S whisper-cpp, or a GPU build: see README)."
echo "Done. Press F10 to save the last 2 hours of audio to $(xdg-user-dir MUSIC 2>/dev/null || echo ~/Music)/Replays."
