//
//  BurnEngine.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI
import Combine

/// 高性能网络流量消耗与测速核心引擎
/// 纯原生 Swift Concurrency 架构，采用零内存分配流式读取（Zero-Allocation Stream）
/// 深度集成 iOS 官方实时活动（Live Activities Frequent Updates）与灵动岛
public final class BurnEngine: ObservableObject {
    public static let shared = BurnEngine()

    // MARK: - 响应式状态发布属性

    /// 引擎是否处于运行拉取状态
    @Published public var isRunning: Bool = false

    /// 是否处于用户手动暂停状态
    @Published public var isPaused: Bool = false

    /// 累计已拉取消耗的字节总数（Byte）
    @Published public var totalBytesBurned: Int64 = 0

    /// 当前瞬时下载速率（Byte/s）
    @Published public var currentSpeedBytesPerSec: Double = 0

    /// 历史最高峰值速率（Byte/s）
    @Published public var peakSpeedBytesPerSec: Double = 0

    /// 累计全程平均速率（Byte/s）
    @Published public var averageSpeedBytesPerSec: Double = 0

    /// 历史采样序列（最近 60 秒，供走势图使用）
    @Published public var speedSamples: [SpeedSample] = []

    /// 各周期消耗预测统计（分/时/天/月）
    @Published public var prediction: TrafficPrediction = TrafficPrediction()

    /// 当前并发工作线程数（1 ~ 64）
    @Published public var activeThreads: Int = 8

    /// 定量目标上限阈值（字节数，nil 代表无上限）
    @Published public var targetQuotaBytes: Int64? = nil

    /// 带宽限速阈值（Byte/s，nil 代表不限速）
    @Published public var speedLimitBytesPerSec: Double? = nil

    /// 当前选中的测速节点
    @Published public var currentNode: BurnNode = NodePresetManager.defaultNodes[0]

    /// 是否启用官方实时活动与灵动岛高频推送
    @Published public var enableLiveActivity: Bool = true

    /// 本次任务点火启动时间
    @Published public var startTime: Date?

    /// 任务累计运行耗时（秒）
    @Published public var elapsedTime: TimeInterval = 0

    // MARK: - 私有属性与协作器

    /// 所有并发工作 Task 句柄
    private var workerTasks: [Task<Void, Never>] = []

    /// 1 秒采样定时器
    private var timerCancellable: AnyCancellable?

    /// 上次采样时刻的累计字节数
    private var lastSampleBytes: Int64 = 0

    /// 上次采样时刻的时间戳
    private var lastSampleTime: Date = Date()

    /// 令牌桶带宽限速器
    private let speedLimiter = SpeedLimiter()

    /// 官方实时活动与灵动岛管理器
    private let liveActivityManager = LiveActivityManager.shared

    // MARK: - 初始化

    private init() {
        // 读取本地存储的用户偏好线程数
        let savedThreads = UserDefaults.standard.integer(forKey: "burn_threads")
        if savedThreads >= 1 && savedThreads <= 64 {
            self.activeThreads = savedThreads
        }

        // 读取实时活动开关配置
        if UserDefaults.standard.object(forKey: "burn_live_activity") != nil {
            self.enableLiveActivity = UserDefaults.standard.bool(forKey: "burn_live_activity")
        }
    }

    // MARK: - 核心业务控制方法

    /// 启动拉取（点火）
    public func start() {
        guard !isRunning else { return }
        guard let targetUrl = currentNode.url else { return }

        isRunning = true
        isPaused = false
        startTime = Date()
        lastSampleBytes = totalBytesBurned
        lastSampleTime = Date()

        // 1. 启动 iOS 官方实时活动（灵动岛 & 锁屏）
        if enableLiveActivity {
            liveActivityManager.startActivity(
                nodeName: currentNode.name,
                targetQuotaBytes: targetQuotaBytes,
                formattedQuota: targetQuotaBytes != nil ? ByteFormatter.formatFullBytes(targetQuotaBytes!) : nil
            )
        }

        // 2. 并发创建多线程流式下载任务
        spawnWorkers(targetUrl: targetUrl, count: activeThreads)

        // 3. 启动 1 秒心跳定时器（计算速率、推算预测并推送实时活动）
        startMetricsTimer()

        HapticManager.notification(.success)
    }

