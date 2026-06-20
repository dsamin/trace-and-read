//
//  WordChooserScreen.swift
//  Features › WordChooser
//
//  A spoken, picture-driven picker of CVC words. No reading required: each
//  tile is a picture; tapping it speaks the word, and a second tap (or tapping
//  the same tile again) begins writing it. The first tap is "hear it", so a
//  child can browse by sound before committing.
//

import SwiftUI

struct WordChooserScreen: View {
    let app: AppModel
    @State private var previewing: String?

    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 28)]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 28) {
                    ForEach(app.content.cvcWords) { word in
                        tile(for: word)
                    }
                }
                .padding(36)
            }
        }
        .overlay(alignment: .bottomTrailing) { freeTraceButton }
        .overlay(alignment: .topTrailing) { ParentGateButton(app: app) }
        .onAppear {
            // Audio-first prompt — what to do, spoken.
            app.audio.play(.cue("Pick a picture to write."))
        }
    }

    private func tile(for word: Word) -> some View {
        Button {
            if previewing == word.id {
                app.chooseWord(word)          // second tap → write it
            } else {
                previewing = word.id
                app.audio.play(.wholeWord(word.spokenLabel))   // first tap → hear it
            }
        } label: {
            VStack(spacing: 14) {
                Image(systemName: word.symbolName)
                    .font(.system(size: 78))
                    .foregroundStyle(Theme.accent)
                    .frame(height: 96)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Theme.surface)
                    .shadow(color: Theme.ink.opacity(0.08), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.startDot, lineWidth: previewing == word.id ? 4 : 0)
            )
            .scaleEffect(previewing == word.id ? 1.04 : 1.0)
            .animation(Theme.gentleSpring, value: previewing)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(word.spokenLabel)
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
