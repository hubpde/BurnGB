//
//  AppModel.swift
//  BurnGB
//
//  SwiftUI 唯一应用状态入口与系统生命周期协调器。
//

import SwiftUI
import Observation
import BurnGBCore

/// BurnGB 的主模型。
/// UI 只观察本类；网络、配额、后台任务和 ActivityKit 各自拥有清晰边界。
@MainActor
@Observable
final class AppModel {
    // MARK: - 对外可观察状态

    let engine: TrafficEngine
    let checkpointStore: BurnCheckpointStore
    let probeService: NodeProbeService
    let ipDiagnostics: IPDiagnosticsService
    let liveActivity: LiveActivityCoordinator

    /// 当前展示快照。
    var snapshot = TrafficSnapshot()
    /// 内置节点与用户节点列表。
    var nodes: [BurnNode] = BurnNodeCatalog.builtIn
    /// 当前选中节点。
    var selectedNode: BurnNode
    /// 并发 worker 数。
    var workerCount: Int = 8
    /// 定量目标（字节）。
    var quotaBytes: Int64?
    /// 限速（Byte/s）。
    var rateLimitBytesPerSecond: Double?
    /// 是否请求系统持续处理任务。
    var requestsBackgroundContinuation = true
    /// 是否启用实时活动。
    var liveActivityEnabled = true
    /// 是否正在执行 UI 操作。
    var isPerformingAction = false
    /// 最近一次需要用户关注的错误。
    var errorMessage: String?
    /// 节点探测结果。
    var probeResults: [UUID: NodeProbeResult] = [:]
    /// 是否正在执行节点探测。
    var isProbingNodes = false
    /// 多出口公网 IP 诊断结果。
    var egressResults: [EgressInfo] = []
    /// 是否正在执行公网出口诊断。
    var isCheckingEgress = false

    // MARK: - 私有生命周期任务

    @ObservationIgnored private var snapshotTask: Task<Void, Never>?
    @ObservationIgnored private var nodeProbeTask: Task<Void, Never>?
    @ObservationIgnored private var egressTask: Task<Void, Never>?
    @ObservationIgnored private var checkpointTask: Task<Void, Never>?
    @ObservationIgnored private var pendingCheckpoint: BurnCheckpoint?
    @ObservationIgnored private var lastCheckpointAt = Date.distantPast
    @ObservationIgnored private var appDelegate: AppDelegate?
    @ObservationIgnored private var backgroundTransfer: BackgroundTransferCoordinator?
    @ObservationIgnored private var continuedProcessing: ContinuedProcessingCoordinator?

    init(appDelegate: AppDelegate? = nil) {
        self.engine = TrafficEngine()
        self.checkpointStore = BurnCheckpointStore()
        self.probeService = NodeProbeService()
        self.ipDiagnostics = IPDiagnosticsService()
        self.liveActivity = LiveActivityCoordinator()
        self.selectedNode = BurnNodeCatalog.builtIn[0]
        self.appDelegate = appDelegate
        self.backgroundTransfer = appDelegate?.backgroundTransferCoordinator
        self.continuedProcessing = ContinuedProcessingCoordinator(engine: engine)

        configureBackgroundBridge()
        observeEngine()
        restoreCheckpoint()
        liveActivity.restoreExistingActivity()
    }

    deinit {
        snapshotTask?.cancel()
        nodeProbeTask?.cancel()
        egressTask?.cancel()
        checkpointTask?.cancel()
    }

    // MARK: - 生命周期桥接

    /// 在 App 启动后安装 BGContinuedProcessingTask 和后台下载回调。
    func installSystemHandlers(on appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.backgroundTransfer = appDelegate.backgroundTransferCoordinator
        configureBackgroundBridge()
        continuedProcessing?.install(on: appDelegate)
    }

