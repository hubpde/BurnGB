//
//  BurnNode.swift
//  BurnGBCore
//
//  测速节点领域模型。
//

import Foundation

/// 用户选择的网络流量目标节点。
public struct BurnNode: Identifiable, Codable, Hashable, Sendable {
    /// 稳定的节点标识。
    public let id: UUID
    /// 节点名称。
    public var name: String
    /// 节点下载地址。
    public var urlString: String
    /// 节点分组。
    public var group: String
    /// SF Symbols 图标名称。
    public var symbolName: String
    /// 是否为用户自行添加的节点。
    public var isCustom: Bool

    /// 经过安全校验的 URL。BurnGB 只接受 HTTPS 节点。
    public var url: URL? {
        guard let url = URL(string: urlString),
              url.scheme?.lowercased() == "https",
              let host = url.host,
              !host.isEmpty,
              url.user == nil,
              url.password == nil else {
            return nil
        }
        return url
    }

    public init(
        id: UUID = UUID(),
        name: String,
        urlString: String,
        group: String,
        symbolName: String = "network",
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.group = group
        self.symbolName = symbolName
        self.isCustom = isCustom
    }
}

/// 可以直接用于个人带宽测试的 HTTPS 示例节点。
///
/// 生产环境建议替换为自己拥有或明确获授权的 Range/持续流端点，
/// 不要把第三方软件包或大型安装镜像当作无限测速服务。
public enum BurnNodeCatalog {
    public static let builtIn: [BurnNode] = [
        BurnNode(
            name: "Cloudflare Speed",
            urlString: "https://speed.cloudflare.com/__down?bytes=104857600",
            group: "全球测速",
            symbolName: "cloud"
        ),
        BurnNode(
            name: "CacheFly Speed Test",
            urlString: "https://web1.cachefly.net/speedtest/downloading",
            group: "全球测速",
            symbolName: "arrow.down.circle"
        ),
        BurnNode(
            name: "Steam CDN",
            urlString: "https://cdn.akamai.steamstatic.com/steam/apps/1063730/extras/NW_Sword_Sorcery_2.gif",
            group: "全球测速",
            symbolName: "gamecontroller"
        )
    ]
}
