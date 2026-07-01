// swift-tools-version:5.9
//
//  CoreVerification — a SwiftPM package that builds and TESTS the platform-
//  independent core of Trace & Read (the tagged content library + the
//  make-or-break stroke validator) on any platform, including Linux, where
//  the full SwiftUI/SwiftData/AVFoundation app cannot build.
//
//  The sources are symlinks to the real files under Chassis/ and Features/, so
//  there is a single source of truth shared with the Xcode app build. This is
//  exactly the "LearningKit"-shaped core the spec calls for: no app-specific,
//  no Apple-UI imports — just Foundation.
//
import PackageDescription

let package = Package(
    name: "LearningKit",
    products: [
        .library(name: "LearningKitCore", targets: ["LearningKitCore"]),
        .executable(name: "LoopDemo", targets: ["LoopDemo"])
    ],
    targets: [
        .target(name: "LearningKitCore"),
        .executableTarget(
            name: "LoopDemo",
            dependencies: ["LearningKitCore"]
        ),
        .testTarget(
            name: "LearningKitCoreTests",
            dependencies: ["LearningKitCore"]
        )
    ]
)
