---
name: simulator-testing
description: >
  Verify the Rain Dodger app builds, boots, installs, and launches on the iOS
  simulator. Use when asked to run the app, verify a build or launch, smoke-test
  a change, check that the app boots, or take a simulator screenshot. Do not use
  for running tests, CI, or UI automation — those come later.
---

I am the simulator smoke-test operator for this repo. I verify Rain Dodger can
be built, booted, installed, and launched on the iOS simulator, and I report
honest evidence about what was and was not proven.

## When to use

- **As the Reviewer, after the code review session completes** (see the
  `swift-review` skill): run the smoke flow before issuing the verdict — a
  reviewed change should be built and launched, and its screenshot handed to
  the user as evidence.
- As the Executor, verifying a build/launch before handoff (the verification
  step in `.opencode/agent/executor.md`).
- User asks "run the app", "does it launch?", "does it boot?", "smoke-test it".
- Before reporting a phase done: run a smoke check and include its output.
- Taking a simulator screenshot to confirm what is on screen.

Not for: running tests, CI, or UI automation — those come later.

## Procedure — one path: `.opencode/scripts/xcode-tools.sh`

Single entry point: `bash .opencode/scripts/xcode-tools.sh <command> [args]`.
Never mix in direct `xcodebuild`/`simctl` calls; the script owns the
environment and simulator selection.

1. **doctor** — toolchain health + chosen simulator.
   - Config: `iPhone 17` / `iOS 26.5` in
     `.opencode/scripts/simulator-config.json`; `RD_SIM` env var overrides the
     device name; a blank `os` in the config prefers the newest OS.
2. **build [Debug]** — builds into
   `.opencode/tmp/DerivedData/Build/Products/<Config>-iphonesimulator/*.app`
   (no sim boot needed). On failure: `tail -40 .opencode/tmp/xcodebuild.log`.
3. **boot** — `simctl boot` + `bootstatus -b`; an already-booted sim is fine
   ("already booted" is `[ok]`).
4. **install** — uninstalls the bundle id first if present, then installs.
5. **launch** — prints exit 0 + pid. Process-level visibility varies by sim
   runtime; the `[warn] no process-level visibility` line is EXPECTED on this
   sim runtime — verify visually via screenshot, not via process lists.
6. **screenshot [name]** — writes
   `.opencode/tmp/screenshots/<name>-<YYYYMMDD-HHMMSS>.png` and prints the
   path; read the path back from the output and hand it to the human.
7. **run [Debug]** — doctor + build + boot + install + launch + screenshot.
   `EXIT 0` plus a screenshot path means the app is launchable.

## Honest verification

- `EXIT 0` from `launch` means simctl accepted the launch and printed a pid —
  it does NOT prove the UI rendered.
- The screenshot is the visual proof, for a human to inspect:
  - "verified launchable" = launch exit 0 + pid + screenshot produced.
  - "verified rendering" = a human inspected the screenshot.
- Never claim render-verified without the screenshot being inspected.

## Guardrails

- Never commit `.opencode/tmp/` — it is gitignored; confirm with
  `git status --short` before handoff.
- Never modify signing, identity, entitlements, or the project file
  (`pbxproj`) — the script builds with `CODE_SIGNING_ALLOWED=NO`.
- Never run `sudo` or `xcode-select` — the script sets `DEVELOPER_DIR` itself.
- Never uninstall other apps — `install` only touches this repo's bundle id.
- Do not open Simulator.app or interact with the UI; automation stays
  read-only.

## Troubleshooting

- xcodebuild errors with "unable to find utility" → run through the script (it
  sets `DEVELOPER_DIR`); never `xcode-select`.
- Sim not found / wrong OS → check `simulator-config.json` and `RD_SIM`,
  update the config.
- Boot timeout → stale build data first: `rm -rf .opencode/tmp/DerivedData`
  (script-owned path). Manual simulator shutdown/erase is a last resort,
  user-approved only — it bypasses the script's simulator ownership.
- Install fails after a code change → uninstall first; the script already does.
- Launch reports "no process-level visibility" → expected on this sim runtime;
  use the screenshot.
- Disk low → run `doctor` and read its disk check.

## Output format

- Machine lines: `[ok]` / `[warn]` / `[fail]` per step plus a final
  `EXIT <rc>`.
- Reporting to the user: one line per step plus the screenshot path, taken
  from the screenshot step's own path line.
- Never claim render-verified without the screenshot inspection.
