//
//  IPDiscoveryService.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

public final class IPDiscoveryService: ObservableObject {
    public static let shared = IPDiscoveryService()

    @Published public var localIP: IPProbeResult?
    @Published public var cloudflareIP: IPProbeResult?
    @Published public var isProbing = false

    private init() {}

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

    /// Probe domestic / default IP info
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
                isp: (json["org"] as? String) ?? "本地网络",
                asn: (json["asn"] as? String) ?? "",
                egressType: "国内出口",
                latencyMs: rtt
            )
        } catch {
            return await fallbackLocalProbe()
        }
    }

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
                    isp: "本地出口",
                    egressType: "本地网络"
                )
            }
        } catch {}
        return nil
    }

    /// Probe Cloudflare Global / CDN egress
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
                city: "Colo: \(colo)",
                isp: "Cloudflare Anycast",
                asn: "AS13335",
                egressType: "Cloudflare 全球出口",
                latencyMs: rtt
            )
        } catch {
            return nil
        }
    }

    /// Measure latency to a specific URL
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
            // Fallback with GET 1 byte range
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
