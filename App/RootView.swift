//
//  RootView.swift
//  App
//
//  Switches between the child-facing screens and the gated parent area based
//  on the AppModel's current screen. Transitions are soft fades — no hard cuts.
//

import SwiftUI

struct RootView: View {
    @State var app: AppModel

    var body: some View {
        ZStack {
            switch app.screen {
            case .name:
                NameScreen(app: app)
                    .transition(.opacity)
            case .wordChooser:
                WordChooserScreen(app: app)
                    .transition(.opacity)
            case .tracing:
                TracingScreen(word: app.currentWord, app: app)
                    .id(app.currentWord.id)            // fresh VM per word
                    .transition(.opacity)
            case .bridge:
                WriteThenReadScreen(word: app.currentWord, app: app)
                    .id(app.currentWord.id)
                    .transition(.opacity)
            case .freeTrace:
                FreeTraceScreen(word: app.currentWord, app: app)
                    .id("free-" + app.currentWord.id)
                    .transition(.opacity)
            case .parentArea:
                ParentAreaScreen(app: app)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(Theme.softEase, value: app.screen)
        .onAppear { app.beginAutopilotIfNeeded() }
    }
}
