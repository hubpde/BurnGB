//
//  BurnEngine.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI
import Combine

public final class BurnEngine: ObservableObject {
    public static let shared = BurnEngine()

    // MARK: - Published State
    @Published public var isRunning = false
    @Published public var isPaused = false

    @Published public var totalBytesBurned: Int64 = 0
    @Published public var currentSpeedBytesPerSec: Double = 0
    @Published public var peakSpeedBytesPerSec: Double = 0
    @Published public var averageSpeedBytesPerSec: Double = 0
    @Published public var speedSamples: [SpeedSample] = []
    @Published public var prediction: TrafficPrediction = TrafficPrediction()

    @Published public var activeThreads: Int = 8
    @Published public var targetQuotaBytes: Int64? = nil // e.g. 1GB, 5GB, 10GB or nil
    @Published public var speedLimitBytesPerSec: Double? = nil // Bandwidth cap
    @Published public var currentNode: BurnNode = NodePresetManager.defaultNodes[0]
    @Published public var enableBackgroundExecution: Bool = true
    @Published public var enableLiveActivity: Bool = true

    @Published public var startTime: Date?
    @Published public var elapsedTime: TimeInterval = 0

    // MARK: - Internal Variables
    private var workerTasks: [Task<Void, Never>] = []
    private var timerCancellable: AnyCancellable?
    private var lastSampleBytes: Int64 = 0
    private var lastSampleTime: Date = Date()
    private let speedLimiter = SpeedLimiter()
    private let liveActivityManager = LiveActivityManager.shared

    private init() {
        // Load user preferences
        let savedThreads = UserDefaults.standard.integer(forKey: "burn_threads")
        if savedThreads >= 1 && savedThreads <= 64 {
            self.activeThreads = savedThreads
        }
        self.enableBackgroundExecution = UserDefaults.standard.bool(forKey: "burn_bg_exec")
    }

    // MARK: - Public Controls

    public func start() {
        guard !isRunning else { return }
        guard let targetUrl = currentNode.url else { return }

        isRunning = true
        isPaused = false
        startTime = Date()
        lastSampleBytes = totalBytesBurned
        lastSampleTime = Date()

        if enableBackgroundExecution {
            BackgroundKeepAlive.shared.enableBackgroundExecution()
        }

        // Start Live Activity
        if enableLiveActivity {
            liveActivityManager.startActivity(
                nodeName: currentNode.name,
                targetQuotaBytes: targetQuotaBytes,
                formattedQuota: targetQuotaBytes != nil ? ByteFormatter.formatFullBytes(targetQuotaBytes!) : nil
            )
        }

        // Spawn worker tasks
        spawnWorkers(targetUrl: targetUrl, count: activeThreads)

        // Start cadence timer (1-second tick for speed calculation)
        startMetricsTimer()

        HapticManager.notification(.success)
    }

    public func stop() {
        guard isRunning else { return }

        isRunning = false
        isPaused = false

        // Cancel all workers
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()

        timerCancellable?.cancel()
        timerCancellable = nil

        currentSpeedBytesPerSec = 0
        prediction = TrafficPrediction()

        BackgroundKeepAlive.shared.disableBackgroundExecution()

        // End Live Activity
        liveActivityManager.endActivity()

        HapticManager.impact(.heavy)
    }

    public func pause() {
        guard isRunning && !isPaused else { return }
        isPaused = true
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()
        currentSpeedBytesPerSec = 0
        liveActivityManager.updateActivity(
            currentSpeed: 0,
            totalBurned: totalBytesBurned,
            targetQuota: targetQuotaBytes,
            isRunning: true,
            isPaused: true,
            activeThreads: activeThreads,
            elapsedSeconds: Int(elapsedTime)
        )
        HapticManager.impact(.medium)
    }

    public func resume() {
        guard isRunning && isPaused else { return }
        guard let targetUrl = currentNode.url else { return }
        isPaused = false
        spawnWorkers(targetUrl: targetUrl, count: activeThreads)
        HapticManager.impact(.medium)
    }

    public func resetStats() {
        stop()
        totalBytesBurned = 0
        currentSpeedBytesPerSec = 0
        peakSpeedBytesPerSec = 0
        averageSpeedBytesPerSec = 0
        elapsedTime = 0
        startTime = nil
        speedSamples.removeAll()
        prediction = TrafficPrediction()
        HapticManager.notification(.warning)
    }

