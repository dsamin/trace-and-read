//
//  StrokeGeometry.swift
//  Chassis › ContentLibrary
//
//  Pure geometry helpers for describing and sampling letter strokes.
//  Everything here lives in a normalized unit square: x and y range 0...1,
//  origin top-left, y growing downward (matching SwiftUI / Core Graphics).
//  A consumer maps this unit square onto whatever on-screen rect it likes.
//
//  CHASSIS RULE: depends only on Foundation / CoreGraphics. No app imports.
//  Designed to be lifted verbatim into the shared `LearningKit` package.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics   // On Apple platforms; on Linux CGPoint/CGFloat come from Foundation.
#endif

/// A heading as a unit vector. A tiny portable stand-in for CGVector, which is
/// not available in swift-corelibs-foundation — keeping the chassis math pure
/// Foundation so it builds and is testable on any platform.
public struct Heading: Sendable, Equatable {
    public let dx: CGFloat
    public let dy: CGFloat
    public init(dx: CGFloat, dy: CGFloat) { self.dx = dx; self.dy = dy }
}

/// The Handwriting-Without-Tears motor families. Letters are grouped by the
/// motion the hand makes, not alphabetically — this is the reversal-prevention
/// strategy (b/d/p/q get separated because they live in different families).
public enum StrokeFamily: String, Codable, CaseIterable, Sendable {
    case vertical      // "big line down" — l, t, i, j ...
    case magicC        // "magic c" curves — c, o, a, d, g ...
    case diagonal      // slants — v, w, x, y, k, z ...

    /// A calm, spoken-friendly label for the parent area.
    public var displayName: String {
        switch self {
        case .vertical: return "Big lines"
        case .magicC:   return "Magic-c curves"
        case .diagonal: return "Slanted lines"
        }
    }
}

/// One pen-down→pen-up motion. The *order* of `points` encodes direction:
/// `points.first` is where the green start dot sits, `points.last` is where
/// the stroke ends. Validation cares about both.
public struct Stroke: Codable, Sendable, Identifiable {
    public let id: UUID
    /// Ordered polyline in unit-square coordinates.
    public let points: [CGPoint]
    /// Spoken cue for the demo step, e.g. "big line down".
    public let cue: String

    public init(points: [CGPoint], cue: String) {
        self.id = UUID()
        self.points = points
        self.cue = cue
    }

    public var start: CGPoint { points.first ?? .zero }
    public var end: CGPoint { points.last ?? .zero }

    /// Total arc length of the polyline (unit-square units).
    public var length: CGFloat { StrokeMath.length(of: points) }
}

/// Formation data for a single letter: where to start, the ordered strokes,
/// the direction of each, plus the *sound* it makes (not its name).
public struct LetterForm: Codable, Sendable, Identifiable {
    public let id: String          // the character as a string, e.g. "a"
    public let family: StrokeFamily
    public let strokes: [Stroke]
    /// The phoneme, spoken as a sound: "sss", not "ess".
    public let sound: String

    /// The letter itself. Derived from `id` so the stored state stays fully
    /// Codable (Character is not Codable), which lets the content library be
    /// serialized to/from a bundled pack later.
    public var character: Character { id.first ?? " " }

    public init(character: Character, family: StrokeFamily, sound: String, strokes: [Stroke]) {
        self.id = String(character)
        self.family = family
        self.sound = sound
        self.strokes = strokes
    }
}

// MARK: - Geometry math

/// Stateless polyline math used by both the renderer and the validator.
public enum StrokeMath {

    /// Euclidean distance between two points.
    public static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    /// Arc length of an ordered polyline.
    public static func length(of points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<points.count {
            total += distance(points[i - 1], points[i])
        }
        return total
    }

