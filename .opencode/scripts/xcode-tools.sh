#!/usr/bin/env bash
# xcode-tools.sh — Xcode + simulator helpers for Rain Dodger
# Commands: doctor | build | boot | install | launch | screenshot | run
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)" || exit 1
PROJECT="$REPO_ROOT/RainDodger.xcodeproj"
SCHEME="RainDodger"
CONFIG_FILE="$SCRIPT_DIR/simulator-config.json"
TMP_DIR="$REPO_ROOT/.opencode/tmp"
DERIVED_DATA="$TMP_DIR/DerivedData"
LOG_FILE="$TMP_DIR/xcodebuild.log"
SCREENSHOT_DIR="$TMP_DIR/screenshots"

SIM_UDID=""
SIM_NAME=""
SIM_OS=""
SIM_STATE=""
SIM_KEYED=""
CACHE_DIR=""

die() {
  echo "[fail] $*" >&2
  echo "EXIT 1"
  exit 1
}

usage() {
  cat <<'EOF'
xcode-tools.sh — Xcode + simulator helpers for Rain Dodger

Usage: xcode-tools.sh <command> [args]

Commands:
  doctor                 Check the Xcode toolchain, config, disk and report
                         the simulator that will be used
  build [Debug|Release]  Build the app for the simulator (default: Debug)
  boot                   Boot the simulator (no-op if already booted)
  install                Install the built app (Debug build preferred)
  launch                 Launch the app (exit 0 + pid); process visibility varies by sim
  screenshot [name]      Take a simulator screenshot (default name: screenshot)
  run [Debug|Release]    doctor + build + boot + install + launch + screenshot

Simulator selection:
  RD_SIM env var overrides the device name (e.g. RD_SIM="iPhone 17 Pro Max")
  Otherwise device/os from simulator-config.json is used
  Blank 'os' prefers the newest OS; no match falls back to a booted iPhone
EOF
}

validate_config() {
  case "$1" in
    [Dd]ebug)   echo "Debug" ;;
    [Rr]elease) echo "Release" ;;
    *)          return 1 ;;
  esac
}

detect_xcode() {
  # CommandLineTools may be selected while Xcode is installed elsewhere
  [[ -n "${DEVELOPER_DIR:-}" ]] && return 0
  local select_path
  if command -v xcodebuild >/dev/null 2>&1; then
    select_path="$(xcode-select -p 2>/dev/null || true)"
  else
    select_path="/usr/bin/xcodebuild (unresolvable)"
  fi
  [[ "$select_path" == /Applications/Xcode*.app/Contents/Developer ]] && return 0
  if [[ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    echo "notice: xcode-select points to '$select_path'; using DEVELOPER_DIR=$DEVELOPER_DIR" >&2
  fi
}

device_re='^(.+)[[:space:]]+\(([0-9A-Fa-f-]{8,})\)[[:space:]]+\(([^)]*)\)[[:space:]]*$'

parse_devices() {
  # simctl list output -> TSV: os|name|udid|state (iOS devices only)
  local line current_os name udid state
  while IFS= read -r line; do
    case "$line" in
      "-- Unavailable:"*) current_os="" ;;
      "-- iOS "*)
        current_os="${line#-- iOS }"
        current_os="${current_os% --}"
        ;;
      "-- "*)
        current_os="" ;;
      "    "*)
        [[ -n "$current_os" ]] || continue
        line="${line#    }"
        if [[ "$line" =~ $device_re ]]; then
          name="${BASH_REMATCH[1]}"
          udid="${BASH_REMATCH[2]}"
          state="${BASH_REMATCH[3]}"
          printf '%s|%s|%s|%s\n' "$current_os" "$name" "$udid" "$state"
        fi
        ;;
    esac
  done < "$1"
}

key_devices() {
  # TSV -> sortable rows: booted|osPadded|modelScore|os|name|udid|state
  awk -F'|' '
  function pad(v, n, p, i, out) {
    n = split(v, p, "."); out = ""
    for (i = 1; i <= n; i++) out = out sprintf("%04d", p[i])
    return out
  }
  function mscore(name, rest, num, r) {
    num = 0; r = 1
    if (name ~ /^iPhone/) {
      name = substr(name, 8)
      rest = name
      sub(/^[0-9]+/, "", rest)
      num = (name + 0)
      if (rest ~ /^e/) r = 0
      else if (rest ~ / Pro Max/) r = 4
      else if (rest ~ / Pro/) r = 3
      else if (rest ~ /Air/) { r = 2; if (num == 0) num = 17 }
      else if (num == 0) r = 0
    }
    if (num == 0) num = 1
    return num * 10 + r
  }
  { bt = ($4 == "Booted") ? 1 : 0
    print bt "|" pad($1) "|" mscore($2) "|" $1 "|" $2 "|" $3 "|" $4 }'
}

