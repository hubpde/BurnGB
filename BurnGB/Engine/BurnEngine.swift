//
//  BurnEngine.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI
import Combine

/// 高性能网络流量消耗与测速核心引擎
/// 采用零内存增长流式读取设计（Zero-Allocation Stream），支持多线程动态伸缩、定量自动切断与后台保活
public final class BurnEngine: ObservableObject {
    public static let shared = BurnEngine()

    // MARK: - 响应式状态发布属性

    /// 引擎是否处于运行状态
    @Published public var isRunning = false

    /// 是否处于用户主动暂停状态
    @Published public var isPaused = false

    /// 累计已消耗的字节数（Byte）
    @Published public var totalBytesBurned: Int64 = 0

    /// 当前瞬时速率（Byte/s）
    @Published public var currentSpeedBytesPerSec: Double = 0

    /// 历史峰值速率（Byte/s）
    @Published public var peakSpeedBytesPerSec: Double = 0

    /// 全程平均速率（Byte/s）
    @Published public var averageSpeedBytesPerSec: Double = 0

    /// 最近 60 秒速率采样历史（用于画布走势图渲染）
    @Published public var speedSamples: [SpeedSample] = []

    /// 基于当前速率推算的各周期消耗预测
    @Published public var prediction: TrafficPrediction = TrafficPrediction()

    /// 当前激活的并发拉取线程数（1 ~ 64）
    @Published public var activeThreads: Int = 8

    /// 定量自动切断阈值（字节数，nil 代表无上限）
    @Published public var targetQuotaBytes: Int64? = nil

    /// 带宽限速阈值（Byte/s，nil 代表不限速）
    @Published public var speedLimitBytesPerSec: Double? = nil

    /// 当前选中的测速目标节点
    @Published public var currentNode: BurnNode = NodePresetManager.defaultNodes[0]

    /// 是否启用后台音频长效保活
    @Published public var enableBackgroundExecution: Bool = true

    /// 是否启用灵动岛与实时活动更新
    @Published public var enableLiveActivity: Bool = true

    /// 本次任务启动时间
    @Published public var startTime: Date?

    /// 任务累计运行耗时（秒）
    @Published public var elapsedTime: TimeInterval = 0

    // MARK: - 私有属性

    /// 存储所有后台拉取任务句柄
    private var workerTasks: [Task<Void, Never>] = []

    /// 1 秒周期指标定时器订阅
    private var timerCancellable: AnyCancellable?

    /// 上一次采样点的累计字节数
    private var lastSampleBytes: Int64 = 0

    /// 上一次采样时间
    private var lastSampleTime: Date = Date()

    /// 令牌桶限速器实例
    private let speedLimiter = SpeedLimiter()

    /// 灵动岛管理器
    private let liveActivityManager = LiveActivityManager.shared

    // MARK: - 初始化

    private init() {
        // 从本地存储读取用户保存的默认并发线程数
        let savedThreads = UserDefaults.standard.integer(forKey: "burn_threads")
        if savedThreads >= 1 && savedThreads <= 64 {
            self.activeThreads = savedThreads
        }

        // 读取后台保活开关偏好
        if UserDefaults.standard.object(forKey: "burn_bg_exec") != nil {
            self.enableBackgroundExecution = UserDefaults.standard.bool(forKey: "burn_bg_exec")
        }
    }

    // MARK: - 核心控制接口

    /// 启动网络拉取任务（点火）
    public func start() {
        guard !isRunning else { return }
        guard let targetUrl = currentNode.url else { return }

        isRunning = true
        isPaused = false
        startTime = Date()
        lastSampleBytes = totalBytesBurned
        lastSampleTime = Date()

        // 1. 开启后台长效保活（无声循环音频）
        if enableBackgroundExecution {
            BackgroundKeepAlive.shared.start()
        }

        // 2. 启动灵动岛实时活动卡片
        if enableLiveActivity {
            liveActivityManager.startActivity(
                nodeName: currentNode.name,
                targetQuotaBytes: targetQuotaBytes,
                formattedQuota: targetQuotaBytes != nil ? ByteFormatter.formatFullBytes(targetQuotaBytes!) : nil
            )
        }

        // 3. 按照设定线程数并发启动流式读取 Worker
        spawnWorkers(targetUrl: targetUrl, count: activeThreads)

        // 4. 启动 1 秒心跳定时器计算速率和绘制走势图
        startMetricsTimer()

        HapticManager.notification(.success)
    }

    /// 终止拉取并释放所有资源
    public func stop() {
        guard isRunning else { return }

        isRunning = false
        isPaused = false

        // 取消并清空所有并发任务
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()

        timerCancellable?.cancel()
        timerCancellable = nil

        currentSpeedBytesPerSec = 0
        prediction = TrafficPrediction()

        // 停用后台保活
        BackgroundKeepAlive.shared.stop()

        // 结束灵动岛实时活动
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

    /// 从暂停中恢复拉取
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

    /// 动态调节并发线程数（无需重启引擎）
    public func updateThreads(_ count: Int) {
        let clamped = min(max(count, 1), 64)
        activeThreads = clamped
        UserDefaults.standard.set(clamped, forKey: "burn_threads")

        if isRunning && !isPaused, let url = currentNode.url {
            if clamped > workerTasks.count {
                // 需要增加线程
                let diff = clamped - workerTasks.count
                for _ in 0..<diff {
                    let task = createWorkerTask(targetUrl: url)
                    workerTasks.append(task)
                }
            } else if clamped < workerTasks.count {
                // 需要减少线程
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

    // MARK: - 多线程流式拉取核心（零内存分配机制）

    private func spawnWorkers(targetUrl: URL, count: Int) {
        workerTasks.forEach { $0.cancel() }
        workerTasks.removeAll()

        for _ in 0..<count {
            let task = createWorkerTask(targetUrl: targetUrl)
            workerTasks.append(task)
        }
    }

    /// 创建一个独立的流式下载工作协程
    /// 核心优势：使用 URLSession.bytes 流式分块，数据仅在 64KB 栈内存中过客式累计长度并即时销毁
    /// 彻底避免传统将数据存入 Data/RAM 导致的内存崩溃
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
                            // 清空缓冲区（重用内存空间）
                            buffer.removeAll(keepingCapacity: true)

                            // 令牌桶限速微秒级等待
                            await self.speedLimiter.throttle(chunkSize: chunkSize)

                            // 主线程原子累计已消耗字节并检查定量上限
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
                    // 网络抖动时微休眠后自动重连
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
        }
    }

    // MARK: - 1 秒心跳速率计算

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

        // 记录折线图采样点
        let sample = SpeedSample(timestamp: now, bytesPerSec: currentSpeed)
        self.speedSamples.append(sample)
        if self.speedSamples.count > 60 {
            self.speedSamples.removeFirst()
        }

        // 同步通知灵动岛与锁屏实时活动
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
