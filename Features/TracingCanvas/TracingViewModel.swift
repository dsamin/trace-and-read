//
//  TracingViewModel.swift
//  Features › TracingCanvas
//
//  Drives the LetterSchool-style 3-step fade for one word:
//      DEMO  →  GUIDED TRACE  →  FREE-WRITE FROM MEMORY
//  per letter, then signals the word is finished so the read bridge can fire.
//
//  The mandatory free-write (unscaffolded recall) is built in, not optional.
//  Everything is errorless: a miss re-models the stroke with an encouraging
//  voice line and lets him try again — never a buzzer, X, or fail screen.
//
//  In free-trace mode (`validationEnabled == false`) the demo and recall steps
//  are skipped and every stroke is accepted: "just trace, no judging".
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class TracingViewModel {

    enum Phase: Equatable {
        case demo            // hand + green dot + arrow + spoken cue
        case guidedTrace     // trace over the visible guide
        case freeWrite       // guide gone; write from memory (mandatory)
        case letterComplete  // brief calm beat; letter sound just played
        case wordComplete    // hand off to the read bridge
    }

    // Inputs
    let word: Word
    let forms: [LetterForm]
    let validationEnabled: Bool
    private let audio: AudioEngine
    private let review: ReviewService
    private let validator = StrokeValidator()
    private let onWordComplete: () -> Void

    // State (read by the view)
    private(set) var letterIndex = 0
    private(set) var strokeIndex = 0
    private(set) var phase: Phase = .demo
    private(set) var demoProgress: CGFloat = 0      // 0...1 along the demoed stroke
    private(set) var showHint = false               // free-write guide faded back in
    private(set) var lastFault: StrokeFault?        // for a brief re-model highlight
    /// The child's accepted ink for the current letter (one polyline per stroke).
    private(set) var inkStrokes: [[CGPoint]] = []

    // Timing knobs
    private let demoStrokeDuration: TimeInterval = 1.6
    private let interStrokePause: TimeInterval = 0.45
    private let stallSeconds: TimeInterval = 6.0

    private var demoTask: Task<Void, Never>?
    private var stallToken = 0

    init(word: Word,
         forms: [LetterForm],
         validationEnabled: Bool,
         audio: AudioEngine,
         review: ReviewService,
         onWordComplete: @escaping () -> Void) {
        self.word = word
        self.forms = forms
        self.validationEnabled = validationEnabled
        self.audio = audio
        self.review = review
        self.onWordComplete = onWordComplete
    }

    // MARK: Derived

    var currentForm: LetterForm? { forms.indices.contains(letterIndex) ? forms[letterIndex] : nil }
    var currentStroke: Stroke? {
        guard let f = currentForm, f.strokes.indices.contains(strokeIndex) else { return nil }
        return f.strokes[strokeIndex]
    }
    /// Whether the faint guide should be drawn under the finger right now.
    var showsGuide: Bool {
        switch phase {
        case .demo, .guidedTrace: return true
        case .freeWrite:          return showHint            // returns only on a stall
        case .letterComplete, .wordComplete: return false
        }
    }
    /// Whether the demo hand / start dot / arrow are visible.
    var showsDemoOverlay: Bool { phase == .demo }

    // MARK: Lifecycle

    func begin() {
        guard !forms.isEmpty else { onWordComplete(); return }
        if validationEnabled {
            startLetter()
        } else {
            // Free-trace: straight to a no-judging guided trace, guide always up.
            phase = .guidedTrace
            strokeIndex = 0
            inkStrokes = []
        }
    }

    func cancel() {
        demoTask?.cancel()
        stallToken += 1
    }

    // MARK: Per-letter

    private func startLetter() {
        strokeIndex = 0
        inkStrokes = []
        lastFault = nil
        phase = .demo
        runDemo(from: 0)
    }

    /// Animate the demo hand along each remaining stroke, speaking its cue.
    private func runDemo(from index: Int) {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            guard let self else { return }
            guard let form = self.currentForm else { return }
            for i in index..<form.strokes.count {
                if Task.isCancelled { return }
                self.strokeIndex = i
                self.demoProgress = 0
                self.audio.play(.cue(form.strokes[i].cue))
                let steps = 60
                for s in 0...steps {
                    if Task.isCancelled { return }
                    self.demoProgress = CGFloat(s) / CGFloat(steps)
                    try? await Task.sleep(for: .seconds(self.demoStrokeDuration / Double(steps)))
                }
                try? await Task.sleep(for: .seconds(self.interStrokePause))
            }
            if Task.isCancelled { return }
            // Demo done → hand it to the child to trace.
            self.strokeIndex = 0
            self.phase = .guidedTrace
        }
    }

    /// Re-model a single stroke after a miss (the errorless redo).
    private func reModel(stroke index: Int) {
        phase = .demo
        runDemoSingle(index: index)
    }

    private func runDemoSingle(index: Int) {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            guard let self, let form = self.currentForm,
                  form.strokes.indices.contains(index) else { return }
            self.strokeIndex = index
            self.demoProgress = 0
            self.audio.play(.cue(form.strokes[index].cue))
            let steps = 60
            for s in 0...steps {
                if Task.isCancelled { return }
                self.demoProgress = CGFloat(s) / CGFloat(steps)
                try? await Task.sleep(for: .seconds(self.demoStrokeDuration / Double(steps)))
            }
            if Task.isCancelled { return }
            self.lastFault = nil
            // Return to whichever practice phase we came from.
            self.phase = self.recallPhaseForCurrentLetter
            if self.phase == .freeWrite { self.armStallTimer() }
        }
    }

    /// During recall we may be in guided or free depending on progress; the
    /// re-model returns to free-write once the guided pass is complete.
    private var recallPhaseForCurrentLetter: Phase = .guidedTrace

    // MARK: Stroke submission (called by the canvas on finger-up)

    func submitStroke(_ points: [CGPoint]) {
        guard phase == .guidedTrace || phase == .freeWrite else { return }
        stallToken += 1            // any input clears the stall timer
        showHint = false

        guard validationEnabled else {
            acceptStroke(points, recordMastery: false)
            return
        }

        guard let stroke = currentStroke, let form = currentForm else { return }
        let mastery = review.masteryFraction(for: form.character)
        // Guided trace is forgiving by nature (the guide is visible); free-write
        // uses the mastery-tuned tolerance. Both flow through the same knobs.
        let tolerance: StrokeTolerance = (phase == .guidedTrace)
            ? StrokeTolerance.interpolated(mastery: min(mastery, 0.35))   // guided stays gentle
            : StrokeTolerance.interpolated(mastery: mastery)

        switch validator.validate(captured: points, against: stroke, tolerance: tolerance) {
        case .good:
            acceptStroke(points, recordMastery: phase == .freeWrite)
        case .retry(let fault):
            lastFault = fault
            audio.play(.encouragement(fault.encouragement))
            recallPhaseForCurrentLetter = phase
            reModel(stroke: strokeIndex)
        }
    }

    private func acceptStroke(_ points: [CGPoint], recordMastery: Bool) {
        inkStrokes.append(points)
        lastFault = nil

        guard let form = currentForm else { return }
        let isLastStroke = strokeIndex >= form.strokes.count - 1

        if !isLastStroke {
            strokeIndex += 1
            if phase == .freeWrite { armStallTimer() }
            return
        }

        // Last stroke of the letter just landed.
        if validationEnabled && phase == .guidedTrace {
            // Guided pass complete → mandatory unscaffolded recall.
            strokeIndex = 0
            inkStrokes = []
            phase = .freeWrite
            recallPhaseForCurrentLetter = .freeWrite
            armStallTimer()
            return
        }

        // Free-write complete (or free-trace mode): the letter is formed.
        completeLetter(recordSuccess: recordMastery)
    }

    private func completeLetter(recordSuccess: Bool) {
        guard let form = currentForm else { return }
        if recordSuccess {
            review.record(letter: form.character, success: true)
        }
        // Voice the SOUND, not the name.
        audio.play(.letterSound(form.sound))
        phase = .letterComplete

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.9))
            guard let self, !Task.isCancelled else { return }
            self.advanceLetter()
        }
    }

    private func advanceLetter() {
        let next = letterIndex + 1
        if next >= forms.count {
            phase = .wordComplete
            onWordComplete()
            return
        }
        letterIndex = next
        if validationEnabled {
            startLetter()
        } else {
            strokeIndex = 0
            inkStrokes = []
            phase = .guidedTrace
        }
    }

    // MARK: Stall handling — fade the guide back only if he gets stuck.

    private func armStallTimer() {
        guard validationEnabled else { return }
        stallToken += 1
        let token = stallToken
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.stallSeconds ?? 6))
            guard let self, token == self.stallToken, self.phase == .freeWrite else { return }
            self.showHint = true
            if let cue = self.currentStroke?.cue {
                self.audio.play(.cue(cue))
            }
        }
    }
}
