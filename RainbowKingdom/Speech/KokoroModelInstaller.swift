//
//  KokoroModelInstaller.swift
//  RainbowKingdom
//
//  把打包在 App bundle 里的 Kokoro 模型安装到 FluidAudio 期望的缓存目录。
//  FluidAudio 在 iOS 上从 <Application Support>/fluidaudio/Models/ 读取 TTS 模型，
//  首次启动时把 bundle 内 BundledModels/ 下的内容复制过去，之后完全离线运行。
//

import Foundation

enum KokoroModelInstaller {
    /// bundle 内模型顶层目录名（对应工程根目录的 BundledModels 文件夹引用）
    private static let bundleFolderName = "BundledModels"
    /// 已安装标记文件名，模型内容变化时递增版本号触发重新安装
    private static let installedMarker = ".rainbowkingdom_installed_v2"

    /// FluidAudio 的 TTS 模型根目录：<Application Support>/fluidaudio/Models
    static func modelsDirectory() throws -> URL {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            throw CocoaError(.fileNoSuchFile)
        }
        return
            appSupport
            .appendingPathComponent("fluidaudio")
            .appendingPathComponent("Models")
    }

    /// 若尚未安装，把 bundle 内的模型复制到缓存目录。返回模型是否可用。
    @discardableResult
    static func installIfNeeded() -> Bool {
        let fm = FileManager.default

        guard
            let bundledRoot = Bundle.main.url(
                forResource: bundleFolderName, withExtension: nil)
        else {
            print("⚠️ bundle 中没有 \(bundleFolderName) 目录，Kokoro 不可用")
            return false
        }

        do {
            let modelsDir = try modelsDirectory()
            let marker = modelsDir.appendingPathComponent(installedMarker)
            if fm.fileExists(atPath: marker.path) {
                return true
            }

            try fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)

            // 复制 BundledModels 下的每个仓库目录（如 kokoro-82m-coreml）
            for item in try fm.contentsOfDirectory(
                at: bundledRoot, includingPropertiesForKeys: nil)
            {
                let dest = modelsDir.appendingPathComponent(item.lastPathComponent)
                // 上次可能复制到一半，删掉重来
                if fm.fileExists(atPath: dest.path) {
                    try fm.removeItem(at: dest)
                }
                try fm.copyItem(at: item, to: dest)
            }

            fm.createFile(atPath: marker.path, contents: Data())
            print("✅ Kokoro 模型已安装到 \(modelsDir.path)")
            return true
        } catch {
            print("⚠️ Kokoro 模型安装失败: \(error)")
            return false
        }
    }
}
