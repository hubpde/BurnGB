//
//  IPInfo.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

/// 多出口 IP 探测诊断结果模型
public struct IPProbeResult: Identifiable, Codable, Hashable {
    /// 唯一标识（使用 IP 作为主键）
    public var id: String { ip }
    /// 公网 IP 地址
    public var ip: String
    /// 国家/地区名称
    public var country: String
    /// 国家/地区代码（如 CN, US）
    public var countryCode: String
    /// 省份/大区
    public var region: String
    /// 城市
    public var city: String
    /// 网络运营商 ISP
    public var isp: String
    /// 自治系统编号 ASN
    public var asn: String
    /// 出口类型描述（如：国内直连、Cloudflare 全球出口）
    public var egressType: String
    /// 探测往返延时 RTT（毫秒）
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

    /// 拼接格式化后的地理归属地展示字符串
    public var displayLocation: String {
        let parts = [country, region, city].filter { !$0.isEmpty && $0 != "未知" }
        return parts.isEmpty ? "未知位置" : parts.joined(separator: " · ")
    }
}
