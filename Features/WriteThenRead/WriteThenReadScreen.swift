//
//  WriteThenReadScreen.swift
//  Features › WriteThenRead
//
//  The payoff. The letters he just wrote slide together into the whole word,
//  the voice blends the sounds *with* him ("s-u-n … sun!"), and the picture
//  appears. Writing the word becomes reading it. This is the core pedagogical
//  bet of the app, so it gets a calm, unhurried beat — no confetti.
//

import SwiftUI

struct WriteThenReadScreen: View {
    let word: Word
    let app: AppModel

    @State private var blended = false       // letters pulled together
    @State private var highlight = -1        // which letter is sounding now
    @State private var revealed = false      // picture shown

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 56) {
                Spacer()

                // The word — letters spaced out, then blended together.
                HStack(spacing: blended ? 2 : 26) {
                    ForEach(Array(word.text.enumerated()), id: \.offset) { idx, ch in
                        Text(String(ch))
                            .font(.system(size: 132, weight: .bold, design: .rounded))
                            .foregroundStyle(idx == highlight ? Theme.accent : Theme.childInk)
                            .scaleEffect(idx == highlight ? 1.18 : 1.0)
                            .animation(.easeInOut(duration: 0.28), value: highlight)
                    }
                }
                .animation(Theme.gentleSpring, value: blended)

                // The picture reveal.
                Image(systemName: word.symbolName)
                    .font(.system(size: 150))
                    .foregroundStyle(Theme.accent)
                    .opacity(revealed ? 1 : 0)
                    .scaleEffect(revealed ? 1 : 0.7)
                    .animation(Theme.gentleSpring, value: revealed)
                    .frame(height: 180)

                Spacer()

                // Gentle continue — appears only after the reveal.
                if revealed {
                    Button {
                        app.bridgeFinished()
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Theme.surface)
                            .padding(34)
                            .background(Circle().fill(Theme.accent))
                    }
                    .transition(.opacity)
                    .padding(.bottom, 40)
                    .accessibilityLabel("Next")
                }
            }
        }
        .overlay(alignment: .topTrailing) { ParentGateButton(app: app) }
        .task { await runBridge() }
    }

    @MainActor
    private func runBridge() async {
        // 1) Sound each letter in turn, highlighting it as it plays.
        try? await Task.sleep(for: .seconds(0.5))
        for (idx, sound) in word.phonemes.enumerated() {
            highlight = idx
            app.audio.play(.letterSound(sound))
            try? await Task.sleep(for: .seconds(0.7))
        }
        highlight = -1

        // 2) Pull the letters together into the whole word.
        withAnimation(Theme.gentleSpring) { blended = true }
        try? await Task.sleep(for: .seconds(0.5))

        // 3) Blend aloud and reveal the picture together.
        app.audio.play(.wholeWord(word.spokenLabel))
        withAnimation(Theme.gentleSpring) { revealed = true }
    }
}