read_config() {
  [[ -f "$CONFIG_FILE" ]] || return 1
  local out device os
  out="$(python3 - "$CONFIG_FILE" 2>/dev/null <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
print(d.get("device") or "")
print(d.get("os") or "")
PYEOF
)" || return 1
  device="$(printf '%s\n' "$out" | sed -n '1p')"
  os="$(printf '%s\n' "$out" | sed -n '2p')"
  [[ -n "$device" ]] || return 1
  printf '%s|%s\n' "$device" "$os"
}

set_sim_globals() {
  local row rest
  row="$(awk -F'|' -v u="$1" '$6 == u {print $4 "|" $5 "|" $6 "|" $7; exit}' "$SIM_KEYED")"
  [[ -n "$row" ]] || return 1
  SIM_OS="${row%%|*}"; rest="${row#*|}"
  SIM_NAME="${rest%%|*}"; rest="${rest#*|}"
  SIM_UDID="${rest%%|*}"; SIM_STATE="${rest#*|}"
}

list_excerpt() {
  xcrun simctl list devices available 2>/dev/null | sed -n '1,25p' >&2
}

resolve_simulator() {
  local tsv="$CACHE_DIR/devices.tsv" udid name os cfg cfg_ok=1
  SIM_KEYED="$CACHE_DIR/devices.keyed"
  xcrun simctl list devices available >"$CACHE_DIR/devices.txt" 2>/dev/null || {
    echo "[fail] simulator: 'xcrun simctl list devices available' failed" >&2
    return 1
  }
  parse_devices "$CACHE_DIR/devices.txt" >"$tsv" || {
    echo "[fail] simulator: could not parse simctl output" >&2
    return 1
  }
  key_devices <"$tsv" >"$SIM_KEYED" || {
    echo "[fail] simulator: could not rank simulators" >&2
    return 1
  }
  sort -t'|' -k1,1nr -k2,2r -k3,3nr "$SIM_KEYED" -o "$SIM_KEYED" || {
    echo "[fail] simulator: could not sort simulators" >&2
    return 1
  }
  if [[ -n "${RD_SIM:-}" ]]; then
    udid="$(awk -F'|' -v n="$RD_SIM" '$5 == n {print $6; exit}' "$SIM_KEYED")"
    if [[ -z "$udid" ]]; then
      echo "[fail] simulator: RD_SIM='$RD_SIM' not found among available devices" >&2
      list_excerpt
      return 1
    fi
  else
    cfg="$(read_config 2>/dev/null)" || cfg_ok=0
    if [[ $cfg_ok -eq 1 ]]; then
      name="${cfg%%|*}"
      os="${cfg#*|}"
      local os1="$os" os2=""
      if [[ "$os" == iOS\ * ]]; then os1="${os#iOS }"; else os2="iOS $os"; fi
      if [[ -n "$os" ]]; then
        udid="$(awk -F'|' -v n="$name" -v o1="$os1" -v o2="$os2" \
          '$5 == n && ($4 == o1 || $4 == o2) {print $6; exit}' "$SIM_KEYED")"
      else
        udid="$(awk -F'|' -v n="$name" '$5 == n {print $6; exit}' "$SIM_KEYED")"
      fi
    fi
    if [[ -z "$udid" ]]; then
      echo "[warn] simulator: config (${name:-none} / '${os:-}') matched nothing — falling back to booted iPhone, newest OS, highest model" >&2
      udid="$(awk -F'|' '$5 ~ /^iPhone/ {print $6; exit}' "$SIM_KEYED")"
      if [[ -z "$udid" ]]; then
        echo "[fail] simulator: no iPhone simulator available" >&2
        list_excerpt
        return 1
      fi
    fi
  fi
  set_sim_globals "$udid" || {
    echo "[fail] simulator: internal parse error" >&2
    return 1
  }
  echo "[ok] simulator: $SIM_NAME ($SIM_OS, $SIM_STATE)"
}

