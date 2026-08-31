# BurnGB 🔥

<p align="center">
  <b>iOS 原生高性能网络流量消耗与多出口测速工具</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=flat-square&logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.10%2B-orange?style=flat-square&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/UI-Pure%20SwiftUI%20Native-purple?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Live%20Activity-Dynamic%20Island-green?style=flat-square" alt="Dynamic Island">
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20IPA-black?style=flat-square&logo=githubactions" alt="CI">
</p>

---

## 📖 项目简介

**BurnGB** 是一款专为 iOS 设计的**纯原生网络流量消耗与带宽基准测试应用**。项目采用 **Swift + SwiftUI + Swift Concurrency** 编写，遵循 Apple 官方 Human Interface Guidelines，采用 100% 纯原生简洁美学设计，并深度适配 **iOS 官方实时活动（Live Activity with Frequent Updates）与灵动岛（Dynamic Island）全场景**。

---

## ✨ 核心特性

- 📱 **100% 官方原生设计美学（Pure Native SwiftUI）**：
  - 采用标准 iOS 分组布局、系统级层次颜色与 SF Pro 排版，纯净克制、清晰易读。
  - 触感引擎（Haptics）交互反馈。
- 🏝️ **官方实时活动与灵动岛（Live Activity & Dynamic Island）**：
  - 开启 `NSSupportsLiveActivitiesFrequentUpdates`，前后台高频推送最新网速与用量。
  - **紧凑形态（Compact）**：微小点火指示器 + 实时网速。
  - **极简形态（Minimal）**：灵动岛单一能量火焰。
  - **展开形态（Expanded）**：节点名称、并发线程、定量进度条、累计消耗量与速率。
  - **锁屏横幅（Lock Screen Activity）**：原生锁屏实时掌控测速进度。
- ⚡ **极致性能与内存零增长（Zero-Memory Allocation）**：
  - 针对大流量消耗设计的流式读取引擎，分块统计后即刻丢弃数据，即使单次消耗 **100GB / 1TB** 内存仍稳定维持在 **~15MB**，杜绝 OOM 闪退。
- 🚀 **1~64 线程动态并发**：
  - 支持在运行中动态滑块调节并发线程，实时拉满千兆 5G / Wi-Fi 7 带宽。
- 🎯 **智能定量自动切断**：
  - 支持预设（500MB、1GB、5GB、10GB、50GB 等）或自定义流量额度，达到目标自动停止并触发振动通知。
- 🎛️ **带宽限速控制**：
  - 内置令牌桶平滑限速算法，可限制拉取速率（如 50Mbps、100Mbps、300Mbps），避免挤占日常网络。
- 🌐 **多出口 IP 探测与延时测试**：
  - 一键探测国内直连出口与 Cloudflare 全球出口 IP、ASN 归属地，支持全节点 Ping 延时测试。
- 📈 **实时吞吐走势折线图**：
  - 实时绘制 60 秒带宽走势与速率预测（每分钟/每小时/每天/每月）。

---

## 🏗️ 架构与目录结构

```text
BurnGB/
├── .github/workflows/build-ipa.yml  # GitHub Actions 自动化编译打包 IPA 流程
├── project.yml                      # XcodeGen 自动化工程配置
├── README.md                        # 完整说明文档
├── BurnGB/
│   ├── BurnGBApp.swift              # App 入口
│   ├── Models/
│   │   ├── BurnNode.swift           # 内置与自定义节点数据模型
│   │   ├── BurnState.swift          # 流量、速率格式化与预测计算
│   │   ├── IPInfo.swift             # 多出口 IP 探测模型
│   │   └── BurnActivityAttributes.swift # 灵动岛共享数据契约
│   ├── Engine/
│   │   ├── BurnEngine.swift         # 零内存多线程并发流式核心
│   │   ├── SpeedLimiter.swift       # 令牌桶带宽限速器
│   │   └── IPDiscoveryService.swift # IP 探测与 Ping 测量服务
│   ├── DesignSystem/
│   │   ├── LiquidGradients.swift    # 原生主题配色定义
│   │   ├── LiquidGlassCard.swift    # 原生分组卡片修饰器
│   │   ├── LiquidGlassButton.swift  # 原生质感按钮
│   │   ├── LiquidGlassSlider.swift  # 原生滑块组件
│   │   ├── LiquidGaugeView.swift    # 速率大数字视图
│   │   └── HapticManager.swift      # 触感反馈管理器
│   ├── Views/
│   │   ├── MainDashboardView.swift  # 主控制仪表盘视图
│   │   ├── NodeSelectionView.swift  # 节点选择与 Ping 延时测试
│   │   ├── QuantitativeLimitSheet.swift # 定量上限配置弹窗
│   │   ├── SpeedLimiterSheet.swift  # 带宽限速配置弹窗
│   │   ├── SpeedChartView.swift     # 实时吞吐走势折线图
│   │   ├── IPInfoView.swift         # 多出口 IP 诊断视图
│   │   ├── SettingsView.swift       # 设置与偏好视图
│   │   └── AboutView.swift          # 关于与免责声明
│   └── Resources/
│       ├── Info.plist               # 权限声明、Live Activity 频繁更新与 ProMotion 配置
│       └── BurnGB.entitlements      # App Group 配置
└── BurnGBWidget/                    # 灵动岛与实时活动 Widget Extension
    ├── BurnGBWidgetBundle.swift     # Widget Bundle 入口
    ├── BurnActivityWidget.swift     # 紧凑/极简/展开岛屿与锁屏卡片
    └── Info.plist                   # Widget 扩展声明
```

---

## 🚀 自动化构建与 IPA 导出（GitHub Actions）

本项目已配置好 **GitHub Actions CI/CD**，无需本地拥有 Mac 或 Xcode 环境：

1. **推送代码到 GitHub 仓库**：
   ```bash
   git push origin main
   ```
2. **自动触发编译打包**：
   - 打开 GitHub 仓库的 **Actions** 标签页。
   - 工作流将在 macOS Runner 中自动调用 `xcodegen` 生成项目并完成 Release 编译与 IPA 打包。
3. **下载 IPA**：
   - 编译完成后，在 Actions 页面底部的 **Artifacts** 即可直接下载 **`BurnGB.ipa`**。

---

## 📱 自签安装方式

下载导出的 `BurnGB.ipa` 后，可通过以下常用自签工具安装到 iPhone / iPad：

- **TrollStore**（巨魔免重签永久安装，推荐）
- **AltStore / AltServer**
- **Sideloadly**
- **牛蛙助手 / 爱思助手**

---

## ⚠️ 免责声明

本项目仅供学习研究、网络基准吞吐测试、带宽故障排查以及个人套餐富余流量自用测试。严禁将本项目用于对未授权服务器进行压力测试或任何破坏性用途。使用本工具产生的一切流量资费及法律责任由使用者自行承担。
