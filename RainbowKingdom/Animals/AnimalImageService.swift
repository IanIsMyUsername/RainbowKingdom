//
//  AnimalImageService.swift
//  RainbowKingdom
//
//  「动物大作战」配图来源，按优先级：
//    1. 内存
//    2. App 内打包的图：bundle 里的 animal-<key>.png（或 AnimalImages/<key>.png）
//    3. 磁盘缓存：<Application Support>/AnimalImages/<key>-v1.png
//    4. 本机 Stable Diffusion 生成（需先下载模型，见 StableDiffusionModelStore）
//  都没有时返回 nil，界面回退到 CSV 里的表情。
//

import SwiftUI
import UIKit

@MainActor
final class AnimalImageService: ObservableObject {
    static let shared = AnimalImageService()

    enum EngineState: Equatable {
        case idle
        case modelMissing  // 模型未下载
        case preparing  // 模型加载/编译中
        case ready
        case unavailable(String)
    }

    @Published private(set) var engineState: EngineState = .idle
    /// 已就绪（内存中）的图片
    @Published private(set) var images: [String: UIImage] = [:]
    /// 正在生成中的单词 key
    @Published private(set) var generating: Set<String> = []
    /// 当前正在生成那张图的进度 0...1
    @Published private(set) var generationProgress: Double = 0

    /// 提示词模板或模型变化时递增，旧的生成缓存自动失效（打包图不受影响）
    private let cacheVersion = 1
    private let engine = StableDiffusionEngine()
    private let modelStore = StableDiffusionModelStore.shared
    private var prepareTask: Task<Void, Never>?
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    /// 串行队列尾部：同一时间只生成一张
    private var queueTail: Task<Void, Never>?

    static let negativePrompt =
        "realistic, photo, scary, dark, blurry, deformed, extra limbs, extra legs, mutated, text, watermark, signature"

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.releaseEngine() }
        }
    }

    // MARK: - 模型加载

    /// 加载模型（幂等）。返回时 engineState 不会是 idle/preparing。
    func prepare() async {
        if let prepareTask {
            await prepareTask.value
            return
        }
        if engineState == .ready { return }

        guard let dir = StableDiffusionModelStore.resolvedModelDirectory() else {
            engineState = .modelMissing
            return
        }
        engineState = .preparing

        let task = Task { @MainActor in
            do {
                try await engine.load(resourcesAt: dir)
                engineState = .ready
                print("✅ Stable Diffusion 就绪")
            } catch {
                engineState = .unavailable("模型加载失败: \(error.localizedDescription)")
                print("⚠️ Stable Diffusion 加载失败: \(error)")
            }
        }
        prepareTask = task
        await task.value
        prepareTask = nil
    }

    /// 释放模型内存（收到内存警告时调用；下次用到会重新加载）
    func releaseEngine() {
        guard engineState == .ready else { return }
        engine.unload()
        engineState = .idle
    }

    /// 模型刚下载好 / 被删除时，重置状态让下一次 prepare 重新判断
    func modelAvailabilityChanged() {
        if engineState == .modelMissing || engineState == .idle {
            engineState = .idle
        } else if !modelStore.isInstalled {
            engine.unload()
            engineState = .idle
        }
    }

    // MARK: - 取图

    /// 不需要生成就能拿到的图（内存 / 打包 / 磁盘缓存）
    func hasLocalImage(for animal: AnimalWord) -> Bool {
        let key = animal.cacheKey
        if images[key] != nil { return true }
        if Self.bundledImageURL(for: key) != nil { return true }
        if let url = cacheURL(for: key), FileManager.default.fileExists(atPath: url.path) { return true }
        return false
    }

    /// 取一张动物图。不可用或失败时返回 nil，由界面回退表情。
    func image(for animal: AnimalWord) async -> UIImage? {
        let key = animal.cacheKey
        if let cached = images[key] { return cached }

        if let local = loadLocal(key: key) {
            images[key] = local
            return local
        }

        if let running = inFlight[key] {
            return await running.value
        }

        // 排队：等前一个生成任务完全结束再开始
        let previous = queueTail
        let task = Task<UIImage?, Never> { @MainActor in
            _ = await previous?.value
            if Task.isCancelled { return nil }

            // 排队期间可能已经被别的路径填好了
            if let cached = images[key] { return cached }

            generating.insert(key)
            generationProgress = 0
            defer {
                generating.remove(key)
                inFlight[key] = nil
            }

            await prepare()
            guard engineState == .ready else { return nil }

            let request = StableDiffusionEngine.Request(
                prompt: animal.imagePrompt,
                negativePrompt: Self.negativePrompt,
                stepCount: 20
            )
            do {
                let cgImage = try await engine.generate(request) { value in
                    Task { @MainActor in self.generationProgress = value }
                }
                guard let cgImage else {
                    print("⚠️ 生成结果为空 [\(animal.english)]")
                    return nil
                }
                let image = UIImage(cgImage: cgImage)
                images[key] = image
                saveToDisk(image, key: key)
                return image
            } catch {
                print("⚠️ 生成图片失败 [\(animal.english)]: \(error)")
                return nil
            }
        }
        inFlight[key] = task
        queueTail = Task { _ = await task.value }
        return await task.value
    }

    /// 后台把整张词表的图准备好；没模型时只加载本地已有的图。
    func prefetch(_ animals: [AnimalWord]) {
        Task { @MainActor in
            for animal in animals where images[animal.cacheKey] == nil {
                if let local = loadLocal(key: animal.cacheKey) {
                    images[animal.cacheKey] = local
                }
            }
            let missing = animals.filter { images[$0.cacheKey] == nil }
            guard !missing.isEmpty else { return }

            await prepare()
            guard engineState == .ready else { return }
            for animal in missing {
                _ = await image(for: animal)
            }
        }
    }

    // MARK: - 本地图片（打包 + 磁盘缓存）

    private func loadLocal(key: String) -> UIImage? {
        if let url = Self.bundledImageURL(for: key), let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        if let url = cacheURL(for: key), let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return nil
    }

    /// 打包图：Resources 目录会被 Xcode 拍平到 bundle 根，所以文件名用 animal- 前缀避免冲突；
    /// 也兼容放在 AnimalImages/ 文件夹引用里的 <key>.png。
    private static func bundledImageURL(for key: String) -> URL? {
        for ext in ["png", "jpg", "jpeg", "heic"] {
            if let url = Bundle.main.url(forResource: "animal-\(key)", withExtension: ext) { return url }
            if let url = Bundle.main.url(forResource: key, withExtension: ext, subdirectory: "AnimalImages") { return url }
        }
        return nil
    }

    private func cacheDirectory() -> URL? {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else { return nil }
        let dir = appSupport.appendingPathComponent("AnimalImages")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cacheURL(for key: String) -> URL? {
        cacheDirectory()?.appendingPathComponent("\(key)-v\(cacheVersion).png")
    }

    private func saveToDisk(_ image: UIImage, key: String) {
        guard let url = cacheURL(for: key), let data = image.pngData() else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// 清空生成缓存（词表或提示词调整后手动触发）；打包图不受影响
    func clearCache() {
        images.removeAll()
        if let dir = cacheDirectory() {
            try? FileManager.default.removeItem(at: dir)
        }
    }
}
