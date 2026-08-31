//
//  BurnCheckpointStore.swift
//  BurnGBCore
//
//  App 与 Widget 共享的轻量 checkpoint 存储。
//

import Foundation

/// 使用 App Group Application Support 保存可恢复任务快照。
/// 文件写入采用临时文件替换，避免应用被系统终止时产生半个 JSON 文件。
public actor BurnCheckpointStore {
    public static let appGroupIdentifier = "group.com.hubpde.BurnGB"
    private let fileManager: FileManager
    private let fileURL: URL?

    public init(
        suiteName: String = BurnCheckpointStore.appGroupIdentifier,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        let baseURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        self.fileURL = baseURL?.appendingPathComponent("burngb-checkpoint.json", isDirectory: false)
    }

    /// 保存当前任务 checkpoint。
    public func save(_ checkpoint: BurnCheckpoint) throws {
        guard let fileURL else { return }
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(checkpoint)
        let temporaryURL = fileURL.appendingPathExtension("tmp")
        try data.write(to: temporaryURL, options: .atomic)

        if fileManager.fileExists(atPath: fileURL.path) {
            _ = try fileManager.replaceItemAt(fileURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: fileURL)
        }
    }

    /// 读取上次保存的 checkpoint。
    public func load() throws -> BurnCheckpoint? {
        guard let fileURL, fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BurnCheckpoint.self, from: data)
    }

    /// 删除 checkpoint。
    public func clear() throws {
        guard let fileURL, fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }
}
