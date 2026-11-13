# ig2txt

<!-- Intro copy comes from /HQ/Content. Everything below is reference. -->

`ig2txt <video-url>` turns an Instagram, TikTok, YouTube, LinkedIn or X video into a markdown note. Gemini watches the video, so the note has what is said and also what is shown: captions, slides, code, UI demos, diagrams.

```
URL ──→ yt-dlp (≤720p, browser cookies if login is needed)
     ──→ Gemini Files API ──→ Gemini watches every item ──→ <slug>-<video-id>.md
                              (fallback: Whisper, speech only)
```

## Install

You need `bash`, `curl`, `jq`, `ffmpeg` and `yt-dlp`.

```sh
brew install jq ffmpeg yt-dlp          # Linux: your package manager, and pip install yt-dlp
git clone https://github.com/4arkin/ig2txt.git
ln -s "$PWD/ig2txt/ig2txt" /opt/homebrew/bin/ig2txt   # or /usr/local/bin, any folder always on PATH
```

Get a Gemini API key at https://aistudio.google.com/apikey. On macOS, keep it in the Keychain, where agent shells can read it:

```sh
security add-generic-password -a "$USER" -s ig2txt-gemini-api-key -w
```

Elsewhere, export `GEMINI_API_KEY`.

## Use

```sh
ig2txt "https://www.instagram.com/reel/<id>/"
ig2txt --audio-only "<url>"    # speech only, through OpenAI Whisper
```

To let an AI agent use it, read [AGENTS.md](AGENTS.md).

## The note

```markdown
---
source: <url>
video_id: <id>
date: <UTC time>
title: "<title>"
items: <N>          # carousels only
mode: video         # or audio
model: <Gemini model>
---

# <title>

## Takeaways
## Timeline         # [mm:ss] SAID / ON SCREEN / SHOWN; ### Item N per carousel item
## Shown, not said
```

## Settings

| Variable | Default | Does |
|---|---|---|
| `GEMINI_API_KEY` | Keychain `ig2txt-gemini-api-key` | Video mode. With no key, ig2txt uses audio-only mode. |
| `OPENAI_API_KEY` | none | Audio-only mode, and the fallback when video mode fails. |
| `IG2TXT_OUT` | current folder | Where notes go. |
| `IG2TXT_BROWSER` | `chrome` | Browser for login cookies (`brave`, `firefox`, `edge`, `safari`). Empty turns the cookie retry off. |
| `IG2TXT_GEMINI_MODEL` | `gemini-flash-latest` | Gemini model. |

## Cost

An 80-second reel is about 45K input tokens on Gemini Flash, roughly $0.05. Audio-only mode is about $0.006 per minute.

## Test

```sh
bash tests/test.sh
```

The test runs offline. It replaces yt-dlp, ffmpeg and the Gemini API with stubs, and checks the request and the note for a single video and for a carousel.

See [GOTCHAS.md](GOTCHAS.md) for carousels, cookies and limits.
