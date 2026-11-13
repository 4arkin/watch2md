# Gotchas

## Carousels

- **Video carousels go to Gemini as one request.** Each item is labelled `Item N`, in post order. The Timeline splits into `### Item N` blocks, and timestamps restart at `[00:00]` for each item. The frontmatter gets `items: N`. The note is named after the post id.
- **Image-only carousels do not work.** yt-dlp finds no video in an image post, so ig2txt stops. The last error often says "login required". That message is wrong for this case: check whether the post has only images before you debug cookies. Read the slides in a browser, or give screenshots to a model that reads images.
- **Audio-only mode on a carousel** transcribes each item under `## Item N`. Items with no sound track, or with music only, show as `(no sound track)` or `(no speech)`. When no item has speech, ig2txt writes no file and says so.

## Instagram and cookies

- **Instagram reels need a login.** The public fetch fails for almost every reel. ig2txt then reads your browser's cookies (`IG2TXT_BROWSER`, default `chrome`).
- **The macOS keychain prompt.** Reading Chrome cookies makes macOS ask for your password ("security wants to access Chrome Safe Storage"). Click **Allow**, not **Always Allow**: "Always Allow" opens every Chrome cookie and saved password to any later read.
- **One prompt per site, not per video.** After the first read, ig2txt keeps only that site's cookies in the Keychain, as `ig2txt-cookies-<site>` (for example `ig2txt-cookies-instagram.com`). When you log out or the session expires, delete it: `security delete-generic-password -s ig2txt-cookies-instagram.com`.
- **On Linux there is no cookie cache.** Each login-required fetch reads the browser again.
- **Run batches one video at a time, with about 20 seconds between them.** Fast bulk pulls on a logged-in account can hit an Instagram rate limit.
- **yt-dlp cannot list a profile's reels.** Collect the reel URLs from the profile's `/reels/` page in a browser.
- **Keep yt-dlp current** (`brew upgrade yt-dlp` or `pip install -U yt-dlp`). Instagram and TikTok changes break old versions.

## Gemini

- **Small on-screen text needs high resolution.** At the default resolution Gemini misread small digits (a date, a unit). ig2txt sends `MEDIA_RESOLUTION_HIGH` for videos up to 20 minutes, and 2 frames per second for clips up to 3 minutes. An 80-second reel costs about 45K input tokens, roughly $0.05.
- **Long YouTube videos go by URL.** Over 20 minutes, ig2txt passes the YouTube link instead of a download, at standard resolution, so the video fits the context window. The resolution setting has no effect on YouTube links, so shorter YouTube videos are downloaded and uploaded.
- **HTTP 402 "prepayment credits are depleted"** means the Gemini project needs credit. The key is fine.
- **`gemini-flash-latest` is an alias** and moves to new models. Pin a model with `IG2TXT_GEMINI_MODEL`.
- **Uploads are deleted after each run.** The Files API would otherwise keep them for 48 hours.

## Audio-only mode (Whisper)

- **Whisper invents text over music** ("Thanks for watching.", subtitle credits, "♪♪"). ig2txt drops segments with a high no-speech score, and segments with no letters.
- **The audio limit is 25 MB**, about 30 minutes. ig2txt does not split longer audio.

## Agents (Claude Code, Codex, Gemini CLI)

- **Agent shells do not read `~/.zshrc`.** A `PATH` entry or an exported `GEMINI_API_KEY` there is invisible to the agent. Put a symlink in a folder that is always on `PATH` (`/opt/homebrew/bin` or `/usr/local/bin`), and on macOS keep the key in the Keychain (see README).
- **Notes go to the current folder.** Set `IG2TXT_OUT` to one notes folder, so an agent in any project writes to the same place.
