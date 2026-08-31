//
//  BackgroundTransferCoordinator.swift
//  BurnGB
//
//  iOS 官方 background URLSession 分段下载适配层。
//

import Foundation
import BurnGBCore

/// 后台文件下载层的事件。
enum BackgroundTransferEvent: Sendable {
    case bytes(runID: RunID, workerID: Int, count: Int)
    case segmentFinished(runID: RunID, workerID: Int)
    case failed(runID: RunID, workerID: Int, message: String)
}

/// 使用系统独立进程执行有限 Range 下载片段。
///
/// 这不是无限流保活机制：系统会决定调度时机，用户强制退出也会取消任务。
/// 每个完成的片段都会删除临时文件并自动排队下一片，尽量延长用户主动任务的后台执行时间。
final class BackgroundTransferCoordinator: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    typealias EventHandler = @Sendable (BackgroundTransferEvent) -> Void

    private struct SegmentMetadata: Sendable {
        let runID: RunID
        let workerID: Int
        let url: URL
        let rangeStart: Int64
        let rangeLength: Int64
        var bytesWritten: Int64
    }

    private let identifier = "com.hubpde.BurnGB.background-downloads"
    private let lock = NSLock()
    private var session: URLSession!
    private var metadataByTaskID: [Int: SegmentMetadata] = [:]
    private var tasksByID: [Int: URLSessionDownloadTask] = [:]
    private var eventHandler: EventHandler?
    private var completionHandler: (() -> Void)?
    private var shouldContinue = false

    override init() {
        super.init()

        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.waitsForConnectivity = true
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 24 * 60 * 60

        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.qualityOfService = .utility
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }

    deinit {
        session.invalidateAndCancel()
    }

    /// 安装事件出口。事件仅包含 Sendable 值。
    func setEventHandler(_ handler: @escaping EventHandler) {
        lock.lock()
        eventHandler = handler
        lock.unlock()
    }

    /// 开始一个后台 Range 片段链。
    func start(runID: RunID, workerID: Int, url: URL, segmentSize: Int64 = 8 * 1024 * 1024) {
        guard segmentSize > 0 else { return }
        lock.lock()
        shouldContinue = true
        lock.unlock()
        startSegment(
            SegmentMetadata(
                runID: runID,
                workerID: workerID,
                url: url,
                rangeStart: 0,
                rangeLength: segmentSize,
                bytesWritten: 0
            )
        )
    }

    /// 开始后台降级通道；每个 worker 以有限 Range 片段串联。
    func startFallback(runID: RunID, url: URL, workerCount: Int) {
        stopAll()
        let count = min(max(workerCount, 1), 4)
        for workerID in 0..<count {
            start(runID: runID, workerID: workerID, url: url)
        }
    }

    /// 停止所有后台片段并清空元数据。
    func stopAll() {
        lock.lock()
        shouldContinue = false
        let tasks = Array(tasksByID.values)
        metadataByTaskID.removeAll()
        tasksByID.removeAll()
        lock.unlock()

        // 在锁外取消，避免 URLSession 回调重入造成死锁。
        tasks.forEach { $0.cancel() }
    }

    /// AppDelegate 收到系统唤醒事件时保存 completion handler，并确保会话已建立。
    func receiveBackgroundEvents(identifier: String, completionHandler: @escaping () -> Void) {
        guard identifier == self.identifier else {
            completionHandler()
            return
        }
        lock.lock()
        self.completionHandler = completionHandler
        lock.unlock()
        session.getAllTasks { _ in }
    }

    private func startSegment(_ metadata: SegmentMetadata) {
        var request = URLRequest(url: metadata.url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 60
        let end = metadata.rangeStart + metadata.rangeLength - 1
        request.setValue("bytes=\(metadata.rangeStart)-\(end)", forHTTPHeaderField: "Range")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("BurnGB/2.0", forHTTPHeaderField: "User-Agent")

        let task = session.downloadTask(with: request)
        lock.lock()
        metadataByTaskID[task.taskIdentifier] = metadata
        tasksByID[task.taskIdentifier] = task
        lock.unlock()
        task.resume()
    }

    private func send(_ event: BackgroundTransferEvent) {
        lock.lock()
        let handler = eventHandler
        lock.unlock()
        handler?(event)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        lock.lock()
        guard var metadata = metadataByTaskID[downloadTask.taskIdentifier] else {
            lock.unlock()
            return
        }
        let delta = max(0, totalBytesWritten - metadata.bytesWritten)
        metadata.bytesWritten = totalBytesWritten
        metadataByTaskID[downloadTask.taskIdentifier] = metadata
        lock.unlock()

        if delta > 0 {
            send(.bytes(runID: metadata.runID, workerID: metadata.workerID, count: Int(min(delta, Int64(Int.max)))))
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // 系统提供的 location 是临时文件。BurnGB 只统计字节，不保留内容。
        try? FileManager.default.removeItem(at: location)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        lock.lock()
        guard let metadata = metadataByTaskID.removeValue(forKey: task.taskIdentifier) else {
            lock.unlock()
            return
        }
        tasksByID.removeValue(forKey: task.taskIdentifier)
        let continueChain = shouldContinue
        lock.unlock()

        if let error {
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled || continueChain {
                send(.failed(runID: metadata.runID, workerID: metadata.workerID, message: error.localizedDescription))
            }
            return
        }

        guard continueChain else {
            send(.segmentFinished(runID: metadata.runID, workerID: metadata.workerID))
            return
        }

        // 片段正常完成后移动到下一段 Range；文件已经在上一个 delegate 回调中删除。
        let next = SegmentMetadata(
            runID: metadata.runID,
            workerID: metadata.workerID,
            url: metadata.url,
            rangeStart: metadata.rangeStart + max(metadata.bytesWritten, metadata.rangeLength),
            rangeLength: metadata.rangeLength,
            bytesWritten: 0
        )
        startSegment(next)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock()
        let completion = completionHandler
        completionHandler = nil
        lock.unlock()

        guard let completion else { return }
        DispatchQueue.main.async {
            completion()
        }
    }
}