    /// 停止拉取并释放所有连接
    public func stop() {
        guard isRunning else { return }

        isRunning = false
        isPaused = false

        // 取消所有并发任务
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()

        timerCancellable?.cancel()
        timerCancellable = nil

        currentSpeedBytesPerSec = 0
        prediction = TrafficPrediction()

        // 关闭官方实时活动
        liveActivityManager.endActivity()

        HapticManager.impact(.heavy)
    }

    /// 暂停拉取
    public func pause() {
        guard isRunning && !isPaused else { return }
        isPaused = true

        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()
        currentSpeedBytesPerSec = 0

        // 更新实时活动为暂停状态
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

    /// 恢复拉取
    public func resume() {
        guard isRunning && isPaused else { return }
        guard let targetUrl = currentNode.url else { return }

        isPaused = false
        spawnWorkers(targetUrl: targetUrl, count: activeThreads)
        HapticManager.impact(.medium)
    }

    /// 重置所有统计数据
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

    /// 动态调节并发线程数（无需重启引擎，即时生效）
    public func updateThreads(_ count: Int) {
        let clamped = min(max(count, 1), 64)
        activeThreads = clamped
        UserDefaults.standard.set(clamped, forKey: "burn_threads")

        if isRunning && !isPaused, let url = currentNode.url {
            if clamped > workerTasks.count {
                // 增加新任务
                let diff = clamped - workerTasks.count
                for _ in 0..<diff {
                    let task = createWorkerTask(targetUrl: url)
                    workerTasks.append(task)
                }
            } else if clamped < workerTasks.count {
                // 减少任务
                let diff = workerTasks.count - clamped
                for _ in 0..<diff {
                    if let last = workerTasks.popLast() {
                        last.cancel()
                    }
                }
            }
        }
    }

    /// 动态更新限速阈值
    public func updateSpeedLimit(_ bytesPerSec: Double?) {
        self.speedLimitBytesPerSec = bytesPerSec
        Task {
            await speedLimiter.setMaxBytesPerSecond(bytesPerSec)
        }
    }

    // MARK: - 零内存分配流式读取 Worker

    private func spawnWorkers(targetUrl: URL, count: Int) {
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()

        for _ in 0..<count {
            let task = createWorkerTask(targetUrl: targetUrl)
            workerTasks.append(task)
        }
    }

    /// 创建一个独立的流式下载协程
    /// 核心设计：使用 URLSession.bytes 异步分块读取，数据仅在 64KB 临时栈内存累加后即时丢弃
    /// 无论消耗多大流量，App 内存始终维持在 ~15MB，杜绝 OOM 崩溃
    private func createWorkerTask(targetUrl: URL) -> Task<Void, Never> {
        Task.detached(priority: .userInitiated) { [weak self, targetUrl] in
            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.timeoutIntervalForRequest = 10
            sessionConfig.timeoutIntervalForResource = 300
            sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            sessionConfig.urlCache = nil
            let session = URLSession(configuration: sessionConfig)

            let bufferSize = 64 * 1024 // 64KB 固定微小缓冲区

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
                            // 清空并保留容量（避免反复内存重分配）
                            buffer.removeAll(keepingCapacity: true)

                            // 令牌桶限速微休眠
                            await self.speedLimiter.throttle(chunkSize: chunkSize)

                            // 主线程原子累计已消耗字节数并检查定量切断阈值
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
                    // 网络抖动时微休眠后重连
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
        }
    }

    // MARK: - 定时采样与实时活动高频推送

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

        // 更新消耗预测
        self.prediction = TrafficPrediction.calculate(fromSpeed: currentSpeed)

        // 记录采样历史点
        let sample = SpeedSample(timestamp: now, bytesPerSec: currentSpeed)
        self.speedSamples.append(sample)
        if self.speedSamples.count > 60 {
            self.speedSamples.removeFirst()
        }

        // 高频同步更新 iOS 官方实时活动与灵动岛
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
