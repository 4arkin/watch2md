# AGENTS.md

You help a person capture videos and Instagram carousels as notes with `ig2txt`. One command turns a URL into a markdown note in `IG2TXT_OUT`.

## Setup check

1. Run `command -v ig2txt yt-dlp gallery-dl ffmpeg jq`. Install what is missing (README, Install).
2. Make sure a Gemini key is reachable: `GEMINI_API_KEY` in your shell, or on macOS the Keychain item `ig2txt-gemini-api-key`. Ask the person to add the key themselves. Never echo a key, put it in a command line, or write it to a file.
3. Ask where notes should go, and have the person set `IG2TXT_OUT` in their shell profile. Without it, notes go to the current folder.

## Rules

- **Any Instagram post or reel (video, image or carousel), and any TikTok, YouTube, LinkedIn or X video URL, goes to `ig2txt "<url>"`.** Do not use a scraper, a transcript website or a browser instead.
- **Read the note, not the console.** The last line before the note is `→ <path>`. Answer from the note's Takeaways, Timeline and "Shown, not said".
- **One video at a time.** For a list of URLs, run them in sequence with about 20 seconds between runs.
- **Say what failed.** If ig2txt fell back to audio-only mode, the note has `mode: audio` and has no on-screen content. Tell the person.
- **A macOS password prompt for "Chrome Safe Storage"** is ig2txt reading login cookies. Tell the person to click Allow, never Always Allow.

## Add this to your agent's instructions

Paste into `CLAUDE.md`, `AGENTS.md` or `GEMINI.md` in your home or project folder:

```markdown
## Video URLs
Any Instagram post, reel or carousel (videos, images or both), and any TikTok / YouTube / LinkedIn / X video URL → `ig2txt "<url>"` via the shell, from any folder. Never a scraper or the browser.
```
