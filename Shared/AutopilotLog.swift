//
//  AutopilotLog.swift
//  Shared
//
//  Tiny stdout marker logger used only by the `-autopilot` CI/UI-test run, so
//  the GitHub Actions macOS job can confirm the full core loop actually ran in
//  the simulator (it greps the launch console for these markers).
//

import Foundation

enum AutopilotLog {
    /// Print a marker and flush so it appears immediately on the launch console.
    static func mark(_ message: String) {
        print("AUTOPILOT \(message)")
        fflush(stdout)
    }
}
