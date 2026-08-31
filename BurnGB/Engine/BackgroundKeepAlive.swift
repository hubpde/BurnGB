//
//  BackgroundKeepAlive.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import UIKit
import AVFAudio

public final class BackgroundKeepAlive: NSObject {
    public static let shared = BackgroundKeepAlive()

    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var audioEngine: AVAudioEngine?
    private var isAudioActive = false

    private override init() {
        super.init()
    }

    public func enableBackgroundExecution() {
        startBackgroundTask()
        startSilentAudioEngine()
    }

    public func disableBackgroundExecution() {
        stopSilentAudioEngine()
        endBackgroundTask()
    }

    // MARK: - Silent Audio Engine (Zero-file in-memory tone generation)

    private func startSilentAudioEngine() {
        guard !isAudioActive else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let engine = AVAudioEngine()
            let mainMixer = engine.mainMixerNode
            mainMixer.outputVolume = 0.0 // Completely silent

            // Generate an in-memory silent buffer player
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)

            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
            engine.connect(playerNode, to: mainMixer, format: format)

            let frameCount: AVAudioFrameCount = 44100
            if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                buffer.frameLength = frameCount
                // Clean buffer memory (pure zeroes)
                if let channelData = buffer.floatChannelData {
                    for channel in 0..<Int(format.channelCount) {
                        memset(channelData[channel], 0, Int(frameCount) * MemoryLayout<Float>.size)
                    }
                }

                try engine.start()
                playerNode.play()
                playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)

                self.audioEngine = engine
                self.isAudioActive = true
            }
        } catch {
            print("[BackgroundKeepAlive] Failed to start silent audio engine: \(error)")
        }
    }

    private func stopSilentAudioEngine() {
        guard isAudioActive else { return }
        audioEngine?.stop()
        audioEngine = nil
        isAudioActive = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - UIKit Background Task

    private func startBackgroundTask() {
        endBackgroundTask()
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "com.hubpde.BurnGB.traffic") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
}
