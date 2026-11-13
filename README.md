<h1 align="center">ig2txt</h1>

<p align="center">
  <strong>Turn a video link into a note your AI agent can read: what is said, and what is only shown.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/works%20with-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Gemini%20CLI-1B512D?style=flat-square" alt="Works with Claude Code, Codex and Gemini CLI">
  <img src="https://img.shields.io/badge/sources-Instagram%20%C2%B7%20TikTok%20%C2%B7%20YouTube%20%C2%B7%20LinkedIn%20%C2%B7%20X-1B512D?style=flat-square" alt="Instagram, TikTok, YouTube, LinkedIn and X">
  <img src="https://img.shields.io/badge/80s%20reel-about%20%240.05-1B512D?style=flat-square" alt="An 80-second reel costs about $0.05">
  <img src="https://img.shields.io/badge/one%20bash%20script-1B512D?style=flat-square" alt="One bash script">
  <img src="https://img.shields.io/badge/license-MIT-1B512D?style=flat-square" alt="MIT license">
</p>

<p align="center">
  <img src="assets/hero.png" width="880" alt="An invented example reel, 38 seconds. On screen: the caption 'Disk full? 1 command' and a terminal with the command du -sh ~/* | sort -h | tail -5, which lists five folders by size, with Downloads last at 48G. The speech only says: Open the terminal and paste this. ig2txt turns the reel link into a note. Its Timeline has each SAID, ON SCREEN and SHOWN entry with a timestamp. Its 'Shown, not said' section has the command and the 48G Downloads folder. The command is never said. The note has it.">
</p>

Give your agent a reel, a TikTok, a YouTube video or an Instagram carousel. Your agent runs `ig2txt "<url>"` and reads the note. The note has the speech, and also the captions, slides, code, UI demos and diagrams that the video only shows.

A transcript tool hears the speech only. In a reel that says *"paste this"* and shows the command on screen, the transcript has no command. An image carousel has no speech, so a transcript is empty. ig2txt sends every item to Gemini, which watches the video and reads each slide.

> **AI agents:** read [`AGENTS.md`](AGENTS.md). It is the complete protocol.

---

## Before and after

<p align="center">
  <img src="assets/before-after.png" width="880" alt="Before: a speech-to-text transcript. Speech: Open the terminal and paste this. Screen: gone, the command was never said, so the transcript does not have it. Carousels: image slides have no speech, so the transcript is empty. After: ig2txt. Speech: verbatim, with a timestamp for each entry. Screen: every caption, slide and line of code, verbatim, and demos and diagrams as text. Carousels: every item, in post order, with slide text verbatim under ### Item N.">
</p>

## How it works

<p align="center">
  <img src="assets/how-it-works.png" width="880" alt="Four steps. 1, you or your agent give ig2txt a link. 2, ig2txt downloads it: Instagram through gallery-dl, videos and images, other sites through yt-dlp up to 720p, with browser cookies if the site needs a login. 3, Gemini watches every item in one request, in post order, at high resolution. 4, ig2txt writes one markdown file in your notes folder and deletes the downloads and the Gemini uploads. Fallback: with no Gemini key, or when video mode fails, ig2txt transcribes the speech with Whisper and marks the note mode: audio.">
</p>

```
Instagram URL ──→ gallery-dl (videos + images) ─┐
other URL ──────→ yt-dlp (≤720p) ───────────────┤  browser cookies if login is needed
                                                ↓
              Gemini Files API ──→ Gemini reads every item, in order ──→ <slug>-<post-id>.md
                                   (fallback: Whisper, speech only)
```

Why gallery-dl for Instagram: yt-dlp cannot download Instagram images. On an image post, the cookie retry then reports "login required", and the real cause is the images. See [GOTCHAS.md](GOTCHAS.md).

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

| Section | What |
|---|---|
| Takeaways | The concrete, reusable points of the video |
| Timeline | Each entry has a `[mm:ss]` timestamp and a label. SAID is the speech, verbatim. ON SCREEN is the text on screen, verbatim. SHOWN is what the video demonstrates: diagrams as structure, interfaces and what changes in them, the tools on screen |
| Shown, not said | The information that is only on screen and not in the speech |

The prompt tells Gemini to write `[illegible]` for text it cannot read, and never to invent speech.

## Who it is for

| You | You do today | ig2txt adds |
|---|---|---|
| Use an AI agent every day | Your agent cannot open a video link | One command that your agent runs from any folder |
| Save reels and carousels to learn from them | You save the post and do not watch it again | A markdown note you can search, quote and reuse |
| Keep notes in a folder or a knowledge base | You retype the slides and the commands by hand | Every slide and every line of code, verbatim |

It does not keep the video. The downloads and the Gemini uploads are deleted after each run.

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

### Let your agent use it

Paste this into `CLAUDE.md`, `AGENTS.md` or `GEMINI.md` in your home or project folder:

```markdown
## Video URLs
Any Instagram post, reel or carousel (videos, images or both), and any TikTok / YouTube / LinkedIn / X video URL → `ig2txt "<url>"` via the shell, from any folder. Never a scraper or the browser.
```

Then send a link to your agent. The full protocol is in [AGENTS.md](AGENTS.md).

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

## FAQ

**Why not a transcript tool?**
A transcript has the speech only. The command in a coding reel, the text on a slide and the numbers in a demo are often on screen and not in the speech. Those go to the "Shown, not said" section.

**Does it work on image carousels?**
Yes. ig2txt downloads every Instagram post with gallery-dl, so image slides, video items and mixed carousels all work. Each item gets a `### Item N` block, and the slide text is verbatim.

**Why does macOS ask for a password?**
Instagram needs a login, so ig2txt reads your browser's cookies. macOS asks for access to "Chrome Safe Storage". Click **Allow**, not **Always Allow**. ig2txt then keeps only that site's cookies in the Keychain, so the prompt comes once per site. On Linux there is no cookie cache.

**What if Gemini fails?**
ig2txt falls back to Whisper, which transcribes the speech only. The note then has `mode: audio` and has no on-screen content. Audio-only mode needs `OPENAI_API_KEY`.

**What about long YouTube videos?**
Over 20 minutes, ig2txt sends the YouTube link instead of a download, at standard resolution, so the video fits the context window.

**Can it read a full profile?**
No. Collect the reel URLs from the profile's `/reels/` page in a browser, then run them one at a time, with about 20 seconds between runs.

## Test

```sh
bash tests/test.sh
```

The test runs offline. It replaces yt-dlp, gallery-dl, ffmpeg and the Gemini API with stubs, and checks the request and the note for a single video, a reel, and video, mixed and image-only carousels.

## Inside

| Path | What |
|---|---|
| `ig2txt` | The script |
| [`AGENTS.md`](AGENTS.md) | The protocol your agent follows, and the snippet for your agent's instructions |
| [`GOTCHAS.md`](GOTCHAS.md) | Carousels, cookies, Gemini, Whisper and agent shells: known traps, and the fix for each |
| `tests/` | `bash tests/test.sh`, offline |

## License

MIT. See [`LICENSE`](LICENSE).
