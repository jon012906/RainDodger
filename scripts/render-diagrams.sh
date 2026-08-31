#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT/docs/diagrams"
OUT_DIR="$SRC_DIR/out"
LOG="$ROOT/build-diagrams.log"
PUPPET="$SRC_DIR/puppeteer-config.json"

usage() {
  echo "Render Mermaid diagrams to SVG/PNG. Usage:"
  echo "  scripts/render-diagrams.sh [file.mmd ...]     render docs/diagrams/*.mmd -> out/"
  echo "  scripts/render-diagrams.sh --embed file.mmd   render + print fenced block to paste into docs/design.md"
  echo "  defaults to all docs/diagrams/*.mmd"
}

EMBED=0

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --embed) EMBED=1; shift ;;
esac

if [ $# -eq 0 ]; then
  FILE_LIST=$(ls "$SRC_DIR"/*.mmd 2>/dev/null) || { usage; exit 1; }
else
  FILE_LIST="$*"
fi

mkdir -p "$OUT_DIR"

ECHO_PUPPET=""
[ -f "$PUPPET" ] && ECHO_PUPPET="-p $PUPPET"

for f in $FILE_LIST; do
  name=$(basename "$f" .mmd)
  echo "Rendering $name -> SVG"
  npx -y @mermaid-js/mermaid-cli -i "$f" -o "$OUT_DIR/$name.svg" $ECHO_PUPPET >"$LOG" 2>&1 || {
    echo "FAILED ($name.svg, see $LOG):"; tail -20 "$LOG"; exit 1;
  }
  echo "Rendering $name -> PNG"
  npx -y @mermaid-js/mermaid-cli -i "$f" -o "$OUT_DIR/$name.png" $ECHO_PUPPET >>"$LOG" 2>&1 || {
    echo "FAILED ($name.png, see $LOG):"; tail -20 "$LOG"; exit 1;
  }
done

if [ "$EMBED" -eq 1 ]; then
  for f in $FILE_LIST; do
    name=$(basename "$f" .mmd)
    echo
    echo "// Paste into docs/design.md:"
    echo "\`\`\`mermaid"
    cat "$f"
    echo "\`\`\`"
  done
fi

echo "Done: $OUT_DIR"
