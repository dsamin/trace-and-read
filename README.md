# Trace & Read

*Write your name first, then the three letters — and watch them become a word you can read.*

> **Status:** Idea spec'd and critiqued — not yet built. This README is the canonical spec; build from it.
> **Build order:** App 3 of 5 in a shared-chassis learning slate, and the one that tackles Jayden's hardest skill — writing.

## What it is

Trace & Read is an iPad app that teaches a 4-year-old how to **form letters by hand** and then **bridges that act of writing directly into reading the word he just wrote**. It is the third of five small learning apps a solo dad (Devan) is building exclusively for his son, Jayden. Writing is Jayden's hardest skill, so this app takes the thing he finds most difficult and wires it straight to the reading goal: the moment he finishes tracing `s-u-n`, the app blends the sounds aloud with him — "s-u-n… *sun!*" — and shows a picture of the sun. **Writing the word is the unlock for reading it.**

It is built on three rules the whole app slate shares. It is **audio-first** (a 4yo can't read a menu, so every instruction is spoken). It is **errorless** (a wrong stroke is never a buzzer or a fail screen — it gently re-models the correct stroke and lets him try again). And it is **calm** (muted palette, soft transitions, one warm human voice, no confetti, no streaks, no timers, no scores). There are no ads, no in-app purchases, no accounts, and no network — everything runs on-device.

## Who it's for

**Jayden, age 4.** Bright and curious, but he genuinely struggles with handwriting and letter formation, and he needs help recognizing and reading words. He cannot yet read, so nothing in the app may require reading to operate it. He has the focus span of a four-year-old: the app must reward him fast, never frustrate him, and always let him bail to a low-pressure mode on a tired day.

This is a personal app built for one child. It is not a general-market product, which frees it to optimize hard for Jayden specifically — starting with the single most motivating thing a 4yo can write: **his own name.**

## What it teaches

1. **Letter formation with correct stroke order** — the primary goal. Where to start each letter, which direction to move, and the muscle memory of forming it without a guide.
2. **Reading via the write-then-read bridge** — every word he writes is immediately blended aloud and shown as a picture, so forming the letters becomes the path to reading the word. This is the core pedagogical bet of the app.
3. **Letter–sound correspondence** — every completed letter voices its **sound**, not its name ("sss", not "ess"), because sounds are what decode words.
4. **Reversal prevention** — letters are grouped by **stroke family** (Handwriting Without Tears style: verticals → "magic-c" curves → diagonals) rather than alphabetically, which is far better at preventing the classic b/d/p/q reversals.

Physically forming letters is known to boost letter recognition far more than watching or typing them — so the writing *is* the reading instruction, not a detour from it.

## How it works

The core loop, step by step:

1. **Day one opens on his own name.** The most motivating possible first word. After he's met his name, he picks a CVC word (cat, dog, sun…) from a spoken, picture-based chooser.
2. **Per letter, a 3-step fade (LetterSchool-style):**
   - **Demo** — a hand demonstrates the stroke while a warm voice gives the cue ("big line down… little curve"). A **green start dot** and an **arrow** show where to begin and which way to go.
   - **Guided trace** — he traces over the on-screen guide. Stroke tolerance is **very generous early** and tightens only as mastery rises.
   - **Free-write from memory** — the guide disappears and he writes the letter **once, unscaffolded**. This is the step most tracing apps skip, and it's the one that builds durable formation instead of guide-dependence. Hints fade back in only if he stalls.
3. **Each completed letter voices its sound** ("sss"), reinforcing letter→sound mapping as he goes.
4. **On finishing all three letters, the bridge fires:** the app blends the sounds aloud *with him* — "s-u-n… *sun!*" — and reveals the picture. The word he just wrote is now a word he can read.
5. **A wrong action never fails him.** If a stroke goes wrong, the voice stays encouraging ("let's try that line again") and the correct stroke is re-modeled. There is no buzzer, no red X, no fail screen.
6. **"Just trace, no judging" free mode is one tap away** — for low-energy days, he can trace with zero validation and zero pressure.

## Screens

- **Name screen (day one / home anchor)** — his name laid out as oversized guided letters; the entry point and the emotional hook.
- **Word chooser** — a spoken, picture-driven picker of CVC words. No reading required; tap a picture, hear the word.
- **Tracing canvas** — the heart of the app. Big stroke width, oversized start dots, the demo hand, the green dot + arrow, and the 3-step fade. Finger-first; stylus optional.
- **Write-then-read bridge** — the blend-and-reveal moment: letters animate together, voice blends the sounds, picture appears.
- **Free "just trace" mode** — the same canvas with validation turned off and an even calmer tone.
- **Parent area (behind a parent gate)** — settings, word/letter selection, left-handed mirrored-demo toggle, and a **replay of how he formed each letter**. Reached via press-and-hold then drag, so a 4yo can't wander in.

## Key design decisions

These are the make-or-break calls specific to this app:

- **Robust real-time stroke validation is the hardest problem — this is the #1 risk.** Detecting stroke *order* and *direction* (not just "did he color inside the lines") via PencilKit / Core Graphics path-matching must be **strict enough to teach correct formation yet forgiving enough not to frustrate a four-year-old.** The chosen answer: start tolerance very generous, tighten with mastery, and **test with Jayden early and often.** Get this wrong in either direction and the app fails — too strict and he quits, too loose and it doesn't teach. Build the validator behind a clean interface with tunable tolerance constants so the strictness can be dialed without touching the UI.
- **The unscaffolded free-write step is mandatory, not optional.** Tracing alone breeds guide-dependence. The recall step is the whole point — never let the MVP ship with only demo + trace.
- **Letters voice their sound, not their name.** Sounds decode words; names don't.
- **HWT stroke-family grouping over A–Z.** Grouping by motor pattern (verticals → magic-c → diagonals) is the reversal-prevention strategy.
- **The redo line must sound like encouragement, never failure.** This is errorless learning — the voice direction matters as much as the code.
- **Name-first personalization.** The strongest motivational lever available at age 4 is his own name; it leads everything.
- **Big targets, finger-first.** Oversized guide dots and thick strokes; stylus is welcome but never required. Left-handed mirrored demo is a planned toggle so the demo hand doesn't occlude his writing hand.

## Shared chassis

The five apps are **not independent**. They share one core, and Trace & Read is the **third** app to build on it (after Sound Catcher, which establishes the chassis). The shared pieces:

- **Tagged content library** — the word / sound / picture database (CVC words, their phonemes, their pictures). Trace & Read reuses this directly for its word list and the write-then-read bridge.
- **Real-human-voice audio engine** — plays pre-recorded human-voice clips. Trace & Read uses it for stroke cues, letter sounds, the blend-and-reveal, and the encouraging redo lines.
- **Mastery / spaced-repetition review service** — the small cross-app "what needs review" service. Letter-formation mastery levels (which drive tolerance tightening) feed into and read from this shared service.

**Architectural rule:** every reusable engine — content library, audio engine, mastery/review service — must have **no app-specific imports** so it can be lifted cleanly into a shared Swift package (**LearningKit**) and reused by the other apps. Build Trace & Read's engines as if they already live in that package: keep them in a dedicated `Chassis/` group, depend only on Foundation/AVFoundation/SwiftData, and never let them `import` a feature module.

## Tech

- **Native SwiftUI**, iPad-only, **landscape-locked**, **iPadOS 17+**.
- Modern APIs: `@Observable`, **SwiftData** for persistence, modern animation APIs.
- **Stroke capture/validation** via PencilKit and/or Core Graphics path-matching, behind a tunable-tolerance interface.
- **Audio:** `AVAudioPlayer` with pre-recorded human-voice clips, with **`AVSpeechSynthesizer` as a swappable placeholder** during development so the full loop is testable immediately (record real voice later without touching the call sites — the audio engine exposes one play-clip API and chooses the backend internally).
- **Zero third-party dependencies. Fully offline.** No network, no accounts, no analytics.
- Reusable engines kept in their own group/package boundary (the shared chassis → LearningKit).
- **Project generation:** scaffold with XcodeGen or a Swift Package app target — there is no Xcode GUI in the build environment; everything must build from the command line with `xcodebuild`.

## Build plan / MVP

This maps to the four-phase workflow in the build prompt: brainstorm → UI/UX design → SwiftUI implementation → end-to-end simulator test. The implementation phase delivers, in order:

1. **Name-first screen** — his name as guided letters; the day-one entry point.
2. **HWT lowercase letter set** — formation data (start point, ordered stroke list, direction per stroke) for lowercase letters, grouped by stroke family.
3. **The 3-step flow with the mandatory free-write step** — demo → guided trace → unscaffolded recall, with generous-then-tightening tolerance.
4. **Sound-on-completion** — each finished letter voices its sound.
5. **Write-then-read bridge for ~10 CVC words** — blend aloud + reveal picture.
6. **"Just trace" free mode** — validation off, one tap away.
7. **Parent gate** — press-and-hold then drag to reach settings.

Build the three chassis engines (content library, audio engine, mastery/review service) **first**, then layer the features on top.

**Deferred (ship without if needed):**

- Left-handed mirrored-demo toggle.
- Parent replay of how each letter was formed.
- Real recorded human-voice clips (use `AVSpeechSynthesizer` placeholder until then).
- Uppercase letters and an expanded word bank beyond the first ~10.

**Effort & risk note.** The code surface is small (no backend, no accounts, no network), but the stroke validator is the real time sink and the make-or-break risk — budget most of the implementation time there, and gate "done" on it feeling right with a real fingertip, not just on it compiling.

## Acceptance criteria

The app is done when every box below is checked and verified in an iPad simulator:

- [ ] App is iPad-only and landscape-locked; runs fully offline with zero third-party dependencies.
- [ ] Day one opens on **Jayden's own name** rendered as oversized guided letters.
- [ ] After the name, he can pick a CVC word from a **spoken, picture-based chooser** that requires no reading.
- [ ] Every instruction is **spoken**; nothing in the child-facing flow requires reading.
- [ ] Each letter runs the **3-step fade**: demo (hand + green start dot + arrow + voice cue) → guided trace → **mandatory unscaffolded free-write**.
- [ ] Stroke validation checks **order and direction** (not just coverage), starts **very generous**, and **tightens as mastery rises**.
- [ ] A wrong stroke **never** produces a buzzer / red X / fail screen — it re-models the stroke and the voice line stays **encouraging**, then lets him retry.
- [ ] Each completed letter voices its **sound** (not its name).
- [ ] Finishing all three letters fires the **write-then-read bridge**: blends the sounds aloud and shows the picture, working for **~10 words**.
- [ ] **"Just trace, no judging"** free mode is reachable in one tap with validation fully off.
- [ ] No confetti, no streaks, no timers, no scores shown to the child; muted palette, soft transitions, one warm voice.
- [ ] A **parent gate** (press-and-hold then drag) hides all settings from the child.
- [ ] Audio plays via `AVAudioPlayer` clips with an `AVSpeechSynthesizer` placeholder swappable without changing call sites.
- [ ] Content library, audio engine, and mastery/review service have **no app-specific imports** and are structured for extraction into the shared **LearningKit** package.
- [ ] App **builds clean** with `xcodebuild` against an iPad simulator, and the **complete core loop runs end to end** when launched in that simulator (name → word → 3-step fade with free-write → letter sounds → write-then-read blend + picture → free mode → parent gate) — verified by actually running it, not just by compilation.

## Project layout (target)

```
trace-and-read/
├── README.md
├── project.yml                      # XcodeGen spec (or Package.swift app target — no Xcode GUI)
├── App/
│   ├── TraceAndReadApp.swift        # @main, landscape lock, SwiftData container
│   └── RootView.swift               # name-first entry → word chooser
├── Features/
│   ├── NameScreen/
│   ├── WordChooser/
│   ├── TracingCanvas/               # 3-step fade, stroke validation, demo hand
│   ├── WriteThenRead/               # blend-and-reveal bridge
│   ├── FreeTrace/                   # "just trace, no judging"
│   └── ParentGate/                  # press-and-hold + drag → settings & replay
├── Chassis/                         # → extract to LearningKit (no app imports)
│   ├── ContentLibrary/              # tagged word/sound/picture DB
│   ├── AudioEngine/                 # AVAudioPlayer clips + AVSpeech placeholder
│   └── ReviewService/               # mastery / spaced-repetition
└── Resources/
    ├── Audio/                       # human-voice clips (later)
    └── Pictures/                    # CVC word art
```

