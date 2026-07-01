//
//  ParentAreaScreen.swift
//  Features › ParentGate
//
//  Settings behind the gate. Read-only-ish for the MVP: shows the mastery the
//  review service has recorded and the tolerance strategy, plus a left-handed
//  mirrored-demo toggle (deferred behavior, wired as a no-op placeholder) and
//  a way back. Nothing here is child-facing.
//

import SwiftUI

struct ParentAreaScreen: View {
    let app: AppModel
    @AppStorage("leftHandedDemo") private var leftHanded = false

    private var letters: [LetterForm] { app.content.lettersByFamily }

    var body: some View {
        NavigationStack {
            Form {
                Section("Practice") {
                    Toggle("Left-handed mirrored demo", isOn: $leftHanded)
                    LabeledContent("Words available", value: "\(app.content.allWords.count)")
                    LabeledContent("Letters authored", value: "\(letters.count)")
                }

                Section("Letter mastery") {
                    ForEach(letters) { form in
                        HStack {
                            Text(String(form.character))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .frame(width: 36)
                            Text(form.family.displayName)
                                .foregroundStyle(.secondary)
                            Spacer()
                            MasteryBar(fraction: app.review.masteryFraction(for: form.character))
                                .frame(width: 120, height: 10)
                        }
                    }
                }

                Section {
                    Text("Stroke tolerance starts very generous and tightens as each letter is mastered. There are no scores, streaks, or timers shown to the child.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Grown-up settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { app.closeParentArea() }
                }
            }
        }
    }
}

private struct MasteryBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.accentSoft)
                Capsule().fill(Theme.startDot)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, fraction))))
            }
        }
    }
}
