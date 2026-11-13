#!/usr/bin/env bash
# Offline test: fake yt-dlp, ffprobe, ffmpeg and curl on PATH, then run the real ig2txt.
# Checks the Gemini request and the note for a single video and for a 2-item carousel.
# Run: bash tests/test.sh

set -u
here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

mkdir -p "$work/bin"

cat > "$work/bin/yt-dlp" <<'EOF'
#!/usr/bin/env bash
# Writes FAKE_ITEMS mp4 files where the -o template points, named like the real download.
while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done
dir=$(dirname "$out")
mkdir -p "$dir"
if [ "$FAKE_ITEMS" -eq 1 ]; then
  echo video > "$dir/NA_VIDEOID.mp4"
else
  for i in $(seq 1 "$FAKE_ITEMS"); do echo video > "$dir/$(printf %03d "$i")_POSTID.mp4"; done
fi
EOF

cat > "$work/bin/ffprobe" <<'EOF'
#!/usr/bin/env bash
echo 12.5
EOF

cp "$work/bin/ffprobe" "$work/bin/ffmpeg"

cat > "$work/bin/curl" <<'EOF'
#!/usr/bin/env bash
# Answers each Gemini call ig2txt makes; saves the generateContent body to $FAKE_LOG/request.json.
args="$*"
out=""
prev=""
for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done
case "$args" in
  *"X-Goog-Upload-Command: start"*)
    printf 'x-goog-upload-url: https://upload.test/session\r\n' ;;
  *upload.test*)
    n=$(( $(cat "$FAKE_LOG/n" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$FAKE_LOG/n"
    echo "{\"file\":{\"uri\":\"https://files.test/f$n\",\"name\":\"files/f$n\"}}" ;;
  *DELETE*) echo "$args" >> "$FAKE_LOG/deleted" ;;
  *generateContent*)
    cat > "$FAKE_LOG/request.json"
    jq -n '{modelVersion: "fake-model",
      candidates: [{content: {parts: [{text: "slug: Test Notes\ntitle: Test Notes\n\n## Takeaways\n- one point"}]}}],
      usageMetadata: {promptTokenCount: 100, candidatesTokenCount: 10}}' > "$out" ;;
  *files/*) echo '{"state":"ACTIVE"}' ;;
  *) echo "unexpected curl call: $args" >&2; exit 1 ;;
esac
EOF

chmod +x "$work/bin/"*

check() { # <description> <command...>
  if "${@:2}"; then echo "ok   $1"; else echo "FAIL $1"; fails=$(( fails + 1 )); fi
}

run() { # <items> <url>
  rm -rf "$work/log" "$work/out"; mkdir -p "$work/log" "$work/out"
  FAKE_ITEMS="$1" FAKE_LOG="$work/log" IG2TXT_OUT="$work/out" GEMINI_API_KEY=test-key \
    PATH="$work/bin:$PATH" bash "$here/ig2txt" "$2" > "$work/log/stdout" 2>&1
}

# Single video
run 1 "https://www.instagram.com/reel/VIDEOID/"
req="$work/log/request.json"
note="$work/out/test-notes-VIDEOID.md"
check "single: note named <slug>-<video-id>.md" test -f "$note"
check "single: one video part" test "$(jq '[.contents[0].parts[] | select(.file_data)] | length' "$req")" = 1
check "single: no Item label" test "$(jq '[.contents[0].parts[] | select(.text == "Item 1")] | length' "$req")" = 0
check "single: short clip sampled at 2 fps" test "$(jq '.contents[0].parts[0].video_metadata.fps' "$req")" = 2
check "single: no items line" bash -c "! grep -q '^items:' '$note'"
check "single: mode video + model" grep -q '^model: fake-model' "$note"
check "single: upload deleted" grep -q 'files/f1' "$work/log/deleted"

# Video carousel with 2 items
run 2 "https://www.instagram.com/p/POSTID/"
note="$work/out/test-notes-POSTID.md"
check "carousel: note named after the post id" test -f "$note"
check "carousel: two video parts, in order" test "$(jq -c '[.contents[0].parts[] | .file_data.file_uri // empty]' "$req")" = '["https://files.test/f1","https://files.test/f2"]'
check "carousel: each item labelled" test "$(jq -c '[.contents[0].parts[] | .text // empty | select(startswith("Item"))]' "$req")" = '["Item 1","Item 2"]'
check "carousel: carousel prompt sent" grep -q 'This post is a carousel' "$req"
check "carousel: items: 2 in frontmatter" grep -q '^items: 2$' "$note"
check "carousel: both uploads deleted" test "$(grep -c 'files/f' "$work/log/deleted")" = 2

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; cat "$work/log/stdout"; exit 1; }
