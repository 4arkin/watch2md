#!/usr/bin/env bash
# Offline test: fake yt-dlp, gallery-dl, ffprobe, ffmpeg and curl on PATH, then run the real ig2txt.
# Checks the Gemini request and the note for a single video, an Instagram reel, and video,
# mixed and image-only carousels.
# Run: bash tests/test.sh

set -u
here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

mkdir -p "$work/bin"

cat > "$work/bin/yt-dlp" <<'EOF'
#!/usr/bin/env bash
# Writes one video where the -o template points, named like the real download.
while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done
dir=$(dirname "$out")
mkdir -p "$dir"
echo video > "$dir/NA_VIDEOID.mp4"
EOF

cat > "$work/bin/gallery-dl" <<'EOF'
#!/usr/bin/env bash
# Writes one file per extension in FAKE_FILES into the -D folder, named like the real download.
while [ $# -gt 0 ]; do [ "$1" = "-D" ] && dir="$2"; shift; done
mkdir -p "$dir"
i=0
for ext in $FAKE_FILES; do i=$(( i + 1 )); echo media > "$dir/$(printf %03d "$i")_POSTID.$ext"; done
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
    echo "$args" | grep -o 'Upload-Header-Content-Type: [a-z0-9./+-]*' >> "$FAKE_LOG/types"
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

run() { # <files for gallery-dl> <url>
  rm -rf "$work/log" "$work/out"; mkdir -p "$work/log" "$work/out"
  FAKE_FILES="$1" FAKE_LOG="$work/log" IG2TXT_OUT="$work/out" GEMINI_API_KEY=test-key \
    PATH="$work/bin:$PATH" bash "$here/ig2txt" "$2" > "$work/log/stdout" 2>&1
}

req="$work/log/request.json"
parts() { jq -c "[.contents[0].parts[] | $1]" "$req"; }

# Single video through yt-dlp
run "" "https://www.tiktok.com/@someone/video/VIDEOID"
note="$work/out/test-notes-VIDEOID.md"
check "single: note named <slug>-<video-id>.md" test -f "$note"
check "single: one video part at 2 fps" test "$(parts 'select(.file_data) | [.file_data.mime_type, .video_metadata.fps]')" = '[["video/mp4",2]]'
check "single: no Item label" test "$(parts 'select(.text == "Item 1")')" = '[]'
check "single: no image instructions" bash -c "! grep -q 'still images' '$req'"
check "single: no items line" bash -c "! grep -q '^items:' '$note'"
check "single: model in frontmatter" grep -q '^model: fake-model' "$note"
check "single: upload deleted" grep -q 'files/f1' "$work/log/deleted"

# Instagram reel through gallery-dl
run "mp4" "https://www.instagram.com/reel/POSTID/"
check "reel: note named after the shortcode" test -f "$work/out/test-notes-POSTID.md"
check "reel: one video part" test "$(parts 'select(.file_data) | .file_data.mime_type')" = '["video/mp4"]'

# Video carousel
run "mp4 mp4" "https://www.instagram.com/p/POSTID/"
note="$work/out/test-notes-POSTID.md"
check "video carousel: two video parts, in order" test "$(parts '.file_data.file_uri // empty')" = '["https://files.test/f1","https://files.test/f2"]'
check "video carousel: each item labelled" test "$(parts '.text // empty | select(startswith("Item"))')" = '["Item 1","Item 2"]'
check "video carousel: carousel prompt sent" grep -q 'This post is a carousel' "$req"
check "video carousel: items: 2 in frontmatter" grep -q '^items: 2$' "$note"
check "video carousel: both uploads deleted" test "$(grep -c 'files/f' "$work/log/deleted")" = 2

# Mixed carousel: video, image, video
run "mp4 jpg mp4" "https://www.instagram.com/p/POSTID/"
note="$work/out/test-notes-POSTID.md"
check "mixed: types in post order" test "$(parts 'select(.file_data) | .file_data.mime_type')" = '["video/mp4","image/jpeg","video/mp4"]'
check "mixed: fps on videos only" test "$(parts 'select(.file_data) | .video_metadata.fps')" = '[2,null,2]'
check "mixed: uploads sent with their type" test "$(sed 's/.*: //' "$work/log/types" | tr '\n' ' ')" = 'video/mp4 image/jpeg video/mp4 '
check "mixed: image instructions sent" grep -q 'still images' "$req"
check "mixed: items: 3 in frontmatter" grep -q '^items: 3$' "$note"

# Image-only carousel
run "jpg jpg jpg" "https://www.instagram.com/p/POSTID/"
note="$work/out/test-notes-POSTID.md"
check "images: three image parts" test "$(parts 'select(.file_data) | .file_data.mime_type')" = '["image/jpeg","image/jpeg","image/jpeg"]'
check "images: high resolution kept" test "$(jq -r '.generationConfig.mediaResolution' "$req")" = MEDIA_RESOLUTION_HIGH
check "images: no fps" test "$(parts 'select(.video_metadata)')" = '[]'
check "images: note written" grep -q '^items: 3$' "$note"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; cat "$work/log/stdout"; exit 1; }
