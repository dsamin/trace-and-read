//
//  ParentGate.swift
//  Features › ParentGate
//
//  A deliberately child-proof entry to the settings area: press and HOLD,
//  then DRAG. A four-year-old won't stumble through both steps, but a parent
//  does it in a second. No text label that a child could be tempted by.
//

import SwiftUI

struct ParentGateButton: View {
    let app: AppModel
    @State private var holding = false
    @State private var dragProgress: CGFloat = 0   // 0...1

    private let holdDuration: TimeInterval = 1.1
    private let dragToOpen: CGFloat = 90

    var body: some View {
        Image(systemName: "gearshape")
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(Theme.inkSoft.opacity(holding ? 0.9 : 0.35))
            .padding(18)
            .background(
                Circle()
                    .fill(Theme.surface.opacity(holding ? 0.9 : 0.0))
                    .overlay(
                        Circle()
                            .trim(from: 0, to: dragProgress)
                            .stroke(Theme.startDot, lineWidth: 3)
                    )
            )
            .scaleEffect(holding ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: holding)
            .padding(20)
            .gesture(gateGesture)
            .accessibilityLabel("Grown-ups: press, hold, then drag")
    }

    private var gateGesture: some Gesture {
        LongPressGesture(minimumDuration: holdDuration)
            .onEnded { _ in holding = true }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                if case .second(true, let drag?) = value {
                    holding = true
                    dragProgress = min(1, abs(drag.translation.width) / dragToOpen)
                }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value,
                   abs(drag.translation.width) >= dragToOpen {
                    app.openParentArea()
                }
                holding = false
                dragProgress = 0
            }
    }
}
