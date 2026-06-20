//
//  AppModel.swift
//  App
//
//  Top-level coordinator: owns the three chassis engines and the current
//  screen. Features read what they need from here and call back to advance the
//  flow. Kept deliberately small — the interesting logic lives in the engines
//  and the tracing view model.
//

import Foundation
import SwiftUI
import SwiftData

/// The child-facing screens, plus the gated parent area.
enum Screen: Equatable {
    case name           // day-one anchor: Jayden's name
    case wordChooser    // spoken, picture-based CVC picker
    case tracing        // the 3-step fade canvas for `currentWord`
    case bridge         // write-then-read blend + picture reveal
    case freeTrace      // "just trace, no judging"
    case parentArea     // behind the parent gate
}

@Observable
final class AppModel {

    // Chassis engines.
    let content = ContentLibrary()
    let audio: AudioEngine
    let review: ReviewService

    // Navigation.
    private(set) var screen: Screen = .name
    /// The word currently being traced / read.
    private(set) var currentWord: Word

    /// Where to return after the free-trace detour.
    private var screenBeforeFreeTrace: Screen = .name

    init(audio: AudioEngine, review: ReviewService) {
        self.audio = audio
        self.review = review
        self.currentWord = WordLibrary.name
    }

    // MARK: Flow

    /// Day one opens here. Speak a warm greeting once the view appears.
    func greetOnName() {
        audio.play(.wholeWord(currentWord.spokenLabel))
    }

    /// Begin tracing the name (from the name anchor screen).
    func startTracingName() {
        currentWord = WordLibrary.name
        go(.tracing)
    }

    /// Move from the name to picking a CVC word.
    func showWordChooser() {
        go(.wordChooser)
    }

    /// Child tapped a picture in the chooser.
    func chooseWord(_ word: Word) {
        currentWord = word
        go(.tracing)
    }

    /// All letters of `currentWord` were written — fire the read bridge.
    func wordCompleted() {
        go(.bridge)
    }

    /// The bridge finished its blend-and-reveal; back to choosing.
    func bridgeFinished() {
        go(.wordChooser)
    }

    // MARK: Free trace (always one tap away)

    func openFreeTrace() {
        screenBeforeFreeTrace = screen
        go(.freeTrace)
    }

    func closeFreeTrace() {
        go(screenBeforeFreeTrace)
    }

    // MARK: Parent area (behind the gate)

    func openParentArea() { go(.parentArea) }
    func closeParentArea() { go(.name) }

    // MARK: -

    private func go(_ destination: Screen) {
        audio.stop()
        withAnimation(Theme.softEase) { screen = destination }
    }
}
