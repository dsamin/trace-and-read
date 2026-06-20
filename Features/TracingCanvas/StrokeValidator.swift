//
//  StrokeValidator.swift
//  Features › TracingCanvas
//
//  THE make-or-break component. Decides whether a captured fingerstroke
//  matches an expected letter stroke — checking START position, DIRECTION,
//  and PATH closeness (not just "did he color inside the lines"). Strict
//  enough to teach correct formation, forgiving enough not to frustrate a
//  four-year-old.
//
//  All strictness lives in `StrokeTolerance` constants and the
//  generous→strict interpolation here. The UI never hard-codes a threshold,
//  so the feel can be dialed without touching any view. Inputs are in the
//  unit square (0...1), matching the formation data.
//

import Foundation
import CoreGraphics

/// Every tunable knob in one place. Distances are in unit-square units
/// (the canvas maps the unit square onto a centered square region).
public struct StrokeTolerance: Sendable {
    /// How far the finger may start from the stroke's start dot.
    public var startRadius: CGFloat
    /// How far the finger may end from the stroke's end (proves direction).
    public var endRadius: CGFloat
    /// Max average distance of the finger path from the guide polyline.
    public var meanPathDistance: CGFloat
    /// Hard ceiling on any single point's distance from the guide (a big
    /// excursion fails even if the average is fine).
    public var maxPathDistance: CGFloat
    /// Fraction of the guide that must be covered by the finger path.
    public var coverage: CGFloat
    /// Minimum finger-path length as a fraction of the guide length (rejects a
    /// tiny dab that happens to sit near the start).
    public var minLengthRatio: CGFloat

    public init(startRadius: CGFloat, endRadius: CGFloat, meanPathDistance: CGFloat,
                maxPathDistance: CGFloat, coverage: CGFloat, minLengthRatio: CGFloat) {
        self.startRadius = startRadius
        self.endRadius = endRadius
        self.meanPathDistance = meanPathDistance
        self.maxPathDistance = maxPathDistance
        self.coverage = coverage
        self.minLengthRatio = minLengthRatio
    }

    /// VERY generous — day one, a brand-new letter. Errs hard toward accepting.
    public static let generous = StrokeTolerance(
        startRadius: 0.26, endRadius: 0.26, meanPathDistance: 0.20,
        maxPathDistance: 0.34, coverage: 0.52, minLengthRatio: 0.45
    )

    /// Strict — a well-mastered letter. Still humane, never hostile.
    public static let strict = StrokeTolerance(
        startRadius: 0.12, endRadius: 0.12, meanPathDistance: 0.085,
        maxPathDistance: 0.17, coverage: 0.82, minLengthRatio: 0.70
    )

    /// Interpolate generous→strict by mastery (0 = new, 1 = mastered).
    /// This is the whole "start loose, tighten with mastery" strategy, in one
    /// place, behind one number.
    public static func interpolated(mastery: Double) -> StrokeTolerance {
        let t = CGFloat(min(1, max(0, mastery)))
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * t }
        return StrokeTolerance(
            startRadius:     mix(generous.startRadius,     strict.startRadius),
            endRadius:       mix(generous.endRadius,       strict.endRadius),
            meanPathDistance: mix(generous.meanPathDistance, strict.meanPathDistance),
            maxPathDistance: mix(generous.maxPathDistance, strict.maxPathDistance),
            coverage:        mix(generous.coverage,        strict.coverage),
            minLengthRatio:  mix(generous.minLengthRatio,  strict.minLengthRatio)
        )
    }
}

/// Why a stroke needs another try. Maps directly to an *encouraging* spoken
/// line — there is no generic "wrong". Errorless by construction.
public enum StrokeFault: Sendable {
    case wrongStart        // started somewhere other than the green dot
    case wrongDirection    // right path, ran it backwards
    case offPath           // wandered away from the guide
    case tooShort          // a dab, not a stroke

