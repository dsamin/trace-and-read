//
//  ParentGate.swift
//  Features › ParentGate
//
//  A deliberately child-proof entry to the settings area: press and HOLD,
//  then DRAG. A four-year-old won't stumble through both steps, but a parent
//  does it in a second. No text label that a child could be tempted by.
//
//  Implemented with LongPress.sequenced(before: Drag) + `.updating`/`.onEnded`
//  (the requirement-free gesture composition — avoids relying on the sequence
//  Value being Equatable, which `.onChanged` would need).
//

import SwiftUI

struct ParentGateButton: View {
    let app: AppModel
    /// True only while the long-press has completed and the drag is underway.
    @GestureState private var gateActive = false

    private let holdDuration: TimeInterval = 1.1
    private let dragToOpen: CGFloat = 90

    var body: some View {
        Image(systemName: "gearshape")
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(Theme.inkSoft.opacity(gateActive ? 0.9 : 0.35))
            .padding(18)
            .background(
                Circle().fill(Theme.surface.opacity(gateActive ? 0.9 : 0.0))
            )
            .scaleEffect(gateActive ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: gateActive)
            .padding(20)
            .gesture(gateGesture)
            .accessibilityLabel("Grown-ups: press, hold, then drag")
    }

    private var gateGesture: some Gesture {
        LongPressGesture(minimumDuration: holdDuration)
            .sequenced(before: DragGesture(minimumDistance: dragToOpen))
            .updating($gateActive) { value, state, _ in
                // The `.second` phase begins once the long-press has fired.
                if case .second(true, _) = value { state = true }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value,
                   abs(drag.translation.width) >= dragToOpen {
                    app.openParentArea()
                }
            }
    }
}
