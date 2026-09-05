//
//  StableDiffusionModelStore.swift
//  RainbowKingdom
//
//  Stable Diffusion 1.5（Apple 官方 Core ML，6-bit palettized，split_einsum_v2）模型的定位与安装。
//
//  正常情况下模型随 App 打包（工程根目录 BundledStableDiffusion/<localFolderName>/，
//  蓝色文件夹引用，git 忽略），直接从 bundle 只读加载，无需网络。
//  如果打包目录不存在（比如为了缩小包体删掉了），退回到首次使用时从 Hugging Face 下载到
//  <Application Support>/StableDiffusion/<localFolderName>/。
//
//  只下载文生图需要的部分：TextEncoder、Unet、VAEDecoder、分词表。
//  SafetyChecker（608 MB）和 VAEEncoder（图生图用）都不需要。
//

import Foundation
import UIKit

@MainActor
final class StableDiffusionModelStore: NSObject, ObservableObject {
    static let shared = StableDiffusionModelStore()

    enum State: Equatable {
        case notInstalled
        case downloading(completed: Int64, total: Int64)
        case installed
        case failed(String)

        var isDownloading: Bool {
            if case .downloading = self { return true }
            return false
        }
    }

    @Published private(set) var state: State = .notInstalled

    /// Hugging Face 主站。国内网络不通时可改为 "https://hf-mirror.com"。
    static let baseURL = "https://huggingface.co"
    static let repo = "apple/coreml-stable-diffusion-v1-5-palettized"
    static let revision = "main"
    static let remoteFolder = "split_einsum_v2/compiled"
    /// 本地目录名；模型换版本时改这个名字，旧目录由 deleteModel 清理
    static let localFolderName = "sd15-palettized-split-einsum-v2"
    /// 打包目录名（工程根目录下的文件夹引用）
    static let bundledFolderName = "BundledStableDiffusion"
    private static let installedMarker = ".installed_v1"

    /// 需要下载的文件（相对路径, 字节数）。大小用于进度条和校验，来自 HF 仓库文件列表。
    static let manifest: [(path: String, size: Int64)] = [
        ("TextEncoder.mlmodelc/analytics/coremldata.bin", 207),
        ("TextEncoder.mlmodelc/coremldata.bin", 825),
        ("TextEncoder.mlmodelc/metadata.json", 2_771),
        ("TextEncoder.mlmodelc/model.mil", 208_229),
        ("TextEncoder.mlmodelc/weights/weight.bin", 139_866_304),
        ("Unet.mlmodelc/analytics/coremldata.bin", 207),
        ("Unet.mlmodelc/coremldata.bin", 1_207),
        ("Unet.mlmodelc/metadata.json", 3_705),
        ("Unet.mlmodelc/model.mil", 3_040_467),
        ("Unet.mlmodelc/weights/weight.bin", 645_167_616),
        ("VAEDecoder.mlmodelc/analytics/coremldata.bin", 207),
        ("VAEDecoder.mlmodelc/coremldata.bin", 755),
        ("VAEDecoder.mlmodelc/metadata.json", 2_472),
        ("VAEDecoder.mlmodelc/model.mil", 181_386),
        ("VAEDecoder.mlmodelc/weights/weight.bin", 98_993_280),
        ("merges.txt", 524_657),
        ("vocab.json", 862_328),
    ]

    static var totalBytes: Int64 { manifest.reduce(0) { $0 + $1.size } }

    private var downloadTask: Task<Void, Never>?

    private override init() {
        super.init()
        state = isInstalled ? .installed : .notInstalled
        if let bundled = Self.bundledModelDirectory() {
            print("📦 使用 App 内置的 Stable Diffusion 模型: \(bundled.lastPathComponent)")
        }
    }

    // MARK: - 路径

    /// App 内置的模型目录（存在且包含 Unet 时才返回）
    static func bundledModelDirectory() -> URL? {
        guard
            let url = Bundle.main.url(
                forResource: localFolderName, withExtension: nil, subdirectory: bundledFolderName)
        else { return nil }
        let unet = url.appendingPathComponent("Unet.mlmodelc")
        return FileManager.default.fileExists(atPath: unet.path) ? url : nil
    }

    var isBundled: Bool { Self.bundledModelDirectory() != nil }

    /// 实际用于加载的模型目录：内置优先，其次是下载目录（已完成安装时）
    static func resolvedModelDirectory() -> URL? {
        if let bundled = bundledModelDirectory() { return bundled }
        guard let dir = try? modelDirectory(),
              FileManager.default.fileExists(atPath: dir.appendingPathComponent(installedMarker).path)
        else { return nil }
        return dir
    }

    /// 下载安装目录（不是内置目录）
    static func modelDirectory() throws -> URL {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else { throw CocoaError(.fileNoSuchFile) }
        return appSupport
            .appendingPathComponent("StableDiffusion")
            .appendingPathComponent(localFolderName)
    }

    var isInstalled: Bool {
        Self.resolvedModelDirectory() != nil
    }

