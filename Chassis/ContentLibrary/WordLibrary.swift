//
//  WordLibrary.swift
//  Chassis › ContentLibrary
//
//  The tagged word / sound / picture database. CVC words, their letters,
//  the sounds to blend, and a picture reference. Pictures are referenced by
//  an SF Symbol name so the app is fully offline with zero image assets to
//  ship; a real art pack can replace these later without changing call sites.
//
//  CHASSIS RULE: Foundation only.
//

import Foundation

/// A word the child can write and then read.
public struct Word: Codable, Sendable, Identifiable {
    public let id: String          // the spelling, e.g. "sun"
    public let text: String
    /// Ordered sounds to blend at the write-then-read bridge, e.g. ["sss","uh","nnn"].
    public let phonemes: [String]
    /// Picture reference — an SF Symbol name (offline, no asset bundle needed).
    public let symbolName: String
    /// Spoken whole-word label for the picture chooser, e.g. "sun".
    public let spokenLabel: String
    /// Whether this is a person's name (drives the day-one anchor screen).
    public let isName: Bool

    public init(text: String,
                phonemes: [String],
                symbolName: String,
                spokenLabel: String? = nil,
                isName: Bool = false) {
        self.id = text
        self.text = text
        self.phonemes = phonemes
        self.symbolName = symbolName
        self.spokenLabel = spokenLabel ?? text
        self.isName = isName
    }

    /// The letters of the word, in order.
    public var letters: [Character] { Array(text) }
}

public enum WordLibrary {

    /// Day-one anchor: the single most motivating word a 4-year-old can write.
    public static let name = Word(
        text: "jayden",
        phonemes: ["juh", "aaa", "yuh", "duh", "eh", "nnn"],
        symbolName: "face.smiling",
        spokenLabel: "Jayden",
        isName: true
    )

    /// The starter CVC bank (~10 words). Every letter used here is authored in
    /// `LetterLibrary`. Symbols are all available on iPadOS 17.
    public static let cvcWords: [Word] = [
        Word(text: "cat", phonemes: ["kuh", "aaa", "tuh"], symbolName: "cat",            spokenLabel: "cat"),
        Word(text: "dog", phonemes: ["duh", "ah", "guh"],  symbolName: "dog",            spokenLabel: "dog"),
        Word(text: "sun", phonemes: ["sss", "uh", "nnn"],  symbolName: "sun.max.fill",   spokenLabel: "sun"),
        Word(text: "pig", phonemes: ["puh", "ih", "guh"],  symbolName: "pawprint.fill",  spokenLabel: "pig"),
        Word(text: "hat", phonemes: ["hhh", "aaa", "tuh"], symbolName: "graduationcap.fill", spokenLabel: "hat"),
        Word(text: "bed", phonemes: ["buh", "eh", "duh"],  symbolName: "bed.double.fill", spokenLabel: "bed"),
        Word(text: "cup", phonemes: ["kuh", "uh", "puh"],  symbolName: "cup.and.saucer.fill", spokenLabel: "cup"),
        Word(text: "fox", phonemes: ["fff", "ah", "ks"],   symbolName: "hare.fill",      spokenLabel: "fox"),
        Word(text: "net", phonemes: ["nnn", "eh", "tuh"],  symbolName: "fish.fill",      spokenLabel: "net"),
        Word(text: "bug", phonemes: ["buh", "uh", "guh"],  symbolName: "ladybug.fill",   spokenLabel: "bug")
    ]

    /// Everything writable: the name plus the CVC bank.
    public static var allWords: [Word] { [name] + cvcWords }

    public static func word(withText text: String) -> Word? {
        allWords.first { $0.text == text }
    }
}