cmd_doctor() {
  local ver
  ver="$(xcodebuild -version 2>&1)" || {
    echo "[fail] xcode: xcodebuild unreachable (DEVELOPER_DIR=${DEVELOPER_DIR:-not set})" >&2
    return 1
  }
  echo "[ok] xcode: $(printf '%s\n' "$ver" | sed -n '1p') (DEVELOPER_DIR=${DEVELOPER_DIR:-system})"
  xcrun simctl list devices available >/dev/null 2>&1 || {
    echo "[fail] simctl: 'xcrun simctl list devices available' failed" >&2
    return 1
  }
  echo "[ok] simctl: usable"
  local cfg cfg_ok=1 sim_free_kb free_gb
  cfg="$(read_config 2>/dev/null)" || cfg_ok=0
  if [[ $cfg_ok -eq 1 ]]; then
    echo "[ok] config: ${cfg%%|*} / ${cfg#*|}"
  elif [[ -f "$CONFIG_FILE" ]]; then
    echo "[warn] config: $CONFIG_FILE exists but could not be parsed — using fallback" >&2
  else
    echo "[warn] config: $CONFIG_FILE not found — using fallback" >&2
  fi
  sim_free_kb="$(df -k "$REPO_ROOT" 2>/dev/null | awk 'NR == 2 {print $4}')"
  if [[ -n "$sim_free_kb" ]]; then
    free_gb=$((sim_free_kb / 1024 / 1024))
    if [[ $free_gb -lt 2 ]]; then
      echo "[warn] disk: only ${free_gb} GB free on the volume holding $REPO_ROOT (build may fail)" >&2
    else
      echo "[ok] disk: ${free_gb} GB free (> 2 GB)"
    fi
  else
    echo "[warn] disk: could not read free space (df failed)" >&2
  fi
  resolve_simulator || return 1
  return 0
}

