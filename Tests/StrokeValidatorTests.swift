//
//  StrokeValidatorTests.swift
//  Tests
//
//  Pins down the make-or-break behavior: the validator must accept a faithful
//  trace, accept a sloppy-but-honest trace when tolerance is generous, reject
//  the same sloppy trace when strict, and catch wrong start / direction / dab.
//

import XCTest
import CoreGraphics
@testable import TraceAndRead

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
}
