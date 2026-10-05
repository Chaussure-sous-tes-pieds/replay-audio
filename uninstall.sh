#!/bin/bash
# replay-audio — remove everything ./install.sh added (your saved replays and transcripts are kept).
systemctl --user disable --now replay-audio.service 2>/dev/null
rm -f "$HOME/.local/bin/replay-audio" "$HOME/.local/bin/transcribe" \
      "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/replay-audio.service" \
      "${XDG_DATA_HOME:-$HOME/.local/share}/applications/replay-audio-save.desktop" \
      "${XDG_DATA_HOME:-$HOME/.local/share}/applications/replay-audio-save-10.desktop" \
      "${XDG_DATA_HOME:-$HOME/.local/share}/kio/servicemenus/transcribe.desktop"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/replay-audio"
systemctl --user daemon-reload
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kglobalshortcutsrc --group services --group replay-audio-save.desktop --key _launch --delete
    kwriteconfig6 --file kglobalshortcutsrc --group services --group replay-audio-save-10.desktop --key _launch --delete
    kbuildsycoca6 >/dev/null 2>&1; systemctl --user restart plasma-kglobalaccel.service 2>/dev/null
fi
echo "Removed. Models (if downloaded) are in ~/.local/share/replay-audio/models — delete them by hand."
