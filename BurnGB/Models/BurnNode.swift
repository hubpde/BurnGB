//
//  BurnNode.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

public struct BurnNode: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var urlString: String
    public var group: String
    public var iconName: String
    public var isCustom: Bool
    public var lastPingMs: Int?

    public var url: URL? {
        URL(string: urlString)
    }

    public init(
        id: UUID = UUID(),
        name: String,
        urlString: String,
        group: String,
        iconName: String = "bolt.horizontal.fill",
        isCustom: Bool = false,
        lastPingMs: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.group = group
        self.iconName = iconName
        self.isCustom = isCustom
        self.lastPingMs = lastPingMs
    }
}

public enum NodePresetManager {
    public static let defaultNodes: [BurnNode] = [
        // 国内运营商与云节点
        BurnNode(
            name: "和彩云高带宽",
            urlString: "https://img.mcloud.139.com/material_prod/material_media/20221128/1669626861087.png",
            group: "国内运营商",
            iconName: "antenna.radiowaves.left.and.right"
        ),
        BurnNode(
            name: "天翼云高速节点",
            urlString: "https://desk.ctyun.cn:8999/desktop-prod/software/windows_tob_client/15/64/202030001/CtyunClouddeskUniversal_2.3.0_202030001_x86_20240327104015_Setup.exe",
            group: "国内运营商",
            iconName: "cloud.fill"
        ),
        BurnNode(
            name: "腾讯云全球加速",
            urlString: "https://dldir1.qq.com/qqfile/qq/PCQQ9.7.19/QQ9.7.19.29259.exe",
            group: "国内运营商",
            iconName: "network"
        ),
        BurnNode(
            name: "网易云音乐 CDN",
            urlString: "https://d1.music.126.net/dmusic/NeteaseCloudMusic_Music_official_8.9.70.230522175024.apk",
            group: "国内运营商",
            iconName: "play.circle.fill"
        ),

        // 全球高速 CDN
        BurnNode(
            name: "Cloudflare Speed (100MB)",
            urlString: "https://speed.cloudflare.com/__down?bytes=104857600",
            group: "全球 CDN",
            iconName: "globe.asia.australia.fill"
        ),
        BurnNode(
            name: "Steam Akamai CDN",
            urlString: "https://cdn.akamai.steamstatic.com/steam/apps/1063730/extras/NW_Sword_Sorcery_2.gif",
            group: "全球 CDN",
            iconName: "gamecontroller.fill"
        ),
        BurnNode(
            name: "Steam Cloudflare CDN",
            urlString: "https://cdn.cloudflare.steamstatic.com/steam/apps/1063730/extras/NW_Sword_Sorcery_2.gif",
            group: "全球 CDN",
            iconName: "bolt.shield.fill"
        ),
        BurnNode(
            name: "Microsoft Akamai CDN",
            urlString: "https://img-prod-cms-rt-microsoft-com.akamaized.net/cms/api/am/imageFileData/RW16Ptm",
            group: "全球 CDN",
            iconName: "square.grid.2x2.fill"
        ),
        BurnNode(
            name: "Cachefly Speed Test",
            urlString: "https://web1.cachefly.net/speedtest/downloading",
            group: "全球 CDN",
            iconName: "arrow.down.forward.and.arrow.up.backward"
        ),
        BurnNode(
            name: "Apple CDN Test Asset",
            urlString: "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-36440/3E9034E5-B5E3-4BEB-8422-9213CE52643E/UniversalMac_14.0_23A344_Restore.ipsw",
            group: "全球 CDN",
            iconName: "apple.logo"
        )
    ]
}
