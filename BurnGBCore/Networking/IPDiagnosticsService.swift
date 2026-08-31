//
//  IPDiagnosticsService.swift
//  BurnGBCore
//
//  公网出口诊断服务，只请求小型 JSON/文本探针，不下载测速文件。
//

import Foundation

/// 公网出口信息。
public struct EgressInfo: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let ipAddress: String
    public let provider: String
    public let location: String
    public let latencyMilliseconds: Int?
    public let source: String
    public let checkedAt: Date

    public init(
        ipAddress: String,
        provider: String,
        location: String,
        latencyMilliseconds: Int?,
        source: String,
        checkedAt: Date = Date()
    ) {
        self.id = UUID()
        self.ipAddress = ipAddress
        self.provider = provider
        self.location = location
        self.latencyMilliseconds = latencyMilliseconds
        self.source = source
        self.checkedAt = checkedAt
    }
}

/// 多出口公网 IP 诊断 actor。
public actor IPDiagnosticsService {
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 6
        configuration.timeoutIntervalForResource = 6
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    /// 并发请求两个轻量出口探针。
    public func checkAll() async -> [EgressInfo] {
        await withTaskGroup(of: EgressInfo?.self, returning: [EgressInfo].self) { group in
            group.addTask { await self.checkIPAPI() }
            group.addTask { await self.checkCloudflareTrace() }
            var values: [EgressInfo] = []
            for await result in group {
                if let result { values.append(result) }
            }
            return values
        }
    }

    private func checkIPAPI() async -> EgressInfo? {
        guard let url = URL(string: "https://ipapi.co/json/") else { return nil }
        let clock = ContinuousClock()
        let start = clock.now
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ip = json["ip"] as? String else { return nil }
            let latency = milliseconds(start.duration(to: clock.now))
            let city = [json["region"] as? String, json["city"] as? String]
                .compactMap { $0 }
                .joined(separator: " · ")
            return EgressInfo(
                ipAddress: ip,
                provider: json["org"] as? String ?? "未知运营商",
                location: [json["country_name"] as? String, city]
                    .compactMap { $0 }
                    .joined(separator: " · "),
                latencyMilliseconds: latency,
                source: "ipapi.co"
            )
        } catch {
            return nil
        }
    }

    private func checkCloudflareTrace() async -> EgressInfo? {
        guard let url = URL(string: "https://1.1.1.1/cdn-cgi/trace") else { return nil }
        let clock = ContinuousClock()
        let start = clock.now
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let text = String(data: data, encoding: .utf8) else { return nil }
            var values: [String: String] = [:]
            for line in text.split(separator: "\n") {
                let pair = line.split(separator: "=", maxSplits: 1).map(String.init)
                if pair.count == 2 { values[pair[0]] = pair[1] }
            }
            guard let ip = values["ip"] else { return nil }
            return EgressInfo(
                ipAddress: ip,
                provider: "Cloudflare Anycast",
                location: "边缘节点 \(values["colo"] ?? "未知")",
                latencyMilliseconds: milliseconds(start.duration(to: clock.now)),
                source: "1.1.1.1/cdn-cgi/trace"
            )
        } catch {
            return nil
        }
    }

    private func milliseconds(_ duration: Duration) -> Int {
        let parts = duration.components
        let seconds = Double(parts.seconds) + Double(parts.attoseconds) / 1_000_000_000_000_000_000
        return max(0, Int((seconds * 1000).rounded()))
    }
}
