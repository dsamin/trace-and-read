# CoreVerification

A SwiftPM package that builds, **tests, and runs** the platform-independent
core of Trace & Read on any platform — including Linux, where the full
SwiftUI / SwiftData / AVFoundation iPad app cannot be built.

The sources are **symlinks** to the real files under `../Chassis/` and
`../Features/`, so there is a single source of truth shared with the Xcode app
build (no copies to drift). The included core is pure Foundation — exactly the
"LearningKit"-shaped, no-Apple-UI core the spec calls for:

- `Chassis/ContentLibrary/*` — stroke geometry/math, HWT letter formation data,
  CVC word/sound/picture bank.
- `Features/TracingCanvas/StrokeValidator.swift` — the make-or-break
  stroke-order/direction validator with tunable tolerance.

## Run the tests (verifies the make-or-break component on real data)

```sh
export PATH=/path/to/swift/usr/bin:$PATH
cd CoreVerification
swift test
```

10 tests: faithful traces pass; sloppy traces pass when generous and fail when
strict; wrong start / wrong direction / tiny dab are caught; tolerance
interpolates generous→strict; **every letter in the name + CVC bank has
formation data**; and **every authored letter's own guide validates while its
reverse does not**.

## Run the headless core-loop demo

```sh
cd CoreVerification
swift run LoopDemo
```

Drives the real ContentLibrary + StrokeValidator through the exact app
sequence — name → chooser → per-letter 3-step fade (demo → guided →
**mandatory free-write**) with an errorless retry → letter sounds →
write-then-read blend — printing the spoken lines and verdicts. This exercises
the loop *logic* end to end; rendering / touch / audio / persistence are the
iPad layer (build on macOS per `../BUILD.md`).
