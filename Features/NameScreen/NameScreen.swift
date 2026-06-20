//
//  NameScreen.swift
//  Features › NameScreen
//
//  Day one opens here. Jayden's own name, laid out as oversized guided
//  letters — the most motivating possible first word and the emotional hook.
//  Audio-first: a warm voice greets him; a big tap starts tracing.
//

import SwiftUI

struct NameScreen: View {
    let app: AppModel
    @State private var appeared = false

    private var name: Word { app.content.nameWord }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // The name as big, soft, guide-colored letters.
                HStack(spacing: 8) {
                    ForEach(Array(name.text.enumerated()), id: \.offset) { idx, ch in
                        Text(String(ch))
                            .font(.system(size: 150, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.guide)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(Theme.gentleSpring.delay(Double(idx) * 0.12), value: appeared)
                    }
                }

                // Spoken-first "start" affordance — a friendly pencil, no text
                // the child must read.
                Button {
                    app.startTracingName()
                } label: {
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(Theme.surface)
                        .padding(46)
                        .background(Circle().fill(Theme.accent))
                        .shadow(color: Theme.ink.opacity(0.12), radius: 12, y: 6)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .animation(Theme.gentleSpring.delay(Double(name.text.count) * 0.12 + 0.1), value: appeared)
                .accessibilityLabel("Write my name")

                Spacer()
            }
        }
        .overlay(alignment: .topTrailing) { ParentGateButton(app: app) }
        .onAppear {
            appeared = true
            app.greetOnName()
        }
    }
}
