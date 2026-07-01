//
//  TracingScreen.swift
//  Features › TracingCanvas
//
//  Hosts the single-letter canvas plus a calm row of the word's letters for
//  context (no reading required to operate — it's just a progress anchor).
//  Drives the view model's lifecycle and exposes the always-available
//  "just trace" escape hatch.
//

import SwiftUI

struct TracingScreen: View {
    let word: Word
    let app: AppModel

    @State private var vm: TracingViewModel

    init(word: Word, app: AppModel) {
        self.word = word
        self.app = app
        _vm = State(initialValue: TracingViewModel(
            word: word,
            forms: app.content.letterForms(for: word),
            validationEnabled: true,
            audio: app.audio,
            review: app.review,
            onWordComplete: { app.wordCompleted() }
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            StrokeCanvasView(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(Theme.surface)
                        .padding(24)
                )
        }
        .calmBackground()
        .overlay(alignment: .bottomTrailing) { freeTraceButton }
        .overlay(alignment: .topTrailing) { ParentGateButton(app: app) }
        .onAppear {
            vm.begin()
            if app.isAutopilot { vm.startAutopilot() }
        }
        .onDisappear { vm.cancel() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ForEach(Array(word.letters.enumerated()), id: \.offset) { idx, ch in
                Text(String(ch))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(color(for: idx))
                    .opacity(idx <= vm.letterIndex ? 1 : 0.35)
                    .scaleEffect(idx == vm.letterIndex ? 1.0 : 0.82)
                    .animation(Theme.gentleSpring, value: vm.letterIndex)
            }
        }
        .padding(.top, 28)
        .padding(.bottom, 4)
    }

    private func color(for index: Int) -> Color {
        if index < vm.letterIndex { return Theme.childInk }     // done
        if index == vm.letterIndex { return Theme.ink }         // current
        return Theme.inkSoft                                     // upcoming
    }

    private var freeTraceButton: some View {
        Button {
            app.openFreeTrace()
        } label: {
            Image(systemName: "scribble.variable")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .padding(20)
                .background(Circle().fill(Theme.accentSoft))
        }
        .padding(28)
        .accessibilityLabel("Just trace, no judging")
    }
}
