//
//  AudioClip.swift
//  Chassis › AudioEngine
//
//  A clip is identified by a name (used to find a bundled human-voice file)
//  and always carries `spokenText` as a fallback. During development there are
//  no recordings, so the synthesizer reads `spokenText`; later, dropping a file
//  named `<name>.m4a` into the Audio bundle makes the engine prefer it — with
//  no change to any call site.
//
//  CHASSIS RULE: Foundation only.
//

import Foundation

public struct AudioClip: Sendable, Equatable {
    /// File stem to look for in the bundle, e.g. "cue_big_line_down".
    public let name: String
    /// What the warm voice says — also the synthesizer fallback text.
    public let spokenText: String
    /// A short, calm pause to leave after this clip (seconds). Used to pace
    /// the write-then-read blend so sounds don't run together.
    public let trailingPause: TimeInterval

    public init(name: String, spokenText: String, trailingPause: TimeInterval = 0) {
        self.name = name
        self.spokenText = spokenText
        self.trailingPause = trailingPause
    }

    // MARK: Convenience factories for the loop

    /// A spoken instruction cue, e.g. the demo stroke direction.
    public static func cue(_ text: String) -> AudioClip {
        AudioClip(name: "cue_" + slug(text), spokenText: text)
    }

    /// A single letter sound, e.g. "sss" (never the letter name).
    public static func letterSound(_ sound: String) -> AudioClip {
        AudioClip(name: "snd_" + slug(sound), spokenText: sound, trailingPause: 0.15)
    }

    /// An encouraging, never-failing redo line.
    public static func encouragement(_ text: String) -> AudioClip {
        AudioClip(name: "enc_" + slug(text), spokenText: text)
    }

    /// A whole spoken word, e.g. the picture-chooser label or the bridge reveal.
    public static func wholeWord(_ text: String) -> AudioClip {
        AudioClip(name: "word_" + slug(text), spokenText: text, trailingPause: 0.2)
    }

    private static func slug(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}