    /// 模型占用的磁盘空间（字节），未安装时为 0
    var installedBytes: Int64 {
        guard let dir = Self.resolvedModelDirectory(),
              let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey])
        else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    private static func remoteURL(for path: String) -> URL? {
        URL(string: "\(baseURL)/\(repo)/resolve/\(revision)/\(remoteFolder)/\(path)")
    }

    // MARK: - 下载

    /// 开始（或继续）下载。已下载完整的文件会跳过，所以中断后重试不会从头开始。
    func startDownload() {
        guard downloadTask == nil, !isInstalled else { return }
        state = .downloading(completed: 0, total: Self.totalBytes)

        // 900 MB 的下载要几分钟，iPad 自动锁屏会让系统挂起网络任务，期间不让屏幕休眠
        UIApplication.shared.isIdleTimerDisabled = true

        downloadTask = Task { @MainActor in
            defer {
                downloadTask = nil
                UIApplication.shared.isIdleTimerDisabled = false
            }
            do {
                try await downloadAll()
                // 让进度条停在 100% 一下，再进入已安装状态
                state = .downloading(completed: Self.totalBytes, total: Self.totalBytes)
                try? await Task.sleep(for: .milliseconds(600))
                state = .installed
                print("✅ Stable Diffusion 模型已安装")
            } catch is CancellationError {
                state = .notInstalled
                print("ℹ️ 模型下载已取消")
            } catch {
                state = .failed(Self.describe(error))
                print("⚠️ 模型下载失败: \(error)")
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
    }

    /// 删除已下载的模型和续传数据（释放约 0.9 GB）。内置模型无法删除。
    func deleteModel() {
        guard !isBundled else { return }
        cancelDownload()
        if let dir = try? Self.modelDirectory() {
            try? FileManager.default.removeItem(at: dir)
        }
        state = .notInstalled
    }

    private func downloadAll() async throws {
        let fm = FileManager.default
        let dir = try Self.modelDirectory()
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let total = Self.totalBytes
        var completed: Int64 = 0

        for item in Self.manifest {
            try Task.checkCancellation()
            let dest = dir.appendingPathComponent(item.path)

            // 已完整存在则跳过（支持断点续传到文件粒度）
            if let attrs = try? fm.attributesOfItem(atPath: dest.path),
               let size = attrs[.size] as? Int64, size == item.size {
                completed += item.size
                state = .downloading(completed: completed, total: total)
                continue
            }

            guard let url = Self.remoteURL(for: item.path) else {
                throw URLError(.badURL)
            }
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)

            let base = completed
            print("⬇️ 下载 \(item.path)（\(Self.formatBytes(item.size))）")
            let downloader = FileDownloader(resumeDataURL: dest.appendingPathExtension("resume")) { written in
                Task { @MainActor in
                    guard case .downloading(let current, _) = self.state else { return }
                    let value = min(base + written, total)
                    if value > current {
                        self.state = .downloading(completed: value, total: total)
                    }
                }
            }
            let tempURL = try await downloader.download(url)

            // 校验大小，防止 CDN 返回错误页面
            let attrs = try fm.attributesOfItem(atPath: tempURL.path)
            let size = (attrs[.size] as? Int64) ?? -1
            guard size == item.size else {
                try? fm.removeItem(at: tempURL)
                throw URLError(.cannotParseResponse, userInfo: [
                    NSLocalizedDescriptionKey: "\(item.path) 大小不符（\(size) / \(item.size)）",
                ])
            }

            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.moveItem(at: tempURL, to: dest)

            completed += item.size
            state = .downloading(completed: completed, total: total)
        }

        fm.createFile(atPath: dir.appendingPathComponent(Self.installedMarker).path, contents: Data())
    }

    private static func describe(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet: return "没有网络连接"
            case .timedOut: return "连接超时，请检查网络后重试"
            case .cannotFindHost, .cannotConnectToHost: return "无法连接到 Hugging Face"
            default: break
            }
        }
        return error.localizedDescription
    }

    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - 单文件下载器（带进度回调，支持取消）

/// 用 URLSession 下载任务下载一个文件到临时目录，进度通过回调上报。
/// 取消或失败时把 resumeData 存到 resumeDataURL，下次对同一文件继续下载而不是从头开始。
private final class FileDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let onProgress: @Sendable (Int64) -> Void
    private let resumeDataURL: URL
    private var continuation: CheckedContinuation<URL, Error>?
    private var task: URLSessionDownloadTask?
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 6 * 60 * 60
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    init(resumeDataURL: URL, onProgress: @escaping @Sendable (Int64) -> Void) {
        self.resumeDataURL = resumeDataURL
        self.onProgress = onProgress
    }

    func download(_ url: URL) async throws -> URL {
        defer { session.finishTasksAndInvalidate() }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                self.continuation = continuation
                let task: URLSessionDownloadTask
                if let data = try? Data(contentsOf: resumeDataURL), !data.isEmpty {
                    print("↩️ 从断点继续下载 \(url.lastPathComponent)")
                    task = session.downloadTask(withResumeData: data)
                } else {
                    task = session.downloadTask(with: url)
                }
                self.task = task
                task.resume()
            }
        } onCancel: {
            // 取消时保留已下载部分，下次继续
            task?.cancel { [weak self] data in self?.saveResumeData(data) }
        }
    }

    private func saveResumeData(_ data: Data?) {
        if let data, !data.isEmpty {
            try? data.write(to: resumeDataURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: resumeDataURL)
        }
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        onProgress(totalBytesWritten)
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64
    ) {
        onProgress(fileOffset)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 回调返回后系统会删掉 location，先挪到我们自己的临时文件
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("sd-download-\(UUID().uuidString)")
        do {
            try FileManager.default.moveItem(at: location, to: temp)
            try? FileManager.default.removeItem(at: resumeDataURL)
            if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                try? FileManager.default.removeItem(at: temp)
                finish(.failure(URLError(.badServerResponse, userInfo: [
                    NSLocalizedDescriptionKey: "服务器返回 \(http.statusCode)",
                ])))
                return
            }
            finish(.success(temp))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }  // 成功路径已在 didFinishDownloadingTo 处理
        // 网络中断 / 取消时系统会附带 resumeData；没有就清掉旧的，下次从头下
        let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        saveResumeData(resumeData)
        if (error as? URLError)?.code == .cancelled {
            finish(.failure(CancellationError()))
        } else {
            finish(.failure(error))
        }
    }

    private func finish(_ result: Result<URL, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}