    public func updateThreads(_ count: Int) {
        let clamped = min(max(count, 1), 64)
        activeThreads = clamped
        UserDefaults.standard.set(clamped, forKey: "burn_threads")

        if isRunning && !isPaused, let url = currentNode.url {
            // Dynamically adjust active worker count
            if clamped > workerTasks.count {
                let diff = clamped - workerTasks.count
                for _ in 0..<diff {
                    let task = createWorkerTask(targetUrl: url)
                    workerTasks.append(task)
                }
            } else if clamped < workerTasks.count {
                let diff = workerTasks.count - clamped
                for _ in 0..<diff {
                    if let last = workerTasks.popLast() {
                        last.cancel()
                    }
                }
            }
        }
    }

    public func updateSpeedLimit(_ bytesPerSec: Double?) {
        self.speedLimitBytesPerSec = bytesPerSec
        Task {
            await speedLimiter.setMaxBytesPerSecond(bytesPerSec)
        }
    }

    // MARK: - Multi-Thread Worker Spawning (Zero Memory Allocation)

    private func spawnWorkers(targetUrl: URL, count: Int) {
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()

        for _ in 0..<count {
            let task = createWorkerTask(targetUrl: targetUrl)
            workerTasks.append(task)
        }
    }

    private func createWorkerTask(targetUrl: URL) -> Task<Void, Never> {
        Task.detached(priority: .userInitiated) { [weak self, targetUrl] in
            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.timeoutIntervalForRequest = 10
            sessionConfig.timeoutIntervalForResource = 300
            sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            sessionConfig.urlCache = nil
            let session = URLSession(configuration: sessionConfig)

            let bufferSize = 64 * 1024 // 64KB stack chunk buffer

            while !Task.isCancelled {
                guard let self = self, await self.isRunning, !(await self.isPaused) else { break }

                do {
                    var request = URLRequest(url: targetUrl)
                    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                    request.setValue("BurnGB/1.0", forHTTPHeaderField: "User-Agent")

                    let (asyncBytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...399).contains(httpResponse.statusCode) else {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        continue
                    }

                    var buffer = [UInt8]()
                    buffer.reserveCapacity(bufferSize)

                    for try await byte in asyncBytes {
                        if Task.isCancelled { break }

                        buffer.append(byte)
                        if buffer.count >= bufferSize {
                            let chunkSize = buffer.count
                            buffer.removeAll(keepingCapacity: true)

                            // Apply speed limiter if configured
                            await self.speedLimiter.throttle(chunkSize: chunkSize)

                            // Accumulate total atomically on MainActor
                            let reachedQuota = await MainActor.run { () -> Bool in
                                self.totalBytesBurned += Int64(chunkSize)

                                if let quota = self.targetQuotaBytes, self.totalBytesBurned >= quota {
                                    self.stop()
                                    HapticManager.notification(.success)
                                    return true
                                }
                                return false
                            }

                            if reachedQuota {
                                return
                            }
                        }
                    }
                } catch {
                    // Backoff slightly on transient network drop then retry
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
        }
    }

    // MARK: - Metrics Timer

    private func startMetricsTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickMetrics()
            }
    }

    private func tickMetrics() {
        guard isRunning else { return }

        let now = Date()
        let interval = now.timeIntervalSince(lastSampleTime)
        guard interval > 0 else { return }

        let deltaBytes = totalBytesBurned - lastSampleBytes
        let currentSpeed = Double(deltaBytes) / interval

        self.currentSpeedBytesPerSec = currentSpeed
        if currentSpeed > self.peakSpeedBytesPerSec {
            self.peakSpeedBytesPerSec = currentSpeed
        }

        if let start = startTime {
            let totalElapsed = now.timeIntervalSince(start)
            self.elapsedTime = totalElapsed
            if totalElapsed > 0 {
                self.averageSpeedBytesPerSec = Double(totalBytesBurned) / totalElapsed
            }
        }

        self.lastSampleBytes = totalBytesBurned
        self.lastSampleTime = now

        // Update prediction
        self.prediction = TrafficPrediction.calculate(fromSpeed: currentSpeed)

        // Store sample for charting
        let sample = SpeedSample(timestamp: now, bytesPerSec: currentSpeed)
        self.speedSamples.append(sample)
        if self.speedSamples.count > 60 {
            self.speedSamples.removeFirst()
        }

        // Update Live Activity
        if enableLiveActivity {
            liveActivityManager.updateActivity(
                currentSpeed: currentSpeed,
                totalBurned: totalBytesBurned,
                targetQuota: targetQuotaBytes,
                isRunning: isRunning,
                isPaused: isPaused,
                activeThreads: activeThreads,
                elapsedSeconds: Int(elapsedTime)
            )
        }
    }
}
