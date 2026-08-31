//
//  IPDiscoveryService.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

/// 多出口公网 IP 探测与网络诊断服务
public final class IPDiscoveryService: ObservableObject {
    public static let shared = IPDiscoveryService()

    /// 国内/默认直连出口诊断结果
    @Published public var localIP: IPProbeResult?

    /// Cloudflare Anycast 全球出口诊断结果
    @Published public var cloudflareIP: IPProbeResult?

    /// 是否正在探测中
    @Published public var isProbing = false

    private init() {}

    /// 同时并发探测多出口信息
    public func probeAll() async {
        await MainActor.run { isProbing = true }

        async let localTask = probeLocalDomesticEgress()
        async let cfTask = probeCloudflareGlobalEgress()

        let (local, cf) = await (localTask, cfTask)

        await MainActor.run {
            self.localIP = local
            self.cloudflareIP = cf
            self.isProbing = false
        }
    }

    /// 探测国内直连出口网络详情
    public func probeLocalDomesticEgress() async -> IPProbeResult? {
        let startTime = Date()
        guard let url = URL(string: "https://ipapi.co/json/") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 6.0
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

            let (data, response) = try await URLSession.shared.data(for: request)
            let rtt = Int(Date().timeIntervalSince(startTime) * 1000)

            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ip = json["ip"] as? String else {
                return await fallbackLocalProbe()
            }

            return IPProbeResult(
                ip: ip,
                country: (json["country_name"] as? String) ?? "中国",
                countryCode: (json["country_code"] as? String) ?? "CN",
                region: (json["region"] as? String) ?? "",
                city: (json["city"] as? String) ?? "",
                isp: (json["org"] as? String) ?? "本地运营商",
                asn: (json["asn"] as? String) ?? "",
                egressType: "国内直连出口",
                latencyMs: rtt
            )
        } catch {
            return await fallbackLocalProbe()
        }
    }

    /// 备选轻量级 IP 探测接口
    private func fallbackLocalProbe() async -> IPProbeResult? {
        guard let url = URL(string: "https://api.ipify.org?format=json") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ip = json["ip"] as? String {
                return IPProbeResult(
                    ip: ip,
                    country: "中国",
                    countryCode: "CN",
                    isp: "本地网络",
                    egressType: "本地出口"
                )
            }
        } catch {}
        return nil
    }

    /// 探测 Cloudflare 全球出口与边缘节点机房 (Colo)
    public func probeCloudflareGlobalEgress() async -> IPProbeResult? {
        let startTime = Date()
        guard let url = URL(string: "https://1.1.1.1/cdn-cgi/trace") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 6.0
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

            let (data, response) = try await URLSession.shared.data(for: request)
            let rtt = Int(Date().timeIntervalSince(startTime) * 1000)

            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let traceString = String(data: data, encoding: .utf8) else {
                return nil
            }

            var dict: [String: String] = [:]
            for line in traceString.components(separatedBy: "\n") {
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 {
                    dict[parts[0]] = parts[1]
                }
            }

            guard let ip = dict["ip"] else { return nil }
            let loc = dict["loc"] ?? "US"
            let colo = dict["colo"] ?? "CF"

            return IPProbeResult(
                ip: ip,
                country: loc,
                countryCode: loc,
                city: "边缘机房: \(colo)",
                isp: "Cloudflare Anycast",
                asn: "AS13335",
                egressType: "Cloudflare 全球出口",
                latencyMs: rtt
            )
        } catch {
            return nil
        }
    }

    /// 测试目标 URL 的往返网络延时 (Ping RTT)
    public func pingNode(_ nodeUrl: URL) async -> Int? {
        let startTime = Date()
        var request = URLRequest(url: nodeUrl)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 4.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) {
                let rtt = Int(Date().timeIntervalSince(startTime) * 1000)
                return rtt
            }
        } catch {
            // 使用 Range 请求 fallback
            request.httpMethod = "GET"
            request.setValue("bytes=0-0", forHTTPHeaderField: "Range")
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if (response as? HTTPURLResponse)?.statusCode != nil {
                    let rtt = Int(Date().timeIntervalSince(startTime) * 1000)
                    return rtt
                }
            } catch {}
        }
        return nil
    }
}
