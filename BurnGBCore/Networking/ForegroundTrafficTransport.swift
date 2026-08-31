//
//  ForegroundTrafficTransport.swift
//  BurnGBCore
//
//  前台 URLSession 数据传输层。只把 Data.count 交给 actor，不把 Data 跨线程传递。
//

import Foundation

/// 前台并发数据任务传输器。
/// 每个任务收到数据后立刻暂停，交由上层限速/配额处理，再恢复任务形成背压。
public final class ForegroundTrafficTransport: NSObject, @unchecked Sendable {
    public typealias EventHandler = @Sendable (TrafficNetworkEvent) -> Void

    private struct TaskMetadata: Sendable {
        let runID: RunID
        let workerID: Int
    }

    private let lock = NSLock()
    private var eventHandler: EventHandler?
    private var metadataByTaskID: [Int: TaskMetadata] = [:]
    private var tasksByID: [Int: URLSessionDataTask] = [:]
    private var suspendedTaskIDs: Set<Int> = []
    private var session: URLSession!

    public override init() {
        super.init()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 0
        configuration.waitsForConnectivity = false

        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.qualityOfService = .userInitiated
        // 初始化完成后才能将 self 作为 URLSession delegate。
        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: delegateQueue
        )
    }

    deinit {
        session.invalidateAndCancel()
    }

    /// 安装单一事件出口；事件只包含 Sendable 值。
    public func setEventHandler(_ handler: @escaping EventHandler) {
        lock.lock()
        eventHandler = handler
        lock.unlock()
    }

    /// 启动一个前台下载 worker。
    @discardableResult
    public func start(runID: RunID, workerID: Int, url: URL) -> Int {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("BurnGB/2.0", forHTTPHeaderField: "User-Agent")

        let task = session.dataTask(with: request)
        lock.lock()
        metadataByTaskID[task.taskIdentifier] = TaskMetadata(runID: runID, workerID: workerID)
        tasksByID[task.taskIdentifier] = task
        lock.unlock()
        task.resume()
        return task.taskIdentifier
    }

    /// 暂停指定网络任务，形成数据层背压；重复暂停不会增加系统计数。
    public func suspend(taskIdentifier: Int) {
        lock.lock()
        guard suspendedTaskIDs.insert(taskIdentifier).inserted,
              let task = tasksByID[taskIdentifier] else {
            lock.unlock()
            return
        }
        lock.unlock()
        task.suspend()
    }

    /// 恢复指定网络任务；只恢复由本类标记为暂停的任务。
    public func resume(taskIdentifier: Int) {
        lock.lock()
        guard suspendedTaskIDs.remove(taskIdentifier) != nil,
              let task = tasksByID[taskIdentifier] else {
            lock.unlock()
            return
        }
        lock.unlock()
        task.resume()
    }

    /// 取消某个 worker 的所有任务。
    public func cancel(workerID: Int) {
        let tasks: [URLSessionDataTask]
        lock.lock()
        tasks = metadataByTaskID.compactMap { key, metadata in
            metadata.workerID == workerID ? tasksByID[key] : nil
        }
        lock.unlock()
        tasks.forEach { $0.cancel() }
    }

    /// 暂停当前传输层中的所有任务。
    public func suspendAll() {
        lock.lock()
        let ids = Array(tasksByID.keys)
        lock.unlock()
        ids.forEach { suspend(taskIdentifier: $0) }
    }

    /// 恢复当前传输层中的所有任务。
    public func resumeAll() {
        lock.lock()
        let ids = Array(suspendedTaskIDs)
        lock.unlock()
        ids.forEach { resume(taskIdentifier: $0) }
    }

    /// 取消当前传输层中的所有任务。
    public func cancelAll() {
        lock.lock()
        let tasks = Array(tasksByID.values)
        lock.unlock()
        tasks.forEach { $0.cancel() }
    }

    /// 返回当前传输层中登记的任务数量。
    public var taskCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return tasksByID.count
    }

    private func task(for taskIdentifier: Int) -> URLSessionDataTask? {
        lock.lock()
        defer { lock.unlock() }
        return tasksByID[taskIdentifier]
    }

    private func metadata(for taskIdentifier: Int) -> TaskMetadata? {
        lock.lock()
        defer { lock.unlock() }
        return metadataByTaskID[taskIdentifier]
    }

    private func removeTask(_ taskIdentifier: Int) -> TaskMetadata? {
        lock.lock()
        defer { lock.unlock() }
        let metadata = metadataByTaskID.removeValue(forKey: taskIdentifier)
        tasksByID.removeValue(forKey: taskIdentifier)
        suspendedTaskIDs.remove(taskIdentifier)
        return metadata
    }

    private func send(_ event: TrafficNetworkEvent) {
        lock.lock()
        let handler = eventHandler
        lock.unlock()
        handler?(event)
    }
}

extension ForegroundTrafficTransport: URLSessionDataDelegate {
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let metadata = metadata(for: dataTask.taskIdentifier) else {
            completionHandler(.cancel)
            return
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        send(.response(runID: metadata.runID, workerID: metadata.workerID, statusCode: statusCode))

        // 只接受成功和重定向响应，避免把错误页面当作流量。
        if (200...399).contains(statusCode) {
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        guard let metadata = metadata(for: dataTask.taskIdentifier) else { return }

        // 在 delegate 队列中立刻暂停，保证系统不会无限制地继续向内存缓冲数据。
        suspend(taskIdentifier: dataTask.taskIdentifier)
        send(
            .bytes(
                runID: metadata.runID,
                workerID: metadata.workerID,
                taskIdentifier: dataTask.taskIdentifier,
                count: data.count
            )
        )
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let metadata = removeTask(task.taskIdentifier) else { return }

        if let error {
            send(
                .failed(
                    runID: metadata.runID,
                    workerID: metadata.workerID,
                    taskIdentifier: task.taskIdentifier,
                    message: error.localizedDescription
                )
            )
        } else {
            send(
                .finished(
                    runID: metadata.runID,
                    workerID: metadata.workerID,
                    taskIdentifier: task.taskIdentifier
                )
            )
        }
    }
}