    /// A warm redo line. Never a failure word.
    public var encouragement: String {
        switch self {
        case .wrongStart:     return "Let's start right on the green dot."
        case .wrongDirection: return "Almost! Let's go the other way this time."
        case .offPath:        return "So close. Let's try that line again."
        case .tooShort:       return "Let's trace the whole line together."
        }
    }
}

/// The verdict. `.good` advances; `.retry` re-models the stroke and lets him
/// try again. There is deliberately no `.fail`.
public enum StrokeOutcome: Sendable, Equatable {
    case good
    case retry(StrokeFault)

    public static func == (lhs: StrokeOutcome, rhs: StrokeOutcome) -> Bool {
        switch (lhs, rhs) {
        case (.good, .good): return true
        case let (.retry(a), .retry(b)):
            return String(describing: a) == String(describing: b)
        default: return false
        }
    }
}

/// Stateless stroke matcher. Pure function of (captured, guide, tolerance) —
/// trivially unit-testable, and the single source of truth for "did he form
/// the letter correctly".
public struct StrokeValidator {

    /// Resolution at which both strokes are resampled before comparison.
    public var sampleCount: Int = 48

    public init(sampleCount: Int = 48) {
        self.sampleCount = sampleCount
    }

    /// Validate one captured stroke against one expected guide stroke.
    public func validate(captured raw: [CGPoint],
                         against guide: Stroke,
                         tolerance: StrokeTolerance) -> StrokeOutcome {
        let guidePts = guide.points
        guard guidePts.count > 1 else { return .good }

        // Reject a tiny dab outright (covers single taps / accidental touches).
        let capturedLength = StrokeMath.length(of: raw)
        let guideLength = guide.length
        guard raw.count >= 2, guideLength > 0 else { return .retry(.tooShort) }
        if capturedLength < guideLength * tolerance.minLengthRatio {
            // It might still be a legitimate-but-short attempt at the start dot;
            // distinguish "started wrong" from "too short" for a better cue.
            let startGap = StrokeMath.distance(raw[0], guide.start)
            return startGap > tolerance.startRadius ? .retry(.wrongStart) : .retry(.tooShort)
        }

        let cap = StrokeMath.resample(raw, count: sampleCount)
        let ref = StrokeMath.resample(guidePts, count: sampleCount)

        // 1) START — must begin near the green dot.
        let startGap = StrokeMath.distance(cap.first ?? .zero, ref.first ?? .zero)

        // 2) DIRECTION — end near the guide's end. If it instead ends near the
        //    guide's START, it's the right shape run backwards.
        let endGap = StrokeMath.distance(cap.last ?? .zero, ref.last ?? .zero)
        let endToStartGap = StrokeMath.distance(cap.last ?? .zero, ref.first ?? .zero)

        if startGap > tolerance.startRadius {
            // Started at the wrong place — but if the finger clearly ran the
            // shape in reverse, the more useful cue is "go the other way".
            if endToStartGap < tolerance.endRadius &&
               StrokeMath.distance(cap.first ?? .zero, ref.last ?? .zero) < tolerance.startRadius {
                return .retry(.wrongDirection)
            }
            return .retry(.wrongStart)
        }

        if endGap > tolerance.endRadius {
            if endToStartGap < tolerance.endRadius {
                return .retry(.wrongDirection)
            }
            return .retry(.offPath)
        }

        // 3) PATH — how closely the finger hugged the guide.
        var sum: CGFloat = 0
        var peak: CGFloat = 0
        for p in cap {
            let d = StrokeMath.distanceToPolyline(p, ref)
            sum += d
            peak = max(peak, d)
        }
        let mean = sum / CGFloat(cap.count)
        if mean > tolerance.meanPathDistance || peak > tolerance.maxPathDistance {
            return .retry(.offPath)
        }

        // 4) COVERAGE — did the finger actually visit most of the guide?
        var covered = 0
        for g in ref {
            if StrokeMath.distanceToPolyline(g, cap) <= tolerance.maxPathDistance {
                covered += 1
            }
        }
        let coverage = CGFloat(covered) / CGFloat(ref.count)
        if coverage < tolerance.coverage {
            return .retry(.offPath)
        }

        return .good
    }
}
