//
//  TraceAndReadApp.swift
//  App
//
//  @main entry. Builds the SwiftData container, wires the three chassis
//  engines into the AppModel, locks the experience to landscape, and shows the
//  day-one name screen.
//

import SwiftUI
import SwiftData

@main
struct TraceAndReadApp: App {

    /// Persistence for letter mastery (the only persisted model).
    let container: ModelContainer
    @State private var app: AppModel

    init() {
        do {
            container = try ModelContainer(for: LetterMastery.self)
        } catch {
            // A fresh in-memory store is an acceptable fallback for a single-
            // child, no-account app — we never want a launch failure.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: LetterMastery.self, configurations: config)
        }
        let review = ReviewService(context: container.mainContext)
        let audio = SystemAudioEngine()
        // CI / UI-test hook: `-autopilot` drives the real loop with synthetic
        // strokes so the simulator run can prove the whole flow end to end.
        let autopilot = ProcessInfo.processInfo.arguments.contains("-autopilot")
        _app = State(initialValue: AppModel(audio: audio, review: review, isAutopilot: autopilot))
    }

    var body: some Scene {
        WindowGroup {
            RootView(app: app)
                .modelContainer(container)
                .preferredColorScheme(.light)        // calm, paper-like, always
                .persistentSystemOverlays(.hidden)
        }
    }
}
