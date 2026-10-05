# replay-audio

**Nvidia-style instant replay, but audio only, for Linux.** It quietly keeps the last 2 hours of your
desktop sound *and* your microphone (calls, lectures, meetings, that thing someone just said) and saves it
as an MP3 when you press **F10**. Then right-click the MP3 in Dolphin → **Transcribe** to get the text,
locally, with Whisper on your GPU.

No video, no clips, no account, nothing leaves your machine.

| | |
|---|---|
| **F10** | save the whole buffer (up to 2 h) as `~/Music/Replays/Replay_<date>.mp3` |
| **Shift+F10** | save only the last 10 minutes |
| **Right-click → Transcribe** | `lecture.mp3` → `lecture.txt` + `lecture.srt` (timestamps) |

## Why

I wanted the "save the last N minutes" button from Nvidia/Medal-style clippers, just for audio: to keep a
lecture or a call *after* realizing it was worth keeping, and turn it into text I can paste into an AI to
summarize. Video recorders do this with a GPU encoder running all the time; for audio, ffmpeg is enough.

## How it works

- A user service runs **one ffmpeg** that records the default output's monitor (everything you hear,
  calls included) mixed with the default microphone, as 128 kbps MP3 chunks of 1 minute in a ring buffer
  in `~/.cache/replay-audio` (~60 MB per hour, ~1-2 % of one CPU core).
- **F10** concatenates the chunks without re-encoding: saving 2 hours takes about a second, and the minute
  being recorded is included.
- **Transcribe** runs [whisper.cpp](https://github.com/ggml-org/whisper.cpp) with `large-v3-turbo` and the
  Silero voice detector, which skips silence and music so Whisper invents far fewer phrases. On an
  RX 6750 XT (Vulkan), 28 minutes take 36 seconds.

## Install

Needs PipeWire (with `pipewire-pulse`) and ffmpeg. Made for KDE Plasma 6 (shortcuts and Dolphin menu);
the replay itself works on any desktop.

```sh
git clone https://github.com/Chaussure-sous-tes-pieds/replay-audio && cd replay-audio
./install.sh --models      # --models downloads Whisper large-v3-turbo (~1.6 GB) + the voice detector
```

For transcription you also need `whisper-cli`:

- easiest: `sudo pacman -S whisper-cpp` (Arch / CachyOS). Note that this package runs on the **CPU**:
  it works, but a 2-hour lecture takes a while.
- fast: build whisper.cpp with GPU support into `~/Applications/whisper.cpp`
  (`cmake -B build -DGGML_VULKAN=1 && cmake --build build -j --config Release`; use `-DGGML_CUDA=1` on
  Nvidia). A build there is used before the system package.

Uninstall: `./uninstall.sh` (your saved MP3s and transcripts are kept).

## Settings

Optional, in `~/.config/replay-audio.conf` (shell syntax):

```sh
BUFFER_MIN=120          # minutes kept in the buffer
MIC_GAIN=1.0            # your voice in the mix (2.0 if your mic is quiet)
BITRATE=128k
OUT_DIR=~/Music/Replays
WHISPER_LANG=auto       # or fr, en, de… (faster and more reliable than auto-detect)
WHISPER_DIR=~/Applications/whisper.cpp
# WHISPER_CLI / WHISPER_MODEL / WHISPER_VAD to point at specific files
```

Restart the buffer after a change: `systemctl --user restart replay-audio`.

## Good to know

- It records **everything** you hear and say while it runs. Mind the people you record and your local
  laws, and stop it when you don't want it: `systemctl --user disable --now replay-audio`.
- Whisper doesn't tell speakers apart, and struggles when several people talk at once.
- `transcribe` also works from a terminal, on any audio or video file: `transcribe *.mp3`.

MIT license. Built with [Claude Code](https://claude.com/claude-code).
