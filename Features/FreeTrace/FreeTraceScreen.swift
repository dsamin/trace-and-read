//
//  FreeTraceScreen.swift
//  Features › FreeTrace
//
//  "Just trace, no judging." The same canvas with validation turned fully off
//  and an even calmer tone — for a tired day. The guide stays visible, every
//  stroke is accepted, nothing is scored, and a close button is always there.
//

import SwiftUI

struct FreeTraceScreen: View {
    let word: Word
    let app: AppModel

    @State private var vm: TracingViewModel

    init(word: Word, app: AppModel) {
        self.word = word
        self.app = app
        _vm = State(initialValue: TracingViewModel(
            word: word,
            forms: app.content.letterForms(for: word),
            validationEnabled: false,
            audio: app.audio,
            review: app.review,
            onWordComplete: { app.closeFreeTrace() }
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            StrokeCanvasView(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(Theme.surface)
                        .padding(24)
                )
        }
        .calmBackground()
        .overlay(alignment: .topLeading) {
            Button {
                app.closeFreeTrace()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .padding(20)
                    .background(Circle().fill(Theme.accentSoft))
            }
            .padding(24)
            .accessibilityLabel("Go back")
        }
        .onAppear { vm.begin() }
        .onDisappear { vm.cancel() }
    }
}