    /// Resample a polyline into exactly `count` points spaced evenly by arc
    /// length. This makes two strokes comparable regardless of how fast or
    /// jittery the finger moved.
    public static func resample(_ points: [CGPoint], count: Int) -> [CGPoint] {
        guard count > 1, points.count > 1 else { return points }
        let total = length(of: points)
        guard total > 0 else { return Array(repeating: points[0], count: count) }

        let step = total / CGFloat(count - 1)
        var result: [CGPoint] = [points[0]]
        var prev = points[0]
        var segIndex = 1
        var distAccrued: CGFloat = 0

        while result.count < count && segIndex < points.count {
            let next = points[segIndex]
            let segLen = distance(prev, next)
            if segLen <= 0 { segIndex += 1; prev = next; continue }

            if distAccrued + segLen >= step {
                let remain = step - distAccrued
                let t = remain / segLen
                let p = CGPoint(x: prev.x + (next.x - prev.x) * t,
                                y: prev.y + (next.y - prev.y) * t)
                result.append(p)
                prev = p
                distAccrued = 0
            } else {
                distAccrued += segLen
                prev = next
                segIndex += 1
            }
        }
        // Floating-point slack can leave us one short; pad with the endpoint.
        while result.count < count { result.append(points[points.count - 1]) }
        return result
    }

    /// Shortest distance from `p` to the segment a–b.
    public static func distanceToSegment(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lenSq = dx * dx + dy * dy
        if lenSq <= .ulpOfOne { return distance(p, a) }
        var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq
        t = min(1, max(0, t))
        let proj = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
        return distance(p, proj)
    }

    /// Shortest distance from `p` to a whole polyline.
    public static func distanceToPolyline(_ p: CGPoint, _ poly: [CGPoint]) -> CGFloat {
        guard poly.count > 1 else { return poly.first.map { distance(p, $0) } ?? .greatestFiniteMagnitude }
        var best = CGFloat.greatestFiniteMagnitude
        for i in 1..<poly.count {
            best = min(best, distanceToSegment(p, poly[i - 1], poly[i]))
        }
        return best
    }

    /// Point at a normalized fraction (0...1) along a polyline by arc length.
    /// Used to drive the demo-hand animation and the moving dot.
    public static func point(at fraction: CGFloat, along points: [CGPoint]) -> CGPoint {
        guard points.count > 1 else { return points.first ?? .zero }
        let clamped = min(1, max(0, fraction))
        let target = length(of: points) * clamped
        var travelled: CGFloat = 0
        for i in 1..<points.count {
            let segLen = distance(points[i - 1], points[i])
            if travelled + segLen >= target {
                let t = segLen > 0 ? (target - travelled) / segLen : 0
                return CGPoint(x: points[i - 1].x + (points[i].x - points[i - 1].x) * t,
                               y: points[i - 1].y + (points[i].y - points[i - 1].y) * t)
            }
            travelled += segLen
        }
        return points[points.count - 1]
    }

    /// Initial heading of a stroke as a unit vector — drives the demo arrow.
    public static func initialDirection(of points: [CGPoint]) -> Heading {
        guard points.count > 1 else { return Heading(dx: 0, dy: 1) }
        // Look a little way down the stroke so the arrow ignores tiny jitter.
        let target = StrokeMath.point(at: 0.12, along: points)
        let dx = target.x - points[0].x
        let dy = target.y - points[0].y
        let mag = hypot(dx, dy)
        guard mag > .ulpOfOne else { return Heading(dx: 0, dy: 1) }
        return Heading(dx: dx / mag, dy: dy / mag)
    }
}

// MARK: - Stroke builders

/// Tiny DSL for hand-authoring letter formation data compactly and readably.
/// All coordinates are unit-square (0...1, origin top-left).
public enum Pen {

    /// A straight line between two points.
    public static func line(_ from: CGPoint, _ to: CGPoint, cue: String) -> Stroke {
        Stroke(points: [from, to], cue: cue)
    }

    /// A polyline through an explicit ordered list of points.
    public static func path(_ pts: [CGPoint], cue: String) -> Stroke {
        Stroke(points: pts, cue: cue)
    }

    /// A circular arc, sampled into a smooth polyline.
    /// Angles in degrees, measured clockwise from 3 o'clock (screen coords,
    /// y-down), so a "magic c" runs from ~60° down to ~300° going counter-
    /// clockwise visually. `sweepClockwise` chooses the travel direction.
    public static func arc(center: CGPoint,
                           radius: CGFloat,
                           startDeg: CGFloat,
                           endDeg: CGFloat,
                           cue: String,
                           samples: Int = 24) -> Stroke {
        var pts: [CGPoint] = []
        let start = startDeg * .pi / 180
        let end = endDeg * .pi / 180
        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let a = start + (end - start) * t
            pts.append(CGPoint(x: center.x + radius * cos(a),
                               y: center.y + radius * sin(a)))
        }
        return Stroke(points: pts, cue: cue)
    }

    public static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
}
