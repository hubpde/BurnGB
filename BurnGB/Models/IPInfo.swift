//
//  IPInfo.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

public struct IPProbeResult: Identifiable, Codable, Hashable {
    public var id: String { ip }
    public var ip: String
    public var country: String
    public var countryCode: String
    public var region: String
    public var city: String
    public var isp: String
    public var asn: String
    public var egressType: String // e.g. "国内直连", "Cloudflare 出口", "海外节点"
    public var latencyMs: Int?

    public init(
        ip: String,
        country: String = "未知",
        countryCode: String = "--",
        region: String = "",
        city: String = "",
        isp: String = "未知运营商",
        asn: String = "AS0",
        egressType: String = "默认出口",
        latencyMs: Int? = nil
    ) {
        self.ip = ip
        self.country = country
        self.countryCode = countryCode
        self.region = region
        self.city = city
        self.isp = isp
        self.asn = asn
        self.egressType = egressType
        self.latencyMs = latencyMs
    }

    public var displayLocation: String {
        let parts = [country, region, city].filter { !$0.isEmpty && $0 != "未知" }
        return parts.isEmpty ? "未知位置" : parts.joined(separator: " · ")
    }
}
