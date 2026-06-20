# Building Trace & Read

This is a native SwiftUI **iPad** app (iPadOS 17+, landscape-locked, fully
offline, zero third-party dependencies). It builds and runs **only on macOS
with Xcode** — Apple's SDKs, `xcodebuild`, and the iPad Simulator do not exist
on Linux.

> ⚠️ The code in this repository was authored on a Linux environment that has
> no Apple toolchain, so it has **not been compiled or run here**. The steps
> below are how to build, test, and verify it on a Mac. Expect to fix the odd
> small thing on first compile (a missing SF Symbol renders blank rather than
> failing; a stray type nudge is possible) — the architecture and logic are
> complete and self-consistent.

## Prerequisites

- macOS with Xcode 15+ (for the iPadOS 17 SDK).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

## Generate the Xcode project

```sh
cd trace-and-read
xcodegen generate          # reads project.yml → TraceAndRead.xcodeproj
```

## Build for an iPad simulator

```sh
xcodebuild \
  -project TraceAndRead.xcodeproj \
  -scheme TraceAndRead \
  -destination 'platform=iOS Simulator,name=iPad Pro (11-inch) (M4)' \
  build
```

(Use `xcrun simctl list devices` to see the iPad simulators you have, and swap
the `name=` to match.)

## Run the unit tests (the make-or-break validator)

```sh
xcodebuild \
  -project TraceAndRead.xcodeproj \
  -scheme TraceAndRead \
  -destination 'platform=iOS Simulator,name=iPad Pro (11-inch) (M4)' \
  test
```

`Tests/StrokeValidatorTests.swift` pins the core risk: faithful traces pass,
sloppy traces pass when tolerance is generous and fail when strict, and wrong
start / wrong direction / tiny-dab are all caught.

## Launch in the simulator

```sh
xcrun simctl boot 'iPad Pro (11-inch) (M4)'
open -a Simulator
xcrun simctl install booted \
  "$(xcodebuild -project TraceAndRead.xcodeproj -scheme TraceAndRead -showBuildSettings | awk '/ BUILT_PRODUCTS_DIR/{print $3}')/TraceAndRead.app"
xcrun simctl launch booted com.devan.traceandread.app
```

## Verifying the core loop

Drive it by hand and confirm the acceptance criteria in `README.md`:

1. Opens on **Jayden's name** as oversized guided letters; a warm voice greets him.
2. Tap the pencil → 3-step fade per letter: **demo** (hand + green dot + arrow +
   spoken cue) → **guided trace** → **mandatory free-write** with the guide gone.
3. Each finished letter voices its **sound** ("juh", "aaa", …), not its name.
4. After the name, the **picture chooser** (tap to hear, tap again to write).
5. Finishing a word fires the **write-then-read bridge**: letters blend, sounds
   play, picture appears.
6. The **"just trace"** button (scribble icon) is always one tap away.
7. The **parent gate** (gear, top-right): press, hold, then drag to open settings.

## Dropping in real voice later

`SystemAudioEngine` prefers a bundled recording named after each clip
(`Resources/Audio/<clipName>.m4a`) and falls back to `AVSpeechSynthesizer`.
Record clips, drop them in `Resources/Audio/`, regenerate — no call sites change.
