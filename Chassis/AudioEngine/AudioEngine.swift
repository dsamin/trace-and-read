//
//  AudioEngine.swift
//  Chassis › AudioEngine
//
//  One play-clip API. The concrete engine prefers a bundled human-voice
//  recording (AVAudioPlayer) and falls back to AVSpeechSynthesizer when no
//  recording exists — so the entire spoken loop is testable today with zero
//  recordings, and real voice can be dropped in later without touching callers.
//
//  CHASSIS RULE: Foundation / AVFoundation only.
//

import Foundation
import AVFoundation

/// The surface every feature uses. Intentionally tiny.
public protocol AudioEngine: AnyObject {
    /// Speak / play one clip. Interrupts whatever is currently playing.
    func play(_ clip: AudioClip)
    /// Play clips back-to-back, honoring each clip's trailingPause. Used for
    /// the write-then-read blend ("s-u-n … sun!").
    func playSequence(_ clips: [AudioClip])
    /// Stop everything immediately (e.g. when leaving a screen).
    func stop()
}

/// Production engine. Records-first, synthesizer-fallback.
public final class SystemAudioEngine: NSObject, AudioEngine, AVSpeechSynthesizerDelegate {

    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    /// Pending synthesized clips, so trailingPause can pace a sequence.
    private var pauseAfterCurrentUtterance: TimeInterval = 0

    /// Voice tuning kept gentle and slow for a 4-year-old.
    public var speechRate: Float = 0.42        // AVSpeechUtteranceDefaultSpeechRate ≈ 0.5
    public var speechPitch: Float = 1.05

    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
        super.init()
        synthesizer.delegate = self
        configureSession()
    }

    private func configureSession() {
        #if os(iOS)
        // Calm, mixes politely; playback category so it works on silent switch.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        #endif
    }

    // MARK: AudioEngine

    public func play(_ clip: AudioClip) {
        stop()
        if playRecording(named: clip.name) { return }
        speak(clip.spokenText, pauseAfter: clip.trailingPause)
    }

    public func playSequence(_ clips: [AudioClip]) {
        stop()
        guard !clips.isEmpty else { return }
        // If every clip has a recording we could chain players, but the common
        // dev path is synthesis: enqueue utterances, which the synthesizer
        // plays in order, inserting each clip's pause as post-utterance delay.
        for clip in clips {
            if hasRecording(named: clip.name) {
                // Fall back to synthesis for mixed sequences to keep ordering
                // simple and deterministic during development.
            }
            enqueueSpeech(clip.spokenText, pauseAfter: clip.trailingPause)
        }
    }

    public func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        player?.stop()
        player = nil
    }

    // MARK: Recording backend

    private func hasRecording(named name: String) -> Bool {
        recordingURL(named: name) != nil
    }

    private func recordingURL(named name: String) -> URL? {
        for ext in ["m4a", "caf", "wav", "aiff"] {
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Audio")
                ?? bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    @discardableResult
    private func playRecording(named name: String) -> Bool {
        guard let url = recordingURL(named: name) else { return false }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            return true
        } catch {
            return false
        }
    }

    // MARK: Synthesizer backend (placeholder voice)

    private func speak(_ text: String, pauseAfter: TimeInterval) {
        enqueueSpeech(text, pauseAfter: pauseAfter)
    }

    private func enqueueSpeech(_ text: String, pauseAfter: TimeInterval) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.postUtteranceDelay = pauseAfter
        utterance.voice = preferredVoice()
        synthesizer.speak(utterance)
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        // Prefer an enhanced en-US voice when present; otherwise default.
        if let enhanced = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.hasPrefix("en") && $0.quality == .enhanced
        }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }
}

/// A no-op engine for previews and unit tests — speaks to the console only.
public final class SilentAudioEngine: AudioEngine {
    public init() {}
    public private(set) var lastPlayed: [String] = []
    public func play(_ clip: AudioClip) { lastPlayed.append(clip.spokenText) }
    public func playSequence(_ clips: [AudioClip]) { lastPlayed.append(contentsOf: clips.map(\.spokenText)) }
    public func stop() {}
}
