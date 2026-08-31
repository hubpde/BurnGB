//
//  TrafficEngine.swift
//  BurnGBCore
//
//  actor 隔离的前台流量引擎：负责 worker 生命周期、精确计数与快照发布。
//

import Foundation

/// 纯 Swift Concurrency 的网络流量引擎。
///
/// 网络 delegate 只把字节数送入这里；所有可变状态都在 actor 内串行处理，
/// 因此停止、暂停、配额裁剪与重新点火不会出现旧任务串量。
public actor TrafficEngine {
    private let transport: ForegroundTrafficTransport
    private let rateLimiter: RateLimiter
    private var quotaLedger: QuotaLedger?
    private let clock = ContinuousClock()

    private var configuration: BurnConfiguration?
    private var currentRunID: RunID?
    private var currentPhase: BurnPhase = .idle
    private var currentBackgroundState: BackgroundExecutionState = .foreground
    private var configuredWorkerIDs: Set<Int> = []
    private var taskIDByWorker: [Int: Int] = [:]
    private var retryAttemptsByWorker: [Int: Int] = [:]
    private var retryTasks: [Int: Task<Void, Never>] = [:]

    private var metricsTask: Task<Void, Never>?
    private var startedInstant: ContinuousClock.Instant?
    private var pausedInstant: ContinuousClock.Instant?
    private var accumulatedPaused: Duration = .zero
    private var lastSampleInstant: ContinuousClock.Instant?
    private var lastSampleBytes: Int64 = 0

    private var snapshotValue = TrafficSnapshot()
    private var streamContinuations: [UUID: AsyncStream<TrafficSnapshot>.Continuation] = [:]

    public init() {
        self.transport = ForegroundTrafficTransport()
        self.rateLimiter = RateLimiter()

        // delegate 回调只创建一个轻量 Task，把 Sendable 事件交给 actor。
        self.transport.setEventHandler { [weak self] event in
            Task { [weak self] in
                await self?.handle(event)
            }
        }
    }

    deinit {
        metricsTask?.cancel()
        retryTasks.values.forEach { $0.cancel() }
        transport.cancelAll()
    }

    // MARK: - 快照订阅

    /// 返回一个可取消的快照流，供 AppModel 和测试使用。
    public func snapshots() -> AsyncStream<TrafficSnapshot> {
        let streamID = UUID()
        let (stream, continuation) = AsyncStream<TrafficSnapshot>.makeStream()
        streamContinuations[streamID] = continuation
        continuation.yield(snapshotValue)
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { [weak self] in
                await self?.removeStream(streamID)
            }
        }
        return stream
    }

    /// 返回当前快照，并实时计算一次耗时字段。
    public func snapshot() -> TrafficSnapshot {
        var result = snapshotValue
        result.elapsedSeconds = elapsedSeconds()
        result.lastUpdatedAt = Date()
        return result
    }

    private func removeStream(_ streamID: UUID) {
        streamContinuations.removeValue(forKey: streamID)
    }

    // MARK: - 任务控制

    /// 前台用户明确点火后启动一个新的独立 run。
    @discardableResult
    public func start(_ configuration: BurnConfiguration) async throws -> RunID {
        guard currentPhase != .running && currentPhase != .paused && currentPhase != .starting else {
            throw TrafficEngineError.alreadyRunning
        }
        guard configuration.node.url != nil else {
            throw TrafficEngineError.invalidNode
        }
        guard configuration.workerCount > 0 else {
            throw TrafficEngineError.invalidConfiguration("并发线程数必须大于 0。")
        }

        // 新 run 先切断旧任务；旧事件会因 run ID 不一致而被忽略。
        transport.cancelAll()
        retryTasks.values.forEach { $0.cancel() }
        retryTasks.removeAll()

        let runID = RunID()
        self.configuration = configuration
        self.currentRunID = runID
        self.currentPhase = .starting
        self.currentBackgroundState = .foreground
        self.quotaLedger = QuotaLedger(quotaBytes: configuration.quotaBytes)
        self.configuredWorkerIDs = Set(0..<configuration.workerCount)
        self.taskIDByWorker.removeAll()
        self.retryAttemptsByWorker.removeAll()
        self.startedInstant = clock.now
        self.pausedInstant = nil
        self.accumulatedPaused = .zero
        self.lastSampleInstant = clock.now
        self.lastSampleBytes = 0
        self.snapshotValue = TrafficSnapshot(
            runID: runID,
            phase: .starting,
            backgroundState: .foreground,
            nodeName: configuration.node.name,
            totalBytes: 0,
            receivedBytes: 0,
            workerCount: configuration.workerCount,
            activeWorkerCount: 0,
            quotaBytes: configuration.quotaBytes,
            startedAt: Date(),
            history: []
        )
        await rateLimiter.setLimit(bytesPerSecond: configuration.rateLimitBytesPerSecond)

        guard let url = configuration.node.url else {
            currentPhase = .failed
            throw TrafficEngineError.invalidNode
        }

        // 所有 worker 共用同一 URLSession，避免 64 个 session 同时占用资源。
        for workerID in configuredWorkerIDs.sorted() {
            taskIDByWorker[workerID] = transport.start(runID: runID, workerID: workerID, url: url)
        }
        currentPhase = .running
        snapshotValue.phase = .running
        snapshotValue.activeWorkerCount = taskIDByWorker.count
        startMetricsLoop()
        emitSnapshot()
        return runID
    }

    /// 停止当前 run，保留最后统计供 UI 查看。
    public func stop() async {
        guard currentRunID != nil else { return }
        currentPhase = .stopping
        snapshotValue.phase = .stopping
        emitSnapshot()

        transport.cancelAll()
        retryTasks.values.forEach { $0.cancel() }
        retryTasks.removeAll()
        metricsTask?.cancel()
        metricsTask = nil
        taskIDByWorker.removeAll()
        configuredWorkerIDs.removeAll()
        currentRunID = nil
        currentPhase = .idle
        currentBackgroundState = .foreground
        snapshotValue.runID = nil
        snapshotValue.phase = .idle
        snapshotValue.backgroundState = .foreground
        snapshotValue.activeWorkerCount = 0
        snapshotValue.elapsedSeconds = elapsedSeconds()
        snapshotValue.lastUpdatedAt = Date()
        emitSnapshot()
    }

    /// 暂停网络任务，但不清除当前 run 和统计账本。
    public func pause() {
        guard currentPhase == .running else { return }
        currentPhase = .paused
        pausedInstant = clock.now
        transport.suspendAll()
        snapshotValue.speedBytesPerSecond = 0
        snapshotValue.phase = .paused
        snapshotValue.activeWorkerCount = taskIDByWorker.count
        snapshotValue.elapsedSeconds = elapsedSeconds()
        emitSnapshot()
    }

    /// 恢复暂停的网络任务。
    public func resume() {
        guard currentPhase == .paused else { return }
        if let pausedInstant {
            accumulatedPaused += pausedInstant.duration(to: clock.now)
        }
        self.pausedInstant = nil
        currentPhase = .running

        // 暂停期间新增的 worker 没有对应 URLSession 任务，恢复时补建。
        if let runID = currentRunID, let url = configuration?.node.url {
            for workerID in configuredWorkerIDs.sorted() where taskIDByWorker[workerID] == nil {
                taskIDByWorker[workerID] = transport.start(runID: runID, workerID: workerID, url: url)
            }
        }
        transport.resumeAll()
        snapshotValue.phase = .running
        snapshotValue.activeWorkerCount = taskIDByWorker.count
        snapshotValue.elapsedSeconds = elapsedSeconds()
        emitSnapshot()
    }

    /// 清空本次任务的统计数据。
    public func reset() async {
        await stop()
        let nodeName = configuration?.node.name ?? snapshotValue.nodeName
        configuration = nil
        quotaLedger = nil
        startedInstant = nil
        pausedInstant = nil
        accumulatedPaused = .zero
        lastSampleInstant = nil
        lastSampleBytes = 0
        snapshotValue = TrafficSnapshot(nodeName: nodeName)
        emitSnapshot()
    }

    /// 运行中动态修改 worker 数量。
    public func setWorkerCount(_ count: Int) {
        let newCount = min(max(count, 1), 64)
        guard var configuration, let runID = currentRunID, let url = configuration.node.url else {
            return
        }
        configuration.workerCount = newCount
        self.configuration = configuration

        let newIDs = Set(0..<newCount)
        let removedIDs = configuredWorkerIDs.subtracting(newIDs)
        for workerID in removedIDs {
            transport.cancel(workerID: workerID)
            taskIDByWorker.removeValue(forKey: workerID)
            retryTasks.removeValue(forKey: workerID)?.cancel()
        }

        if currentPhase == .running {
            for workerID in newIDs.subtracting(configuredWorkerIDs) {
                taskIDByWorker[workerID] = transport.start(runID: runID, workerID: workerID, url: url)
            }
        }
        configuredWorkerIDs = newIDs
        snapshotValue.workerCount = newCount
        snapshotValue.activeWorkerCount = taskIDByWorker.count
        emitSnapshot()
    }

    /// 更新限速策略并立即作用于后续分块。
    public func setRateLimit(bytesPerSecond: Double?) async {
        guard let value = bytesPerSecond, value.isFinite, value > 0 else {
            configuration?.rateLimitBytesPerSecond = nil
            await rateLimiter.setLimit(bytesPerSecond: nil)
            return
        }
        configuration?.rateLimitBytesPerSecond = value
        await rateLimiter.setLimit(bytesPerSecond: value)
    }

    /// 运行中禁止偷偷切换实际节点，避免 UI 与连接目标不一致。
    public func setNode(_ node: BurnNode) throws {
        guard currentPhase != .running && currentPhase != .paused && currentPhase != .starting else {
            throw TrafficEngineError.cannotChangeNodeWhileRunning
        }
        guard node.url != nil else { throw TrafficEngineError.invalidNode }
        configuration?.node = node
        snapshotValue.nodeName = node.name
        emitSnapshot()
    }

    /// 更新系统管理的后台执行状态。
    public func setBackgroundState(_ state: BackgroundExecutionState) {
        currentBackgroundState = state
        snapshotValue.backgroundState = state
        emitSnapshot()
    }

    /// 后台 URLSession 分段下载回调使用的统一计数入口。
    public func ingestBackgroundBytes(runID: RunID, count: Int) async {
        guard currentRunID == runID, isActivePhase else { return }
        await ingest(runID: runID, workerID: -1, taskIdentifier: -1, count: count)
    }

    // MARK: - 网络事件处理

    private func handle(_ event: TrafficNetworkEvent) async {
        switch event {
        case let .response(runID, _, statusCode):
            guard runID == currentRunID else { return }
            if !(200...399).contains(statusCode) {
                snapshotValue.lastError = "节点响应异常：HTTP \(statusCode)"
                emitSnapshot()
            }

        case let .bytes(runID, workerID, taskIdentifier, count):
            await ingest(runID: runID, workerID: workerID, taskIdentifier: taskIdentifier, count: count)

        case let .finished(runID, workerID, taskIdentifier):
            guard runID == currentRunID else { return }
            if taskIDByWorker[workerID] == taskIdentifier {
                taskIDByWorker.removeValue(forKey: workerID)
            }
            if currentPhase == .running, configuredWorkerIDs.contains(workerID) {
                scheduleRetry(workerID: workerID, runID: runID, message: "节点响应已结束，准备重新连接")
            }
            snapshotValue.activeWorkerCount = taskIDByWorker.count
            emitSnapshot()

        case let .failed(runID, workerID, taskIdentifier, message):
            guard runID == currentRunID else { return }
            if taskIDByWorker[workerID] == taskIdentifier {
                taskIDByWorker.removeValue(forKey: workerID)
            }
            snapshotValue.lastError = message
            if currentPhase == .running, configuredWorkerIDs.contains(workerID) {
                scheduleRetry(workerID: workerID, runID: runID, message: message)
            }
            snapshotValue.activeWorkerCount = taskIDByWorker.count
            emitSnapshot()
        }
    }

    private func ingest(runID: RunID, workerID: Int, taskIdentifier: Int, count: Int) async {
        guard runID == currentRunID,
              isActivePhase,
              (workerID < 0 || configuredWorkerIDs.contains(workerID)),
              count > 0 else {
            if taskIdentifier >= 0 { transport.resume(taskIdentifier: taskIdentifier) }
            return
        }
        guard let ledger = quotaLedger else { return }

        let decision = await ledger.ingest(count)
        snapshotValue.receivedBytes = decision.receivedBytes
        snapshotValue.totalBytes = decision.totalBytes
        snapshotValue.lastUpdatedAt = Date()

        if decision.reachedQuota {
            // 账本已原子裁剪，展示值不会超过额度。
            currentPhase = .completed
            transport.cancelAll()
            retryTasks.values.forEach { $0.cancel() }
            retryTasks.removeAll()
            taskIDByWorker.removeAll()
            metricsTask?.cancel()
            metricsTask = nil
            snapshotValue.phase = .completed
            snapshotValue.activeWorkerCount = 0
            snapshotValue.elapsedSeconds = elapsedSeconds()
            emitSnapshot()
            return
        }

        if decision.acceptedBytes > 0 {
            do {
                try await rateLimiter.wait(for: Int(min(decision.acceptedBytes, Int64(Int.max))))
            } catch {
                return
            }
        }

        // 上层等待期间可能已经停止或换了 run，只有当前任务仍有效时才能恢复。
        if taskIdentifier >= 0, runID == currentRunID, currentPhase == .running {
            transport.resume(taskIdentifier: taskIdentifier)
        }
    }

    // MARK: - 重连与指标

    private var isActivePhase: Bool {
        currentPhase == .running || currentPhase == .paused
    }

    private func scheduleRetry(workerID: Int, runID: RunID, message: String) {
        guard retryTasks[workerID] == nil else { return }
        let attempt = retryAttemptsByWorker[workerID, default: 0]
        retryAttemptsByWorker[workerID] = min(attempt + 1, 8)
        let delaySeconds = min(pow(2.0, Double(attempt)) * 0.25, 8.0)
        snapshotValue.lastError = message

        retryTasks[workerID] = Task { [weak self] in
            let nanoseconds = UInt64(delaySeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            await self?.retryWorker(workerID: workerID, runID: runID)
        }
    }

    private func retryWorker(workerID: Int, runID: RunID) {
        retryTasks[workerID] = nil
        guard runID == currentRunID,
              currentPhase == .running,
              configuredWorkerIDs.contains(workerID),
              let url = configuration?.node.url else { return }
        taskIDByWorker[workerID] = transport.start(runID: runID, workerID: workerID, url: url)
        snapshotValue.activeWorkerCount = taskIDByWorker.count
        emitSnapshot()
    }

    private func startMetricsLoop() {
        metricsTask?.cancel()
        metricsTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.publishMetrics()
            }
        }
    }

    private func publishMetrics() {
        guard currentRunID != nil, currentPhase == .running else { return }
        let now = clock.now
        let interval = lastSampleInstant?.duration(to: now) ?? .seconds(1)
        let elapsed = max(durationSeconds(interval), 0.001)
        let delta = max(0, snapshotValue.totalBytes - lastSampleBytes)
        let speed = Double(delta) / elapsed

        snapshotValue.speedBytesPerSecond = speed
        snapshotValue.peakSpeedBytesPerSecond = max(snapshotValue.peakSpeedBytesPerSecond, speed)
        let runningSeconds = max(elapsedSeconds(), 0.001)
        snapshotValue.averageSpeedBytesPerSecond = Double(snapshotValue.totalBytes) / runningSeconds
        snapshotValue.elapsedSeconds = runningSeconds
        snapshotValue.history.append(SpeedPoint(timestamp: Date(), bytesPerSecond: speed))
        snapshotValue.history = Array(snapshotValue.history.suffix(60))
        snapshotValue.lastUpdatedAt = Date()
        lastSampleBytes = snapshotValue.totalBytes
        lastSampleInstant = now
        emitSnapshot()
    }

    private func elapsedSeconds() -> TimeInterval {
        guard let startedInstant else { return snapshotValue.elapsedSeconds }
        var end = clock.now
        var paused = accumulatedPaused
        if let pausedInstant, currentPhase == .paused {
            end = pausedInstant
        }
        let activeDuration = startedInstant.duration(to: end) - paused
        return max(durationSeconds(activeDuration), 0)
    }

    /// 将 Duration 安全转换为 Double 秒数。
    private func durationSeconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }

    private func emitSnapshot() {
        snapshotValue.lastUpdatedAt = Date()
        for continuation in streamContinuations.values {
            continuation.yield(snapshotValue)
        }
    }
}
