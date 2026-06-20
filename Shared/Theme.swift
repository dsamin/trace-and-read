//
//  Theme.swift
//  Shared
//
//  One calm visual style for the whole app: muted palette, soft transitions,
//  big targets. No bright "reward" colors, because there are no rewards to
//  celebrate loudly — the app is deliberately quiet.
//

import SwiftUI

enum Theme {

    // MARK: Palette — soft, low-saturation, easy on a small child's eyes.
    static let background = Color(red: 0.96, green: 0.95, blue: 0.91)   // warm paper
    static let surface    = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let ink        = Color(red: 0.27, green: 0.30, blue: 0.34)   // soft charcoal
    static let inkSoft    = Color(red: 0.55, green: 0.58, blue: 0.62)

    /// The guide / trace color — a calm dusty blue.
    static let guide      = Color(red: 0.55, green: 0.66, blue: 0.74)
    static let guideFaint = Color(red: 0.78, green: 0.84, blue: 0.88)

    /// The child's own ink as he traces — a gentle teal, never harsh black.
    static let childInk   = Color(red: 0.30, green: 0.52, blue: 0.55)

    /// The green start dot.
    static let startDot   = Color(red: 0.46, green: 0.70, blue: 0.52)

    /// A muted, friendly accent for pictures / chooser tiles.
    static let accent     = Color(red: 0.78, green: 0.66, blue: 0.55)
    static let accentSoft = Color(red: 0.90, green: 0.84, blue: 0.77)

    // MARK: Motion — everything soft, nothing snappy.
    static let softEase = Animation.easeInOut(duration: 0.6)
    static let gentleSpring = Animation.spring(response: 0.7, dampingFraction: 0.85)

    // MARK: Metrics
    static let strokeWidth: CGFloat = 26      // thick, finger-friendly
    static let guideWidth: CGFloat = 22
    static let startDotRadius: CGFloat = 26   // oversized target
    static let cornerRadius: CGFloat = 28
}

extension View {
    /// Standard calm screen background.
    func calmBackground() -> some View {
        self.background(Theme.background.ignoresSafeArea())
    }
}
