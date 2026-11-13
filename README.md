# ig2txt

<!-- Intro copy comes from /HQ/Content. Everything below is reference. -->

`ig2txt <url>` turns an Instagram, TikTok, YouTube, LinkedIn or X video into a markdown note. Instagram carousels work too: videos, image slides, or both. Gemini watches every item, so the note has what is said and also what is shown: captions, slides, code, UI demos, diagrams.

```
Instagram URL ──→ gallery-dl (videos + images) ─┐
other URL ──────→ yt-dlp (≤720p) ───────────────┤  browser cookies if login is needed
                                                ↓
              Gemini Files API ──→ Gemini reads every item, in order ──→ <slug>-<post-id>.md
                                   (fallback: Whisper, speech only)
```

## Install

You need `bash`, `curl`, `jq`, `ffmpeg`, `yt-dlp`, and `gallery-dl` for Instagram.

```sh
brew install jq ffmpeg yt-dlp gallery-dl   # Linux: your package manager, and pip install yt-dlp gallery-dl
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
ig2txt "https://www.instagram.com/p/<id>/"    # carousel: videos, images, or both
ig2txt --audio-only "<url>"                   # speech only, through OpenAI Whisper
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
## Timeline         # [mm:ss] SAID / ON SCREEN / SHOWN; ### Item N per carousel item, no timestamps on images
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

An 80-second reel is about 45K input tokens on Gemini Flash, roughly $0.05. An 8-slide image carousel is about 9K. Audio-only mode is about $0.006 per minute.

## Test

```sh
bash tests/test.sh
```

The test runs offline. It replaces yt-dlp, gallery-dl, ffmpeg and the Gemini API with stubs, and checks the request and the note for a single video, a reel, and video, mixed and image-only carousels.

See [GOTCHAS.md](GOTCHAS.md) for carousels, cookies and limits.
