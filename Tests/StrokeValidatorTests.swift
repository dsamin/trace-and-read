//
//  StrokeValidatorTests.swift
//  Tests
//
//  Pins down the make-or-break behavior: the validator must accept a faithful
//  trace, accept a sloppy-but-honest trace when tolerance is generous, reject
//  the same sloppy trace when strict, and catch wrong start / direction / dab.
//

import XCTest
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
// In the Xcode app build the types live in the app module; in the SwiftPM
// core-verification build (e.g. on Linux) they live in LearningKitCore.
#if canImport(TraceAndRead)
@testable import TraceAndRead
#else
@testable import LearningKitCore
#endif

final class StrokeValidatorTests: XCTestCase {

    private let validator = StrokeValidator()

    /// A simple top-to-bottom vertical guide ("big line down").
    private let downLine = Pen.line(CGPoint(x: 0.5, y: 0.15),
                                    CGPoint(x: 0.5, y: 0.85),
                                    cue: "big line down")

    private func trace(_ pts: [CGPoint]) -> [CGPoint] { pts }

    func testFaithfulTraceIsAccepted() {
        let captured = trace((0...20).map {
            CGPoint(x: 0.5 + .random(in: -0.01...0.01), y: 0.15 + 0.7 * CGFloat($0) / 20)
        })
        XCTAssertEqual(validator.validate(captured: captured, against: downLine,
                                          tolerance: .generous), .good)
        XCTAssertEqual(validator.validate(captured: captured, against: downLine,
                                          tolerance: .strict), .good)
    }

    func testSloppyTraceAcceptedWhenGenerousRejectedWhenStrict() {
        // Drifts ~0.13 sideways at the middle — fine for a beginner, not for mastery.
        let captured = (0...20).map { i -> CGPoint in
            let t = CGFloat(i) / 20
            let drift = sin(t * .pi) * 0.13
            return CGPoint(x: 0.5 + drift, y: 0.15 + 0.7 * t)
        }
        XCTAssertEqual(validator.validate(captured: captured, against: downLine,
                                          tolerance: .generous), .good)
        if case .good = validator.validate(captured: captured, against: downLine,
                                           tolerance: .strict) {
            XCTFail("Strict tolerance should reject a 0.13 drift")
        }
    }

    func testWrongDirectionIsCaught() {
        // Same line, run bottom-to-top.
        let captured = (0...20).map { i -> CGPoint in
            CGPoint(x: 0.5, y: 0.85 - 0.7 * CGFloat(i) / 20)
        }
        let outcome = validator.validate(captured: captured, against: downLine,
                                         tolerance: .generous)
        XCTAssertEqual(outcome, .retry(.wrongDirection))
    }

    func testWrongStartIsCaught() {
        // Starts far from the green dot, in a different region entirely.
        let captured = (0...20).map { i -> CGPoint in
            CGPoint(x: 0.1 + 0.02 * CGFloat(i), y: 0.5)
        }
        let outcome = validator.validate(captured: captured, against: downLine,
                                         tolerance: .generous)
        if case .good = outcome { XCTFail("A wrong-start stroke must not pass") }
    }

    func testTinyDabIsTooShort() {
        let captured = [CGPoint(x: 0.5, y: 0.15), CGPoint(x: 0.5, y: 0.18)]
        XCTAssertEqual(validator.validate(captured: captured, against: downLine,
                                          tolerance: .generous), .retry(.tooShort))
    }

    func testToleranceInterpolationMovesGenerousToStrict() {
        let new = StrokeTolerance.interpolated(mastery: 0)
        let mastered = StrokeTolerance.interpolated(mastery: 1)
        XCTAssertGreaterThan(new.startRadius, mastered.startRadius)
        XCTAssertGreaterThan(new.meanPathDistance, mastered.meanPathDistance)
        XCTAssertLessThan(new.coverage, mastered.coverage)
    }

    func testResampleProducesRequestedCount() {
        let pts = (0...5).map { CGPoint(x: CGFloat($0), y: 0) }
        XCTAssertEqual(StrokeMath.resample(pts, count: 48).count, 48)
    }

    // MARK: - Real content: data integrity + every authored letter is traceable

    private let content = ContentLibrary()

    /// Every letter in the name and the CVC bank must have authored formation
    /// data — otherwise the tracing flow would silently skip it.
    func testEveryWordLetterHasFormationData() {
        for word in content.allWords {
            for ch in word.letters {
                XCTAssertNotNil(content.letterForm(for: ch),
                                "Missing formation data for '\(ch)' in word '\(word.text)'")
            }
            // The flow relies on a 1:1 mapping (no silently dropped letters).
            XCTAssertEqual(content.letterForms(for: word).count, word.letters.count,
                           "Word '\(word.text)' loses a letter when resolving forms")
        }
    }

    /// Every authored stroke voices a sound and starts/ends at distinct points.
    func testAuthoredLettersAreWellFormed() {
        for form in content.lettersByFamily {
            XCTAssertFalse(form.sound.isEmpty, "'\(form.character)' has no sound")
            for stroke in form.strokes {
                XCTAssertGreaterThanOrEqual(stroke.points.count, 2,
                    "'\(form.character)' has a degenerate stroke")
                // Allow legitimate tiny strokes (the dots on i / j are ~0.04)
                // while still catching a truly degenerate zero-length stroke.
                XCTAssertGreaterThan(stroke.length, 0.02,
                    "'\(form.character)' has a near-zero-length stroke")
            }
        }
    }

    /// The make-or-break "feel" check across the WHOLE real alphabet: tracing a
    /// letter's own guide faithfully must be accepted (no letter is impossible
    /// to satisfy), and running that same stroke backwards must NOT pass — the
    /// validator is genuinely checking direction on real shapes, not a toy line.
    func testTracingTheRealGuidesBehavesCorrectly() {
        let tol = StrokeTolerance.generous
        for form in content.lettersByFamily {
            for (i, stroke) in form.strokes.enumerated() {
                // Faithful trace = the guide resampled with a touch of jitter.
                let faithful = StrokeMath.resample(stroke.points, count: 40).map {
                    CGPoint(x: $0.x + .random(in: -0.008...0.008),
                            y: $0.y + .random(in: -0.008...0.008))
                }
                XCTAssertEqual(validator.validate(captured: faithful, against: stroke, tolerance: tol),
                               .good,
                               "Faithful trace of '\(form.character)' stroke \(i) was rejected")

                // Reversed trace must not be accepted as-is (skip near-symmetric
                // strokes whose endpoints nearly coincide, where direction is
                // genuinely ambiguous).
                let endsGap = StrokeMath.distance(stroke.start, stroke.end)
                if endsGap > tol.startRadius * 1.5 {
                    let reversed = Array(faithful.reversed())
                    XCTAssertNotEqual(validator.validate(captured: reversed, against: stroke, tolerance: tol),
                                      .good,
                                      "Reversed trace of '\(form.character)' stroke \(i) was wrongly accepted")
                }
            }
        }
    }
}
