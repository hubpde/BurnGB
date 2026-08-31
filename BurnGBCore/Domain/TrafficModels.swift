//
//  TrafficModels.swift
//  BurnGBCore
//
//  流量任务的不可变领域数据与状态定义。
//

import Foundation

/// 一次点火任务的唯一标识。
public struct RunID: RawRepresentable, Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue.uuidString
    }
}

/// 引擎当前阶段。
public enum BurnPhase: String, Codable, Hashable, Sendable {
    case idle
    case starting
    case running
    case paused
    case stopping
    case completed
    case failed
}

/// 后台执行能力在界面中的真实状态。
public enum BackgroundExecutionState: String, Codable, Hashable, Sendable {
    case foreground
    case submitting
    case running
    case waitingForSystem
    case unavailable
    case expired
    case interrupted
}

/// 一次任务的配置。启动后通过 run ID 固化，避免运行中配置漂移。
public struct BurnConfiguration: Codable, Hashable, Sendable {
    public var node: BurnNode
    public var workerCount: Int
    /// 定量上限，nil 表示不设上限。
    public var quotaBytes: Int64?
    /// Byte/s 限速，nil 表示不限速。
    public var rateLimitBytesPerSecond: Double?
    /// 是否请求系统管理的 iOS 26 持续处理任务。
    public var requestsBackgroundContinuation: Bool

    public init(
        node: BurnNode,
        workerCount: Int = 8,
        quotaBytes: Int64? = nil,
        rateLimitBytesPerSecond: Double? = nil,
        requestsBackgroundContinuation: Bool = true
    ) {
        self.node = node
        self.workerCount = min(max(workerCount, 1), 64)
        self.quotaBytes = quotaBytes.flatMap { $0 > 0 ? $0 : nil }
        self.rateLimitBytesPerSecond = rateLimitBytesPerSecond.flatMap {
            $0.isFinite && $0 > 0 ? $0 : nil
        }
        self.requestsBackgroundContinuation = requestsBackgroundContinuation
    }
}

/// 由网络层送入引擎的事件。只传递字节数，不跨 actor 传递 Data。
public enum TrafficNetworkEvent: Sendable {
    case response(runID: RunID, workerID: Int, statusCode: Int)
    case bytes(runID: RunID, workerID: Int, taskIdentifier: Int, count: Int)
    case finished(runID: RunID, workerID: Int, taskIdentifier: Int)
    case failed(runID: RunID, workerID: Int, taskIdentifier: Int, message: String)
}

/// 配额账本处理分块后的结果。
public struct QuotaDecision: Sendable, Hashable {
    /// 网络层收到的总字节数（可能包含被配额截断的部分）。
    public let receivedBytes: Int64
    /// 本次允许计入展示统计的字节数。
    public let acceptedBytes: Int64
    /// 当前展示统计累计值。
    public let totalBytes: Int64
    /// 是否已经达到上限。
    public let reachedQuota: Bool

    public init(
        receivedBytes: Int64,
        acceptedBytes: Int64,
        totalBytes: Int64,
        reachedQuota: Bool
    ) {
        self.receivedBytes = receivedBytes
        self.acceptedBytes = acceptedBytes
        self.totalBytes = totalBytes
        self.reachedQuota = reachedQuota
    }
}

/// 速率走势图中的一个时间点。
public struct SpeedPoint: Codable, Hashable, Sendable, Identifiable {
    public let id: Date
    public let timestamp: Date
    public let bytesPerSecond: Double

    public init(timestamp: Date, bytesPerSecond: Double) {
        self.id = timestamp
        self.timestamp = timestamp
        self.bytesPerSecond = max(bytesPerSecond, 0)
    }
}

/// 供 UI、checkpoint 与实时活动使用的只读快照。
public struct TrafficSnapshot: Codable, Hashable, Sendable {
    public var runID: RunID?
    public var phase: BurnPhase
    public var backgroundState: BackgroundExecutionState
    public var nodeName: String
    public var totalBytes: Int64
    public var receivedBytes: Int64
    public var speedBytesPerSecond: Double
    public var peakSpeedBytesPerSecond: Double
    public var averageSpeedBytesPerSecond: Double
    public var workerCount: Int
    public var activeWorkerCount: Int
    public var quotaBytes: Int64?
    public var startedAt: Date?
    public var elapsedSeconds: TimeInterval
    public var lastUpdatedAt: Date
    public var lastError: String?
    /// 最近一分钟的速率采样，供 Swift Charts 使用。
    public var history: [SpeedPoint]

    public init(
        runID: RunID? = nil,
        phase: BurnPhase = .idle,
        backgroundState: BackgroundExecutionState = .foreground,
        nodeName: String = "未选择节点",
        totalBytes: Int64 = 0,
        receivedBytes: Int64 = 0,
        speedBytesPerSecond: Double = 0,
        peakSpeedBytesPerSecond: Double = 0,
        averageSpeedBytesPerSecond: Double = 0,
        workerCount: Int = 0,
        activeWorkerCount: Int = 0,
        quotaBytes: Int64? = nil,
        startedAt: Date? = nil,
        elapsedSeconds: TimeInterval = 0,
        lastUpdatedAt: Date = Date(),
        lastError: String? = nil,
        history: [SpeedPoint] = []
    ) {
        self.runID = runID
        self.phase = phase
        self.backgroundState = backgroundState
        self.nodeName = nodeName
        self.totalBytes = max(totalBytes, 0)
        self.receivedBytes = max(receivedBytes, 0)
        self.speedBytesPerSecond = max(speedBytesPerSecond, 0)
        self.peakSpeedBytesPerSecond = max(peakSpeedBytesPerSecond, 0)
        self.averageSpeedBytesPerSecond = max(averageSpeedBytesPerSecond, 0)
        self.workerCount = max(workerCount, 0)
        self.activeWorkerCount = max(activeWorkerCount, 0)
        self.quotaBytes = quotaBytes
        self.startedAt = startedAt
        self.elapsedSeconds = max(elapsedSeconds, 0)
        self.lastUpdatedAt = lastUpdatedAt
        self.lastError = lastError
        self.history = Array(history.suffix(60))
    }
}

/// App 重启后恢复任务所需的 checkpoint。
public struct BurnCheckpoint: Codable, Hashable, Sendable {
    public var configuration: BurnConfiguration
    public var snapshot: TrafficSnapshot
    public var wasRunning: Bool

    public init(
        configuration: BurnConfiguration,
        snapshot: TrafficSnapshot,
        wasRunning: Bool
    ) {
        self.configuration = configuration
        self.snapshot = snapshot
        self.wasRunning = wasRunning
    }
}

/// 引擎错误类型，便于 UI 显示明确原因。
public enum TrafficEngineError: LocalizedError, Sendable, Hashable {
    case invalidNode
    case alreadyRunning
    case notRunning
    case cannotChangeNodeWhileRunning
    case invalidConfiguration(String)
    case backgroundSubmissionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidNode:
            return "测速节点地址无效，仅支持 HTTPS。"
        case .alreadyRunning:
            return "当前已有流量任务正在运行。"
        case .notRunning:
            return "当前没有正在运行的流量任务。"
        case .cannotChangeNodeWhileRunning:
            return "运行中不能切换节点，请先暂停或终止任务。"
        case let .invalidConfiguration(message):
            return message
        case let .backgroundSubmissionFailed(message):
            return "后台任务提交失败：\(message)"
        }
    }
}
