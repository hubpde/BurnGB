//
//  BackgroundKeepAlive.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import UIKit
import AVFAudio

/// 后台长效保活管理器
/// 结合 AVAudioSession 后台播放模式（静音音频无感循环）与 UIKit BackgroundTask
/// 确保 App 在锁屏、熄屏或切换至后台时，网络流式拉取任务不被 iOS 系统挂起冻结
public final class BackgroundKeepAlive: NSObject, AVAudioPlayerDelegate {
    public static let shared = BackgroundKeepAlive()

    // MARK: - 属性定义

    /// 静音音频播放器，用于向系统声明持续活跃的音频输出
    private var audioPlayer: AVAudioPlayer?

    /// 标记当前后台保活是否处于开启状态
    private(set) public var isRunning: Bool = false

    /// 系统后台任务标识符（UIKit 辅助保活）
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

    // MARK: - 初始化与通知监听

    private override init() {
        super.init()
        setupAudioPlayer()
        registerNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
    }

    // MARK: - 公开控制方法

    /// 开启后台长效保活（配置音频会话并启动静音循环）
    public func start() {
        guard !isRunning else { return }

        // 1. 配置系统音频会话为后台播放且允许与其他 App 音频混合
        configureAudioSession()

        // 2. 启动静音循环播放
        if let player = audioPlayer {
            player.numberOfLoops = -1 // 无限循环
            player.volume = 0.0       // 绝对静音，不干扰用户正常使用
            player.prepareToPlay()
            let success = player.play()
            if success {
                isRunning = true
            }
        }

        // 3. 申请系统后台执行时间片
        beginBackgroundTask()
    }

    /// 停止后台保活并释放音频会话
    public func stop() {
        guard isRunning else { return }

        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isRunning = false

        // 停用音频会话并通知其他 App 恢复原有音量
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // 忽略停用过程中的非关键错误
        }

        endBackgroundTask()
    }

    // MARK: - 音频会话配置

    /// 配置系统音频会话
    /// 使用 .playback 类别保证锁屏和切后台时进程存活
    /// 使用 .mixWithOthers 选项确保不抢占、不中断用户正在播放的音乐/播客
    @discardableResult
    private func configureAudioSession() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
            return true
        } catch {
            print("[BackgroundKeepAlive] 音频会话激活失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 在内存中构建极小体积的标准静音 WAV 音频数据并初始化 AVAudioPlayer
    /// 纯内存生成，无需依赖外部本地 mp3 文件，杜绝资源丢失风险
    private func setupAudioPlayer() {
        let silentWavData = createSilentWavData()
        do {
            audioPlayer = try AVAudioPlayer(data: silentWavData)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.0
            audioPlayer?.prepareToPlay()
        } catch {
            print("[BackgroundKeepAlive] 静音音频播放器初始化失败: \(error.localizedDescription)")
        }
    }

    /// 内存生成 1 秒的双声道 44.1kHz 16-bit 静音 PCM WAV 二进制数据
    private func createSilentWavData() -> Data {
        let sampleRate: Int32 = 44100
        let channels: Int16 = 2
        let bitsPerSample: Int16 = 16
        let durationSeconds: Int = 1

        let numSamples = Int(sampleRate) * durationSeconds
        let subchunk2Size = Int32(numSamples * Int(channels) * Int(bitsPerSample / 8))
        let chunkSize = 36 + subchunk2Size

        var data = Data()

        // RIFF chunk descriptor
        data.append(contentsOf: "RIFF".utf8)
        var chunkSizeBytes = chunkSize.littleEndian
        data.append(Data(bytes: &chunkSizeBytes, count: 4))
        data.append(contentsOf: "WAVE".utf8)

        // "fmt " sub-chunk
        data.append(contentsOf: "fmt ".utf8)
        var subchunk1Size: Int32 = 16.littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = 1.littleEndian // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = channels.littleEndian
        data.append(Data(bytes: &numChannels, count: 2))
        var sampleRateBytes = sampleRate.littleEndian
        data.append(Data(bytes: &sampleRateBytes, count: 4))
        var byteRate = (sampleRate * Int32(channels) * Int32(bitsPerSample / 8)).littleEndian
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = (channels * (bitsPerSample / 8)).littleEndian
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSampleBytes = bitsPerSample.littleEndian
        data.append(Data(bytes: &bitsPerSampleBytes, count: 2))

        // "data" sub-chunk
        data.append(contentsOf: "data".utf8)
        var dataSizeBytes = subchunk2Size.littleEndian
        data.append(Data(bytes: &dataSizeBytes, count: 4))

        // 填充全零 PCM 静音数据
        let zeroBytes = [UInt8](repeating: 0, count: Int(subchunk2Size))
        data.append(contentsOf: zeroBytes)

        return data
    }

    // MARK: - 系统中断与前后台通知监听

    private func registerNotifications() {
        let center = NotificationCenter.default

        // 音频被电话打断或系统抢占后恢复
        center.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        // 音频路由变更（如拔出耳机、断开蓝牙）
        center.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )

        // App 进入后台通知
        center.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        // App 回到前台通知
        center.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // 中断开始（如来电）
            break
        case .ended:
            // 中断结束，自动恢复静音播放
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isRunning {
                    configureAudioSession()
                    audioPlayer?.play()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard isRunning else { return }
        if audioPlayer?.isPlaying == false {
            configureAudioSession()
            audioPlayer?.play()
        }
    }

    @objc private func appDidEnterBackground() {
        guard isRunning else { return }
        beginBackgroundTask()
        if audioPlayer?.isPlaying == false {
            configureAudioSession()
            audioPlayer?.play()
        }
    }

    @objc private func appWillEnterForeground() {
        endBackgroundTask()
    }

    // MARK: - UIKit Background Task 辅助机制

    private func beginBackgroundTask() {
        endBackgroundTask()
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "BurnGB.KeepAlive") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
}
