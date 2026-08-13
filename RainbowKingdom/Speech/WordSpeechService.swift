//
//  WordSpeechService.swift
//  RainbowKingdom
//
//  单词/短语朗读服务：优先使用本地 Kokoro-82M 神经网络语音（FluidAudio），
//  合成结果按词缓存到磁盘；Kokoro 不可用时回退到系统 AVSpeechSynthesizer。
//

import AVFoundation
import CryptoKit
import FluidAudio
import Foundation

@MainActor
final class WordSpeechService: NSObject, ObservableObject {
    static let shared = WordSpeechService()

    enum EngineState {
        case idle  // 尚未初始化
        case preparing  // 模型加载中
        case ready  // Kokoro 可用
        case unavailable  // Kokoro 不可用，使用系统语音
    }

    @Published private(set) var engineState: EngineState = .idle
    @Published private(set) var isSpeaking = false

    /// Kokoro 语速：1.0 为正常，越小越慢（0.8 ≈ 慢 20%，适合跟读）
    private let kokoroSpeed: Float = 0.8

    private var kokoro: KokoroAneManager?
    private let systemSynthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var speakTask: Task<Void, Never>?

    private override init() {
        super.init()
    }

    /// App 启动后调用一次：安装 bundle 内模型并预热 Kokoro（首次需编译模型，耗时十几秒）。
    func warmUp() {
        guard engineState == .idle else { return }
        engineState = .preparing

        Task {
            // 模型已随 App 打包，禁止 FluidAudio 联网下载
            ModelHub.offlineMode = true

            let installed = await Task.detached(priority: .utility) {
                KokoroModelInstaller.installIfNeeded()
            }.value

            guard installed else {
                engineState = .unavailable
                return
            }

            do {
                let manager = KokoroAneManager()
                try await manager.initialize()
                kokoro = manager
                engineState = .ready
                print("✅ Kokoro TTS 就绪")
            } catch {
                engineState = .unavailable
                print("⚠️ Kokoro 初始化失败，回退系统语音: \(error)")
            }
        }
    }

    /// 朗读一个英文单词或短语。重复点击会打断上一次播放。
    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        speakTask?.cancel()
        stopPlayback()

        speakTask = Task {
            isSpeaking = true
            defer { isSpeaking = false }

            activateAudioSession()

            // 1. 磁盘缓存直接播（缓存键包含语速，改语速后旧缓存自动失效）
            let cacheURL = Self.cacheFileURL(for: trimmed, speed: kokoroSpeed)
            if let cacheURL, FileManager.default.fileExists(atPath: cacheURL.path) {
                play(fileURL: cacheURL)
                return
            }

            // 2. Kokoro 合成
            if engineState == .ready, let kokoro {
                do {
                    let wav = try await kokoro.synthesize(text: trimmed, speed: kokoroSpeed)
                    guard !Task.isCancelled else { return }
                    if let cacheURL {
                        try? wav.write(to: cacheURL)
                    }
                    play(data: wav)
                    return
                } catch {
                    print("⚠️ Kokoro 合成失败，回退系统语音: \(error)")
                }
            }

            // 3. 系统语音兜底
            speakWithSystemVoice(trimmed)
        }
    }

    // MARK: - 播放

    private func activateAudioSession() {
        // .playback 保证侧边静音开关打开时也有声音
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    private func play(fileURL: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            self.player = player
            player.play()
        } catch {
            print("⚠️ 播放缓存音频失败: \(error)")
            speakWithSystemVoice(fileURL.deletingPathExtension().lastPathComponent)
        }
    }

    private func play(data: Data) {
        do {
            let player = try AVAudioPlayer(data: data)
            self.player = player
            player.play()
        } catch {
            print("⚠️ 播放合成音频失败: \(error)")
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        if systemSynthesizer.isSpeaking {
            systemSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - 系统语音兜底

    private func speakWithSystemVoice(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.bestEnglishSystemVoice()
        utterance.rate = 0.4  // 系统语音同步放慢，与 Kokoro 慢速一致
        systemSynthesizer.speak(utterance)
    }

    private static func bestEnglishSystemVoice() -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-US" }
        return english.first { $0.quality == .premium }
            ?? english.first { $0.quality == .enhanced }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - 缓存

    /// 每个"单词+语速"一个 wav：<Application Support>/WordAudio/<sha256 前 16 位>.wav
    private static func cacheFileURL(for text: String, speed: Float) -> URL? {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else { return nil }

        let dir = appSupport.appendingPathComponent("WordAudio")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let digest = SHA256.hash(data: Data("\(text.lowercased())@\(speed)".utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined().prefix(16)
        return dir.appendingPathComponent("\(name).wav")
    }
}
