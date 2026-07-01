//
//  LetterLibrary.swift
//  Chassis › ContentLibrary
//
//  Hand-authored lowercase letter formation data, grouped by Handwriting-
//  Without-Tears stroke family. Coordinates are unit-square (0...1, top-left
//  origin, y-down). Each letter lists its strokes in the order they must be
//  written, and each stroke's point order encodes its direction.
//
//  Only the letters needed by Jayden's name and the starter CVC word bank are
//  authored here; the structure is data-driven, so adding letters later means
//  adding entries, not touching code.
//
//  CHASSIS RULE: Foundation / CoreGraphics only.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics   // On Apple platforms; on Linux CGPoint/CGFloat come from Foundation.
#endif

public enum LetterLibrary {

    /// All authored letters, keyed by character.
    public static let all: [Character: LetterForm] = {
        // Local helper so the compact `p(x, y)` calls below resolve cleanly
        // inside this static initializer.
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

        var forms: [LetterForm] = []

        // ---- VERTICAL family: "big line down" first ----------------------

        // i — line down, then a dot.
        forms.append(LetterForm(character: "i", family: .vertical, sound: "ih", strokes: [
            Pen.line(p(0.5, 0.30), p(0.5, 0.80), cue: "Big line down."),
            Pen.line(p(0.5, 0.14), p(0.5, 0.18), cue: "Little dot on top.")
        ]))

        // t — line down, then a little line across.
        forms.append(LetterForm(character: "t", family: .vertical, sound: "tuh", strokes: [
            Pen.line(p(0.5, 0.14), p(0.5, 0.82), cue: "Big line down."),
            Pen.line(p(0.34, 0.40), p(0.66, 0.40), cue: "Little line across.")
        ]))

        // l — one big line down.
        forms.append(LetterForm(character: "l", family: .vertical, sound: "lll", strokes: [
            Pen.line(p(0.5, 0.14), p(0.5, 0.82), cue: "Big line down.")
        ]))

        // n — line down, up over the hill, down.
        forms.append(LetterForm(character: "n", family: .vertical, sound: "nnn", strokes: [
            Pen.path([p(0.34, 0.34), p(0.34, 0.80)], cue: "Big line down."),
            Pen.path([p(0.34, 0.46), p(0.40, 0.36), p(0.52, 0.34),
                    p(0.64, 0.40), p(0.66, 0.52), p(0.66, 0.80)],
                   cue: "Up, over the hill, and down.")
        ]))

        // h — tall line down, then over the hill and down.
        forms.append(LetterForm(character: "h", family: .vertical, sound: "hhh", strokes: [
            Pen.line(p(0.34, 0.14), p(0.34, 0.80), cue: "Big tall line down."),
            Pen.path([p(0.34, 0.50), p(0.42, 0.40), p(0.54, 0.38),
                    p(0.64, 0.46), p(0.66, 0.58), p(0.66, 0.80)],
                   cue: "Up a bit, over the hill, and down.")
        ]))

        // b — tall line down, then a tummy that curves around.
        forms.append(LetterForm(character: "b", family: .vertical, sound: "buh", strokes: [
            Pen.line(p(0.34, 0.14), p(0.34, 0.80), cue: "Big tall line down."),
            Pen.path([p(0.34, 0.52), p(0.46, 0.44), p(0.60, 0.48),
                    p(0.66, 0.62), p(0.60, 0.76), p(0.46, 0.80), p(0.34, 0.74)],
                   cue: "Around to make a tummy.")
        ]))

        // p — line down low, then a tummy at the top.
        forms.append(LetterForm(character: "p", family: .vertical, sound: "puh", strokes: [
            Pen.line(p(0.34, 0.34), p(0.34, 0.96), cue: "Big line down, way past the bottom."),
            Pen.path([p(0.34, 0.40), p(0.46, 0.34), p(0.60, 0.38),
                    p(0.66, 0.50), p(0.60, 0.62), p(0.46, 0.66), p(0.34, 0.60)],
                   cue: "Around to make a tummy.")
        ]))

        // j — hook down below, then a dot.
        forms.append(LetterForm(character: "j", family: .vertical, sound: "juh", strokes: [
            Pen.path([p(0.54, 0.30), p(0.54, 0.84), p(0.50, 0.94),
                    p(0.40, 0.96), p(0.32, 0.90)],
                   cue: "Big line down, then a little hook."),
            Pen.line(p(0.54, 0.14), p(0.54, 0.18), cue: "Little dot on top.")
        ]))

        // ---- MAGIC-C family: curves that start like a c -----------------

        // c — one open magic-c curve.
        forms.append(LetterForm(character: "c", family: .magicC, sound: "kuh", strokes: [
            Pen.arc(center: p(0.50, 0.57), radius: 0.23, startDeg: 55, endDeg: 305,
                  cue: "Magic c. Start up high and curve around.")
        ]))

        // o — a full circle that closes back at the top.
        forms.append(LetterForm(character: "o", family: .magicC, sound: "ah", strokes: [
            Pen.arc(center: p(0.50, 0.57), radius: 0.23, startDeg: 300, endDeg: 660,
                  cue: "Magic c, then close it up into an o.")
        ]))

        // a — magic c, then a line down and a little tail.
        forms.append(LetterForm(character: "a", family: .magicC, sound: "aaa", strokes: [
            Pen.arc(center: p(0.50, 0.57), radius: 0.22, startDeg: 55, endDeg: 300,
                  cue: "Magic c."),
            Pen.path([p(0.71, 0.36), p(0.71, 0.80), p(0.78, 0.84)],
                   cue: "Line down and a little tail.")
        ]))

        // d — magic c, then a tall line down beside it.
        forms.append(LetterForm(character: "d", family: .magicC, sound: "duh", strokes: [
            Pen.arc(center: p(0.46, 0.57), radius: 0.22, startDeg: 55, endDeg: 300,
                  cue: "Magic c."),
            Pen.line(p(0.67, 0.14), p(0.67, 0.82), cue: "Big tall line down.")
        ]))

        // g — magic c, then a line down with a hook below.
        forms.append(LetterForm(character: "g", family: .magicC, sound: "guh", strokes: [
            Pen.arc(center: p(0.50, 0.57), radius: 0.22, startDeg: 55, endDeg: 300,
                  cue: "Magic c."),
            Pen.path([p(0.71, 0.36), p(0.71, 0.88), p(0.64, 0.96), p(0.52, 0.96), p(0.46, 0.90)],
                   cue: "Line down and a hook under the line.")
        ]))

        // s — a curvy snake.
        forms.append(LetterForm(character: "s", family: .magicC, sound: "sss", strokes: [
            Pen.path([p(0.66, 0.40), p(0.54, 0.34), p(0.42, 0.38), p(0.40, 0.48),
                    p(0.50, 0.56), p(0.60, 0.62), p(0.60, 0.74), p(0.48, 0.80),
                    p(0.36, 0.76)],
                   cue: "Curve like a snake.")
        ]))

        // e — little line across, then around like a c.
        forms.append(LetterForm(character: "e", family: .magicC, sound: "eh", strokes: [
            Pen.path([p(0.32, 0.58), p(0.68, 0.58), p(0.66, 0.45), p(0.50, 0.38),
                    p(0.34, 0.46), p(0.30, 0.62), p(0.40, 0.78), p(0.58, 0.80), p(0.68, 0.72)],
                   cue: "Little line across, then around.")
        ]))

        // f — curve over the top, big line down, little line across.
        forms.append(LetterForm(character: "f", family: .magicC, sound: "fff", strokes: [
            Pen.path([p(0.64, 0.24), p(0.52, 0.16), p(0.42, 0.22), p(0.40, 0.36), p(0.40, 0.82)],
                   cue: "Curve over and a big line down."),
            Pen.line(p(0.28, 0.46), p(0.56, 0.46), cue: "Little line across.")
        ]))

        // ---- DIAGONAL family: slants ------------------------------------

        // v — down-slant, up-slant.
        forms.append(LetterForm(character: "v", family: .diagonal, sound: "vvv", strokes: [
            Pen.path([p(0.32, 0.36), p(0.50, 0.80), p(0.68, 0.36)],
                   cue: "Slant down, then slant up.")
        ]))

        // w — two valleys.
        forms.append(LetterForm(character: "w", family: .diagonal, sound: "wuh", strokes: [
            Pen.path([p(0.26, 0.36), p(0.38, 0.80), p(0.50, 0.50),
                    p(0.62, 0.80), p(0.74, 0.36)],
                   cue: "Down, up, down, up.")
        ]))

        // x — one slant, then the other.
        forms.append(LetterForm(character: "x", family: .diagonal, sound: "ks", strokes: [
            Pen.line(p(0.32, 0.36), p(0.68, 0.80), cue: "Slant down this way."),
            Pen.line(p(0.68, 0.36), p(0.32, 0.80), cue: "Slant down the other way.")
        ]))

        // y — down-slant, then a long slant with a tail.
        forms.append(LetterForm(character: "y", family: .diagonal, sound: "yuh", strokes: [
            Pen.path([p(0.34, 0.36), p(0.50, 0.66)], cue: "Slant down to the middle."),
            Pen.path([p(0.68, 0.36), p(0.50, 0.66), p(0.40, 0.90), p(0.30, 0.96), p(0.24, 0.92)],
                   cue: "Long slant down with a tail.")
        ]))

        // u — down, around the bottom, up, then down.
        forms.append(LetterForm(character: "u", family: .diagonal, sound: "uh", strokes: [
            Pen.path([p(0.34, 0.36), p(0.34, 0.66), p(0.40, 0.78), p(0.52, 0.80),
                    p(0.64, 0.72), p(0.66, 0.58), p(0.66, 0.36)],
                   cue: "Down, around the bottom, and up."),
            Pen.line(p(0.66, 0.36), p(0.66, 0.80), cue: "Little line back down.")
        ]))

        // k — tall line, then two slants meeting it.
        forms.append(LetterForm(character: "k", family: .diagonal, sound: "kuh", strokes: [
            Pen.line(p(0.34, 0.14), p(0.34, 0.80), cue: "Big tall line down."),
            Pen.line(p(0.66, 0.40), p(0.34, 0.60), cue: "Slant in to the line."),
            Pen.line(p(0.42, 0.55), p(0.66, 0.80), cue: "Slant back out.")
        ]))

        // m — line down, then two hills.
        forms.append(LetterForm(character: "m", family: .vertical, sound: "mmm", strokes: [
            Pen.line(p(0.26, 0.34), p(0.26, 0.80), cue: "Big line down."),
            Pen.path([p(0.26, 0.44), p(0.34, 0.36), p(0.44, 0.36), p(0.50, 0.46), p(0.50, 0.80)],
                   cue: "Up, over the hill, and down."),
            Pen.path([p(0.50, 0.46), p(0.58, 0.36), p(0.68, 0.36), p(0.74, 0.46), p(0.74, 0.80)],
                   cue: "Up, over the next hill, and down.")
        ]))

        // r — line down, then a little shoulder.
        forms.append(LetterForm(character: "r", family: .vertical, sound: "rrr", strokes: [
            Pen.line(p(0.38, 0.34), p(0.38, 0.80), cue: "Big line down."),
            Pen.path([p(0.38, 0.46), p(0.46, 0.37), p(0.58, 0.36), p(0.66, 0.42)],
                   cue: "Up and a little shoulder.")
        ]))

        return Dictionary(uniqueKeysWithValues: forms.map { ($0.character, $0) })
    }()

    /// Look up a letter's formation. Returns nil for an unauthored character.
    public static func form(for character: Character) -> LetterForm? {
        all[Character(character.lowercased())]
    }

    /// Letters present in the library, ordered by HWT stroke family so a
    /// "learn the letters" surface can present them in motor-pattern order.
    public static var orderedByFamily: [LetterForm] {
        StrokeFamily.allCases.flatMap { family in
            all.values.filter { $0.family == family }.sorted { $0.id < $1.id }
        }
    }
}
