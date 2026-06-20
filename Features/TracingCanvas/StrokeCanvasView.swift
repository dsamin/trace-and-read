//
//  StrokeCanvasView.swift
//  Features › TracingCanvas
//
//  The big, finger-first drawing surface for one letter. Renders the faint
//  guide, the demo hand + green start dot + direction arrow, and the child's
//  own ink, then captures finger strokes and hands them to the view model in
//  unit-square coordinates.
//
//  Uses a SwiftUI Canvas + DragGesture (Core Graphics path-matching, no
//  PencilKit dependency) so stroke order and direction are fully under our
//  control — exactly what the validator needs.
//

import SwiftUI
import Foundation   // cos / sin / atan2 used by the demo arrow

/// Maps the unit square (0...1) onto a centered square region of a view rect.
private struct CanvasMapper {
    let rect: CGRect
    init(size: CGSize, inset: CGFloat = 0.10) {
        let side = min(size.width, size.height) * (1 - inset * 2)
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        rect = CGRect(origin: origin, size: CGSize(width: side, height: side))
    }
    func toView(_ p: CGPoint) -> CGPoint {
        CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
    }
    func toUnit(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - rect.minX) / rect.width, y: (p.y - rect.minY) / rect.height)
    }
}

struct StrokeCanvasView: View {
    @Bindable var vm: TracingViewModel
    /// Live points of the in-progress finger stroke, in view coordinates.
    @State private var liveViewPoints: [CGPoint] = []

    var body: some View {
        GeometryReader { geo in
            let mapper = CanvasMapper(size: geo.size)

            // Establish @Observable dependencies HERE, in body. Reads that
            // happen only inside the Canvas renderer closure (below) run after
            // body evaluation and would not register, so the canvas would not
            // redraw as the demo hand moves. Touching them here fixes that.
            let _ = (vm.demoProgress, vm.strokeIndex, vm.letterIndex,
                     vm.phase, vm.showHint, vm.inkStrokes.count)

            ZStack {
                Canvas { ctx, _ in
                    drawGuide(in: ctx, mapper: mapper)
                    drawInk(in: ctx, mapper: mapper)
                    drawLiveStroke(in: ctx)
                    drawDemoOverlay(in: ctx, mapper: mapper)
                }
                .animation(Theme.softEase, value: vm.phase)
                .animation(.easeInOut(duration: 0.2), value: vm.showHint)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        liveViewPoints.append(value.location)
                    }
                    .onEnded { _ in
                        let unit = liveViewPoints.map { mapper.toUnit($0) }
                        liveViewPoints = []
                        guard unit.count >= 1 else { return }
                        vm.submitStroke(unit)
                    }
            )
        }
    }

    // MARK: Drawing

    private func drawGuide(in ctx: GraphicsContext, mapper: CanvasMapper) {
        guard vm.showsGuide, let form = vm.currentForm else { return }
        for (i, stroke) in form.strokes.enumerated() {
            var path = Path()
            let pts = stroke.points.map { mapper.toView($0) }
            guard let first = pts.first else { continue }
            path.move(to: first)
            for p in pts.dropFirst() { path.addLine(to: p) }

            let isCurrent = (i == vm.strokeIndex)
            let color = isCurrent ? Theme.guide : Theme.guideFaint
            ctx.stroke(path, with: .color(color.opacity(isCurrent ? 0.8 : 0.45)),
                       style: StrokeStyle(lineWidth: Theme.guideWidth, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawInk(in ctx: GraphicsContext, mapper: CanvasMapper) {
        for stroke in vm.inkStrokes {
            var path = Path()
            let pts = stroke.map { mapper.toView($0) }
            guard let first = pts.first else { continue }
            path.move(to: first)
            for p in pts.dropFirst() { path.addLine(to: p) }
            ctx.stroke(path, with: .color(Theme.childInk),
                       style: StrokeStyle(lineWidth: Theme.strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawLiveStroke(in ctx: GraphicsContext) {
        guard liveViewPoints.count > 1 else { return }
        var path = Path()
        path.move(to: liveViewPoints[0])
        for p in liveViewPoints.dropFirst() { path.addLine(to: p) }
        ctx.stroke(path, with: .color(Theme.childInk),
                   style: StrokeStyle(lineWidth: Theme.strokeWidth, lineCap: .round, lineJoin: .round))
    }

    private func drawDemoOverlay(in ctx: GraphicsContext, mapper: CanvasMapper) {
        guard let stroke = vm.currentStroke else { return }

        // Green start dot (oversized target) — shown in demo and at the start
        // of a guided/free stroke so he knows where to begin.
        if vm.showsDemoOverlay || vm.phase == .guidedTrace {
            let start = mapper.toView(stroke.start)
            let r = Theme.startDotRadius
            let dot = Path(ellipseIn: CGRect(x: start.x - r, y: start.y - r, width: r * 2, height: r * 2))
            ctx.fill(dot, with: .color(Theme.startDot.opacity(0.9)))
        }

        guard vm.showsDemoOverlay else { return }

        // Direction arrow at the start, pointing the way the stroke travels.
        let dir = StrokeMath.initialDirection(of: stroke.points)
        let start = mapper.toView(stroke.start)
        drawArrow(in: ctx, at: start, direction: dir, length: 56)

        // The demo "fingertip" travelling along the stroke.
        let pos = mapper.toView(StrokeMath.point(at: vm.demoProgress, along: stroke.points))
        let r: CGFloat = 22
        let finger = Path(ellipseIn: CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2))
        ctx.fill(finger, with: .color(Theme.ink.opacity(0.30)))
        let r2: CGFloat = 12
        let inner = Path(ellipseIn: CGRect(x: pos.x - r2, y: pos.y - r2, width: r2 * 2, height: r2 * 2))
        ctx.fill(inner, with: .color(Theme.ink.opacity(0.55)))
    }

    private func drawArrow(in ctx: GraphicsContext, at origin: CGPoint, direction: Heading, length: CGFloat) {
        let tip = CGPoint(x: origin.x + direction.dx * length, y: origin.y + direction.dy * length)
        var shaft = Path()
        shaft.move(to: origin)
        shaft.addLine(to: tip)
        ctx.stroke(shaft, with: .color(Theme.startDot.opacity(0.8)),
                   style: StrokeStyle(lineWidth: 8, lineCap: .round))

        // Arrowhead.
        let angle = atan2(direction.dy, direction.dx)
        let wing: CGFloat = 16
        let a1 = angle + .pi * 0.82
        let a2 = angle - .pi * 0.82
        var head = Path()
        head.move(to: tip)
        head.addLine(to: CGPoint(x: tip.x + cos(a1) * wing, y: tip.y + sin(a1) * wing))
        head.move(to: tip)
        head.addLine(to: CGPoint(x: tip.x + cos(a2) * wing, y: tip.y + sin(a2) * wing))
        ctx.stroke(head, with: .color(Theme.startDot.opacity(0.8)),
                   style: StrokeStyle(lineWidth: 8, lineCap: .round))
    }
}
