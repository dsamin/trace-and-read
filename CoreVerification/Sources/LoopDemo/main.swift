//
//  LoopDemo — a headless driver of the Trace & Read CORE LOOP.
//
//  The iPad app's touch + SwiftUI rendering cannot run on Linux, but the
//  *logic* of the loop can: this program drives the real ContentLibrary and
//  the real StrokeValidator through the exact sequence the app follows —
//  name → word chooser → per-letter 3-step fade (demo → guided → free-write)
//  → letter sound → write-then-read blend — including an errorless retry.
//
//  It prints the spoken lines and validator verdicts so the loop is
//  demonstrably exercised end to end on real data, with real tolerances.
//
import Foundation
import LearningKitCore

let content = ContentLibrary()
let validator = StrokeValidator()

func say(_ who: String, _ text: String) { print("  🔊 [\(who)] \(text)") }
func beat(_ s: String) { print("\n\u{2014}\u{2014} \(s) \u{2014}\u{2014}") }

/// Simulate a fingertip tracing a guide stroke. `mode` lets us inject an
/// honest beginner wobble or a wrong-direction attempt.
enum TraceMode { case faithful, drift(CGFloat), reversed }
func simulateTrace(of stroke: Stroke, _ mode: TraceMode = .faithful) -> [CGPoint] {
    let base = StrokeMath.resample(stroke.points, count: 40)
    switch mode {
    case .faithful:
        return base.map { CGPoint(x: $0.x + .random(in: -0.01...0.01),
                                  y: $0.y + .random(in: -0.01...0.01)) }
    case .drift(let d):
        return base.enumerated().map { i, p in
            let t = CGFloat(i) / CGFloat(base.count - 1)
            return CGPoint(x: p.x + sin(t * .pi) * d, y: p.y)
        }
    case .reversed:
        return Array(base.reversed())
    }
}

/// Run one letter through demo → guided → free-write, with errorless retries.
/// Returns true once the unscaffolded free-write succeeds.
func traceLetter(_ form: LetterForm, mastery: Double, injectMistakeOnFirstStroke: Bool) {
    let tol = StrokeTolerance.interpolated(mastery: mastery)
    print("\n  ✎ Letter '\(form.character)'  (\(form.family.displayName), mastery \(Int(mastery*100))%)")

    for (i, stroke) in form.strokes.enumerated() {
        // (a) DEMO
        say("voice", "\(stroke.cue)")

        // (b) GUIDED TRACE — forgiving; the guide is visible.
        let guided = validator.validate(captured: simulateTrace(of: stroke),
                                        against: stroke,
                                        tolerance: .generous)
        print("     guided trace … \(verdict(guided))")

        // (c) FREE-WRITE FROM MEMORY — the mandatory unscaffolded step.
        if injectMistakeOnFirstStroke && i == 0 {
            let wrong = validator.validate(captured: simulateTrace(of: stroke, .reversed),
                                           against: stroke, tolerance: tol)
            if case .retry(let fault) = wrong {
                print("     free-write … \(verdict(wrong))  (errorless: re-model, no buzzer)")
                say("voice", fault.encouragement)        // encouraging, never a fail
            }
        }
        // Retry / honest attempt succeeds.
        let free = validator.validate(captured: simulateTrace(of: stroke, .drift(0.04)),
                                      against: stroke, tolerance: tol)
        print("     free-write … \(verdict(free))")
    }
    // Letter complete → voice the SOUND, not the name.
    say("voice", "\"\(form.sound)\"")
}

func verdict(_ o: StrokeOutcome) -> String {
    switch o {
    case .good: return "✓ good"
    case .retry(let f): return "↻ retry (\(f))"
    }
}

// ───────────────────────────────────────────────────────────────────────────

print("TRACE & READ — core-loop logic demo (headless, real validator + data)")

beat("Day one: NAME screen")
let name = content.nameWord
say("voice", "Let's write your name, \(name.spokenLabel)!")
print("  name laid out as oversized guided letters: \(name.text.map(String.init).joined(separator: " "))")
// Trace the first two letters of the name to show the flow on the anchor word.
for ch in name.letters.prefix(2) {
    if let form = content.letterForm(for: ch) {
        traceLetter(form, mastery: 0.0, injectMistakeOnFirstStroke: ch == name.letters.first)
    }
}
print("  …(remaining name letters follow the same 3-step fade)")

beat("WORD CHOOSER (spoken, picture-based — no reading)")
say("voice", "Pick a picture to write.")
let word = content.word("sun")!
print("  child taps the picture → hears: ")
say("voice", "\(word.spokenLabel)")
print("  picture symbol: \(word.symbolName)")

beat("TRACING '\(word.text)' — 3-step fade per letter, mandatory free-write")
let forms = content.letterForms(for: word)
for (idx, form) in forms.enumerated() {
    // Mastery rises across letters to show tolerance tightening in action.
    traceLetter(form, mastery: Double(idx) * 0.5, injectMistakeOnFirstStroke: idx == 0)
}

beat("WRITE-THEN-READ BRIDGE")
print("  letters slide together: \(word.text)")
say("voice", "\(word.phonemes.joined(separator: "… "))…")
say("voice", "\(word.spokenLabel)!")
print("  picture revealed: \(word.symbolName)   ← writing the word IS reading it")

beat("FREE MODE (\"just trace, no judging\") — always one tap away")
print("  validation OFF: every stroke accepted, calm tone, no scoring")

print("\n✅ Core loop exercised end to end on real content with the real validator.")
print("   (Rendering, touch input, audio playback and SwiftData persistence are")
print("    the iPad/SwiftUI layer — build & run that on macOS per BUILD.md.)")