app_path() {
  ls -d "$DERIVED_DATA/Build/Products/$1-iphonesimulator"/*.app 2>/dev/null | head -1
}

bundle_id() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Info.plist" 2>/dev/null
}

last_built_app() {
  local app release
  app="$(app_path Debug)"
  [[ -n "$app" ]] && { echo "$app"; return 0; }
  release="$(app_path Release)"
  [[ -n "$release" ]] && { echo "$release"; return 0; }
  return 1
}

cmd_build() {
  local cfg="${1:-Debug}"
  cfg="$(validate_config "$cfg")" || {
    echo "[fail] build: invalid configuration '$cfg' (use Debug or Release)" >&2
    return 1
  }
  resolve_simulator || return 1
  mkdir -p "$TMP_DIR"
  echo "[build] project: $(basename "$PROJECT") scheme: $SCHEME config: $cfg"
  echo "[build] destination: $SIM_NAME ($SIM_OS) [$SIM_UDID]"
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$cfg" \
    -destination "platform=iOS Simulator,id=$SIM_UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO | tee "$LOG_FILE"
  local status=${PIPESTATUS[0]} app bundle
  if [[ $status -ne 0 ]]; then
    echo "[fail] build: xcodebuild exited with $status (log: $LOG_FILE; tail below)" >&2
    tail -40 "$LOG_FILE" >&2
    return 1
  fi
  app="$(app_path "$cfg")"
  [[ -n "$app" && -d "$app" ]] || {
    echo "[fail] build: .app not found under $(dirname "$DERIVED_DATA/Build/Products")" >&2
    return 1
  }
  bundle="$(bundle_id "$app")"
  echo "[ok] build: $app"
  echo "[ok] bundle id: ${bundle:-unknown}"
}

is_booted() {
  xcrun simctl list devices 2>/dev/null | grep -qF "($1) (Booted)"
}

run_with_timeout() {
  # secs command... — kills the command after secs; returns 124 on timeout
  local secs="$1"; shift
  "$@" &
  local pid=$!
  local waited=0
  while [[ $waited -lt "$secs" ]]; do
    sleep 2
    waited=$((waited + 2))
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid" 2>/dev/null
      return $?
    fi
  done
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  return 124
}

cmd_boot() {
  resolve_simulator || return 1
  if is_booted "$SIM_UDID"; then
    echo "[ok] boot: $SIM_NAME already booted"
    return 0
  fi
  xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || {
    echo "[fail] boot: 'simctl boot' failed for $SIM_NAME [$SIM_UDID]" >&2
    return 1
  }
  echo "[boot] waiting for $SIM_NAME to finish booting (up to 120s)..."
  run_with_timeout 120 xcrun simctl bootstatus "$SIM_UDID" -b || {
    echo "[fail] boot: 'simctl bootstatus' timed out or failed" >&2
    return 1
  }
  echo "[ok] boot: $SIM_NAME ready"
}

cmd_install() {
  resolve_simulator || return 1
  local app bundle
  app="$(last_built_app)" || {
    echo "[fail] install: no built .app found — run 'xcode-tools.sh build' first" >&2
    return 1
  }
  bundle="$(bundle_id "$app")"
  [[ -n "$bundle" ]] || {
    echo "[fail] install: cannot read bundle id from $app/Info.plist" >&2
    return 1
  }
  if xcrun simctl uninstall "$SIM_UDID" "$bundle" >/dev/null 2>&1; then
    echo "[install] removed previous install of $bundle"
  fi
  xcrun simctl install "$SIM_UDID" "$app" || {
    echo "[fail] install: 'simctl install' failed" >&2
    return 1
  }
  echo "[ok] install: $bundle"
}

cmd_launch() {
  resolve_simulator || return 1
  local app bundle out pid
  app="$(last_built_app)" || {
    echo "[fail] launch: no built .app found — run 'xcode-tools.sh build' first" >&2
    return 1
  }
  bundle="$(bundle_id "$app")"
  [[ -n "$bundle" ]] || {
    echo "[fail] launch: cannot read bundle id from $app/Info.plist" >&2
    return 1
  }
  out="$(xcrun simctl launch "$SIM_UDID" "$bundle" 2>&1)" || {
    echo "[fail] launch: $out" >&2
    return 1
  }
  pid="$(printf '%s\n' "$out" | awk '{print $NF}')"
  echo "[ok] launch: pid ${pid:-?}"
  sleep 3
  if xcrun simctl spawn "$SIM_UDID" launchctl list 2>/dev/null | grep -q "UIKitApplication:$bundle"; then
    echo "[ok] launch: alive (UIKitApplication:$bundle)"
  else
    echo "[warn] launch: no process-level visibility in this sim runtime (launch exited 0 + pid ${pid:-?}) — verify visually via screenshot" >&2
  fi
  return 0
}

cmd_screenshot() {
  local name="${1:-screenshot}"
  resolve_simulator || return 1
  mkdir -p "$SCREENSHOT_DIR"
  local ts path
  ts="$(date +%Y%m%d-%H%M%S)"
  path="$SCREENSHOT_DIR/$name-$ts.png"
  xcrun simctl io "$SIM_UDID" screenshot "$path" 2>&1 || {
    echo "[fail] screenshot: 'simctl io screenshot' failed" >&2
    return 1
  }
  echo "[ok] screenshot: $path"
}

cmd_run() {
  local cfg="${1:-Debug}"
  cfg="$(validate_config "$cfg")" || {
    echo "[fail] run: invalid configuration '$cfg' (use Debug or Release)" >&2
    return 1
  }
  echo "[run] phases: doctor -> build($cfg) -> boot -> install -> launch -> screenshot"
  cmd_doctor || { echo "[fail] step: doctor" >&2; return 1; }
  cmd_build "$cfg" || { echo "[fail] step: build" >&2; return 1; }
  cmd_boot || { echo "[fail] step: boot" >&2; return 1; }
  cmd_install || { echo "[fail] step: install" >&2; return 1; }
  cmd_launch || { echo "[fail] step: launch" >&2; return 1; }
  cmd_screenshot smoke || { echo "[fail] step: screenshot" >&2; return 1; }
  echo "[ok] run: all steps complete"
}

main() {
  detect_xcode
  mkdir -p "$TMP_DIR"
  CACHE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xcode-tools.XXXXXX")" || exit 1
  trap 'rm -rf "$CACHE_DIR"' EXIT

  if [[ $# -eq 0 ]]; then
    usage >&2
    die "missing command"
  fi
  local cmd="$1"; shift
  case "$cmd" in
    doctor)     cmd_doctor "$@" ;;
    build)      cmd_build "$@" ;;
    boot)       cmd_boot "$@" ;;
    install)    cmd_install "$@" ;;
    launch)     cmd_launch "$@" ;;
    screenshot) cmd_screenshot "$@" ;;
    run)        cmd_run "$@" ;;
    help|--help|-h) usage ;;
    *) echo "" >&2; usage >&2; die "unknown command: $cmd" ;;
  esac
  local rc=$?
  echo "EXIT $rc"
  exit "$rc"
}

main "$@"
