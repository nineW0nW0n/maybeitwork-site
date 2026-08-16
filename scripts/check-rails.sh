#!/bin/sh
# Enforces the hard rails in .claude/CLAUDE.md that biome can't see
# (it doesn't parse HTML). Heuristic grep checks, not a full parser —
# false negatives are possible; this catches obvious slips, not everything.
set -eu

FILE="index.html"
FAIL=0

if [ ! -f "$FILE" ]; then
  echo "no $FILE yet — nothing to check"
  exit 0
fi

fail() {
  echo "FAIL: $1"
  FAIL=1
}

# Rail 1/2: no external stylesheet/script files, no CDN requests.
if grep -Eq '<link[^>]+rel="stylesheet"[^>]+href="https?://' "$FILE"; then
  fail "external stylesheet <link> found (rail 1/2 — inline into <style>)"
fi
if grep -Eq '<script[^>]+src="https?://' "$FILE"; then
  fail "external <script src> found (rail 1/2 — inline into <script>)"
fi
if grep -Eiq 'fonts\.(googleapis|gstatic)\.com' "$FILE"; then
  fail "Google Fonts reference found (rail 2 — self-host/inline the font)"
fi
if grep -Eiq '@import[^;]+url\(["'"'"']?https?://' "$FILE"; then
  fail "external @import url() found (rail 2)"
fi

# Rail 3: no video/gif/lottie standing in for motion.
if grep -Eiq '<video' "$FILE"; then
  fail "<video> tag found (rail 3 — motion must be DOM+CSS or the approved canvas exception)"
fi
if grep -Eiq '\.(gif|json)["'"'"'].*lottie|lottie' "$FILE"; then
  fail "Lottie reference found (rail 3)"
fi

# Rail 4: keyframes must not animate layout-triggering properties.
# Extract each @keyframes block and scan its body for the banned properties.
awk '/@keyframes/{depth=0; flag=1} flag{print; n=gsub(/\{/,"{"); depth+=n; n=gsub(/\}/,"}"); depth-=n; if(depth<=0)flag=0}' "$FILE" \
  | grep -Ei '(width|height|top|left|margin[a-z-]*)\s*:' \
  && fail "keyframes animate a layout property (width/height/top/left/margin) — rail 4, transform/opacity only" \
  || true

# Security: no markup-writing sinks. The metric readout used to assemble an
# HTML string and inject it -- safe only because nothing untrusted reached
# the template, which nothing enforced. It builds real <span>s now. Keep it
# that way: there is no reason this page ever needs to write markup.
if grep -vE 'base64' "$FILE" | grep -Eq 'innerHTML|outerHTML|insertAdjacentHTML|document\.write'; then
  fail "markup-writing sink found (innerHTML/outerHTML/insertAdjacentHTML/document.write) — use textContent and real elements"
fi

# Rail 7: reduced-motion must be honored somewhere in the file.
if ! grep -q 'prefers-reduced-motion' "$FILE"; then
  fail "no prefers-reduced-motion handling found (rail 7)"
fi

# Informational: line count vs the ~1500-line split threshold.
LINES=$(wc -l < "$FILE" | tr -d ' ')
if [ "$LINES" -gt 1500 ]; then
  echo "NOTE: $FILE is $LINES lines — CLAUDE.md says propose a split past ~1500"
fi

exit $FAIL