    /// SwiftUI scenePhase 变化入口。
    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .background:
            persistCheckpoint(wasRunning: isRunning, immediately: true)
            submitBackgroundContinuationIfNeeded()
        case .active:
            Task { [weak self] in
                guard let self else { return }
                await self.engine.setBackgroundState(.foreground)
                self.snapshot = await self.engine.snapshot()
                self.liveActivity.update(with: self.snapshot)
            }
        case .inactive:
            // inactive 只表示过渡态，不改变网络任务状态。
            break
        @unknown default:
            break
        }
    }

    // MARK: - 业务控制

    /// 根据当前设置点火。
    func start() {
        guard !isRunning else { return }
        guard let url = selectedNode.url else {
            errorMessage = TrafficEngineError.invalidNode.localizedDescription
            return
        }
        guard url.scheme?.lowercased() == "https" else {
            errorMessage = "为了安全，BurnGB 只允许 HTTPS 测速地址。"
            return
        }

        isPerformingAction = true
        errorMessage = nil
        let configuration = BurnConfiguration(
            node: selectedNode,
            workerCount: workerCount,
            quotaBytes: quotaBytes,
            rateLimitBytesPerSecond: rateLimitBytesPerSecond,
            requestsBackgroundContinuation: requestsBackgroundContinuation
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.engine.start(configuration)
                self.snapshot = await self.engine.snapshot()
                if self.liveActivityEnabled {
                    await self.liveActivity.start(for: self.snapshot)
                }
                if configuration.requestsBackgroundContinuation {
                    do {
                        try await self.continuedProcessing?.submitIfNeeded(for: configuration)
                    } catch {
                        // BGContinuedProcessingTask 被系统拒绝时，切换到有限的 background URLSession 片段通道。
                        self.errorMessage = error.localizedDescription
                        if let runID = self.snapshot.runID, let nodeURL = configuration.node.url {
                            self.backgroundTransfer?.startFallback(
                                runID: runID,
                                url: nodeURL,
                                workerCount: configuration.workerCount
                            )
                            await self.engine.setBackgroundState(.running)
                        }
                    }
                }
                self.persistCheckpoint(wasRunning: true, immediately: true)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isPerformingAction = false
        }
    }

    /// 暂停当前任务。
    func pause() {
        guard isRunning else { return }
        Task { [weak self] in
            guard let self else { return }
            await self.engine.pause()
            self.snapshot = await self.engine.snapshot()
            self.liveActivity.update(with: self.snapshot)
            self.persistCheckpoint(wasRunning: true, immediately: true)
        }
    }

    /// 恢复当前任务。
    func resume() {
        guard isPaused else { return }
        Task { [weak self] in
            guard let self else { return }
            await self.engine.resume()
            self.snapshot = await self.engine.snapshot()
            self.liveActivity.update(with: self.snapshot)
            self.persistCheckpoint(wasRunning: true, immediately: true)
        }
    }

    /// 终止任务并立即结束实时活动。
    func stop() {
        guard isRunning || snapshot.phase == .completed else { return }
        isPerformingAction = true
        continuedProcessing?.cancel()
        backgroundTransfer?.stopAll()
        Task { [weak self] in
            guard let self else { return }
            await self.engine.stop()
            self.snapshot = await self.engine.snapshot()
            await self.liveActivity.endCurrent()
            self.persistCheckpoint(wasRunning: false, immediately: true)
            self.isPerformingAction = false
        }
    }

    /// 重置本次统计。
    func reset() {
        guard !isRunning else { return }
        Task { [weak self] in
            guard let self else { return }
            await self.engine.reset()
            self.snapshot = await self.engine.snapshot()
            try? await self.checkpointStore.clear()
        }
    }

    /// 动态修改 worker 数量。
    func setWorkerCount(_ value: Int) {
        workerCount = min(max(value, 1), 64)
        Task { await engine.setWorkerCount(workerCount) }
    }

    /// 动态修改限速。
    func setRateLimit(_ value: Double?) {
        rateLimitBytesPerSecond = value
        Task { await engine.setRateLimit(bytesPerSecond: value) }
    }

    /// 修改节点；运行时由引擎拒绝切换。
    func selectNode(_ node: BurnNode) {
        guard !isRunning else {
            errorMessage = TrafficEngineError.cannotChangeNodeWhileRunning.localizedDescription
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.engine.setNode(node)
                self.selectedNode = node
                self.snapshot = await self.engine.snapshot()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// 探测本机通过不同服务看到的公网出口。
    func checkEgress() {
        egressTask?.cancel()
        isCheckingEgress = true
        egressTask = Task { [weak self] in
            guard let self else { return }
            let results = await self.ipDiagnostics.checkAll()
            guard !Task.isCancelled else { return }
            self.egressResults = results
            self.isCheckingEgress = false
        }
    }

    // MARK: - 节点探测

    /// 并发探测全部节点，并在视图销毁时取消任务。
    func probeAllNodes() {
        nodeProbeTask?.cancel()
        isProbingNodes = true
        let allNodes = nodes
        nodeProbeTask = Task { [weak self] in
            guard let self else { return }
            let results = await self.probeService.probeAll(allNodes)
            guard !Task.isCancelled else { return }
            self.probeResults = Dictionary(uniqueKeysWithValues: results.map { ($0.nodeID, $0) })
            self.isProbingNodes = false
        }
    }

    // MARK: - 自定义节点

    func addNode(name: String, urlString: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let url = URL(string: trimmedURL),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false,
              url.user == nil,
              url.password == nil else {
            return "请输入有效的 HTTPS 地址，且地址不能包含用户名或密码。"
        }

        let node = BurnNode(
            name: trimmedName,
            urlString: trimmedURL,
            group: "自定义",
            symbolName: "link",
            isCustom: true
        )
        nodes.append(node)
        persistCustomNodes()
        return nil
    }

    func removeNode(_ node: BurnNode) {
        guard node.isCustom, !isRunning else { return }
        nodes.removeAll { $0.id == node.id }
        if selectedNode.id == node.id {
            selectedNode = BurnNodeCatalog.builtIn[0]
        }
        persistCustomNodes()
    }

    // MARK: - 后台桥接

    private func configureBackgroundBridge() {
        guard let backgroundTransfer else { return }
        backgroundTransfer.setEventHandler { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch event {
                case let .bytes(runID, _, count):
                    await self.engine.ingestBackgroundBytes(runID: runID, count: count)
                case let .segmentFinished(_, _):
                    break
                case let .failed(_, _, message):
                    self.errorMessage = message
                    await self.engine.setBackgroundState(.interrupted)
                }
            }
        }
    }

    private func submitBackgroundContinuationIfNeeded() {
        guard isRunning,
              requestsBackgroundContinuation,
              let configuration = currentConfiguration else { return }

        Task { [weak self] in
            guard let self else { return }
            await self.engine.setBackgroundState(.submitting)
            do {
                try await self.continuedProcessing?.submitIfNeeded(for: configuration)
            } catch {
                await self.engine.setBackgroundState(.unavailable)
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private var currentConfiguration: BurnConfiguration? {
        guard selectedNode.url != nil else { return nil }
        return BurnConfiguration(
            node: selectedNode,
            workerCount: workerCount,
            quotaBytes: quotaBytes,
            rateLimitBytesPerSecond: rateLimitBytesPerSecond,
            requestsBackgroundContinuation: requestsBackgroundContinuation
        )
    }

    // MARK: - 快照、持久化与恢复

    private func observeEngine() {
        snapshotTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.engine.snapshots()
            for await snapshot in stream {
                guard !Task.isCancelled else { return }
                self.snapshot = snapshot
                self.liveActivity.update(with: snapshot)
                if snapshot.phase == .running || snapshot.phase == .paused {
                    self.persistCheckpoint(wasRunning: true)
                }
            }
        }
    }

    private func persistCheckpoint(wasRunning: Bool, immediately: Bool = false) {
        guard let configuration = currentConfiguration else { return }
        pendingCheckpoint = BurnCheckpoint(
            configuration: configuration,
            snapshot: snapshot,
            wasRunning: wasRunning
        )

        let now = Date()
        let elapsed = now.timeIntervalSince(lastCheckpointAt)
        guard immediately || elapsed >= 2 else {
            // 高频网络回调只更新内存中的 pending checkpoint，最多每两秒落盘一次。
            if checkpointTask == nil {
                let delay = max(0.1, 2 - elapsed)
                checkpointTask = Task { @MainActor [weak self] in
                    let nanoseconds = UInt64(delay * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanoseconds)
                    guard !Task.isCancelled else { return }
                    self?.checkpointTask = nil
                    self?.persistCheckpoint(wasRunning: wasRunning, immediately: true)
                }
            }
            return
        }

        let checkpoint = pendingCheckpoint
        pendingCheckpoint = nil
        lastCheckpointAt = now
        checkpointTask?.cancel()
        checkpointTask = nil
        guard let checkpoint else { return }

        let store = checkpointStore
        Task {
            try? await store.save(checkpoint)
        }
    }

    private func restoreCheckpoint() {
        let task = Task { [weak self] in
            guard let self else { return }
            guard let checkpoint = try? await self.checkpointStore.load() else { return }
            self.selectedNode = checkpoint.configuration.node
            self.workerCount = checkpoint.configuration.workerCount
            self.quotaBytes = checkpoint.configuration.quotaBytes
            self.rateLimitBytesPerSecond = checkpoint.configuration.rateLimitBytesPerSecond
            self.requestsBackgroundContinuation = checkpoint.configuration.requestsBackgroundContinuation
            self.snapshot = checkpoint.snapshot
            if checkpoint.wasRunning {
                self.snapshot.backgroundState = .interrupted
                self.snapshot.lastError = "上一次任务被系统中断，请确认节点和额度后重新开始。"
            }
        }
        // 保留 Task 由系统运行；恢复只在启动阶段执行一次。
        _ = task
        loadCustomNodes()
    }

    private func loadCustomNodes() {
        guard let data = UserDefaults(suiteName: BurnCheckpointStore.appGroupIdentifier)?.data(forKey: "burngb.custom-nodes"),
              let decoded = try? JSONDecoder().decode([BurnNode].self, from: data) else { return }
        nodes = BurnNodeCatalog.builtIn + decoded
    }

    private func persistCustomNodes() {
        let custom = nodes.filter(\.isCustom)
        guard let data = try? JSONEncoder().encode(custom) else { return }
        UserDefaults(suiteName: BurnCheckpointStore.appGroupIdentifier)?.set(data, forKey: "burngb.custom-nodes")
    }

    var isRunning: Bool {
        snapshot.phase == .running || snapshot.phase == .starting || snapshot.phase == .paused
    }

    var isPaused: Bool {
        snapshot.phase == .paused
    }

    var isFinished: Bool {
        snapshot.phase == .completed
    }
}
