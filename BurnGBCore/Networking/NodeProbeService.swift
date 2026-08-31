//
//  NodeProbeService.swift
//  BurnGBCore
//
//  节点可用性与延时探测服务。
//

import Foundation

/// 节点探测结果，只传递 HTTP 状态和耗时，不下载大文件。
public struct NodeProbeResult: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let nodeID: UUID
    public let statusCode: Int?
    public let latencyMilliseconds: Int?
    public let isReachable: Bool
    public let message: String?
    public let checkedAt: Date

    public init(
        nodeID: UUID,
        statusCode: Int?,
        latencyMilliseconds: Int?,
        isReachable: Bool,
        message: String? = nil,
        checkedAt: Date = Date()
    ) {
        self.id = UUID()
        self.nodeID = nodeID
        self.statusCode = statusCode
        self.latencyMilliseconds = latencyMilliseconds
        self.isReachable = isReachable
        self.message = message
        self.checkedAt = checkedAt
    }
}

/// 可取消的节点探测 actor。
public actor NodeProbeService {
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 5
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    /// 使用 HEAD 请求探测节点；服务器不支持 HEAD 时仅发送 1 字节 Range GET。
    public func probe(_ node: BurnNode) async -> NodeProbeResult {
        guard let url = node.url else {
            return NodeProbeResult(
                nodeID: node.id,
                statusCode: nil,
                latencyMilliseconds: nil,
                isReachable: false,
                message: "节点不是有效的 HTTPS 地址。"
            )
        }

        let first = await perform(method: "HEAD", url: url, range: nil)
        if first.isReachable || first.statusCode != 405 {
            return NodeProbeResult(
                nodeID: node.id,
                statusCode: first.statusCode,
                latencyMilliseconds: first.latencyMilliseconds,
                isReachable: first.isReachable,
                message: first.message
            )
        }

        let fallback = await perform(method: "GET", url: url, range: "bytes=0-0")
        return NodeProbeResult(
            nodeID: node.id,
            statusCode: fallback.statusCode,
            latencyMilliseconds: fallback.latencyMilliseconds,
            isReachable: fallback.isReachable,
            message: fallback.message
        )
    }

    /// 并发探测一组节点；TaskGroup 会随调用方取消而停止。
    public func probeAll(_ nodes: [BurnNode]) async -> [NodeProbeResult] {
        await withTaskGroup(of: NodeProbeResult.self, returning: [NodeProbeResult].self) { group in
            for node in nodes {
                group.addTask { await self.probe(node) }
            }
            var results: [NodeProbeResult] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.nodeID.uuidString < $1.nodeID.uuidString }
        }
    }

    private func perform(method: String, url: URL, range: String?) async -> (statusCode: Int?, latencyMilliseconds: Int?, isReachable: Bool, message: String?) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("BurnGB/2.0", forHTTPHeaderField: "User-Agent")
        if let range {
            request.setValue(range, forHTTPHeaderField: "Range")
        }

        let clock = ContinuousClock()
        let started = clock.now
        do {
            let (_, response) = try await session.data(for: request)
            let elapsed = started.duration(to: clock.now)
            let milliseconds = Int(max(0, durationMilliseconds(elapsed)))
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let reachable = statusCode.map { (200...399).contains($0) } ?? false
            return (statusCode, milliseconds, reachable, reachable ? nil : "HTTP \(statusCode ?? -1)")
        } catch is CancellationError {
            return (nil, nil, false, "探测已取消。")
        } catch {
            return (nil, nil, false, error.localizedDescription)
        }
    }

    private func durationMilliseconds(_ duration: Duration) -> Double {
        let parts = duration.components
        // duration(to:) 的方向在调用处已取反，统一处理可能出现的负值。
        let seconds = Double(parts.seconds) + Double(parts.attoseconds) / 1_000_000_000_000_000_000
        return abs(seconds * 1000)
    }
}
