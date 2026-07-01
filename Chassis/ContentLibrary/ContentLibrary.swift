//
//  ContentLibrary.swift
//  Chassis › ContentLibrary
//
//  Facade over the tagged word / letter / sound / picture data. This is the
//  one type features talk to; the underlying tables (LetterLibrary,
//  WordLibrary) stay private implementation detail so the storage can change
//  (bundled JSON, SwiftData, a downloaded pack) without touching callers.
//
//  CHASSIS RULE: Foundation only. Lifts cleanly into LearningKit.
//

import Foundation

public struct ContentLibrary: Sendable {

    public init() {}

    // MARK: Words

    /// The day-one name anchor.
    public var nameWord: Word { WordLibrary.name }

    /// The CVC chooser bank.
    public var cvcWords: [Word] { WordLibrary.cvcWords }

    public var allWords: [Word] { WordLibrary.allWords }

    public func word(_ text: String) -> Word? { WordLibrary.word(withText: text) }

    // MARK: Letters

    /// Formation data for a character, or nil if not yet authored.
    public func letterForm(for character: Character) -> LetterForm? {
        LetterLibrary.form(for: character)
    }

    /// Formation data for every letter in a word, in order. Skips any
    /// unauthored character (there are none in the shipped bank, but this keeps
    /// the app crash-proof if the bank is extended before the letter is added).
    public func letterForms(for word: Word) -> [LetterForm] {
        word.letters.compactMap { LetterLibrary.form(for: $0) }
    }

    /// All authored letters in HWT stroke-family order.
    public var lettersByFamily: [LetterForm] { LetterLibrary.orderedByFamily }

    /// The spoken sound for a character ("sss"), or nil if unauthored.
    public func sound(for character: Character) -> String? {
        LetterLibrary.form(for: character)?.sound
    }
}
