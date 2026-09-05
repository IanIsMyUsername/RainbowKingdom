//
//  ReadAloudService.swift
//  RainbowKingdom
//
//  跟读识别：用 WhisperKit（openai_whisper-small.en，随 App 打包在 BundledWhisper/）
//  在本机把小朋友的声音转成文字，交给 ReadAloudScorer 打分。全程离线。
//
//  录音：AVAudioEngine → 16 kHz 单声道；用相对能量判断"说了 / 没说"，
//  说完停顿 0.9 秒自动结束，最长 5 秒。
//

import AVFoundation
import Foundation
import WhisperKit

@MainActor
final class ReadAloudService: ObservableObject {
    static let shared = ReadAloudService()

    enum EngineState: Equatable {
        case idle
        case preparing
        case ready
        case unavailable(String)
    }

    enum RecordingState: Equatable {
        case idle
        case recording
        case processing
    }

    @Published private(set) var engineState: EngineState = .idle
    @Published private(set) var recordingState: RecordingState = .idle
    /// 当前音量 0...1，给界面做动效
    @Published private(set) var level: Float = 0
    /// 本次录音里是否检测到过说话
    @Published private(set) var heardSpeech = false

    static let bundledFolderName = "BundledWhisper"
    static let modelFolderName = "openai_whisper-small.en"
    static let tokenizerFolderName = "tokenizer-small.en"

    static let maxDuration: TimeInterval = 5.0
    static let silenceToStop: TimeInterval = 0.9
    static let minDuration: TimeInterval = 0.5
    /// 相对能量阈值（WhisperKit 示例用 0.3）
    static let voiceThreshold: Float = 0.35

    private var whisper: WhisperKit?
    private var prepareTask: Task<Void, Never>?
    private let audio = AudioProcessor()
    private var monitorTask: Task<Void, Never>?
    private var recordingStart: Date?
    private var lastVoiceAt: Date?
    private var peakEnergy: Float = 0

    private init() {}

    // MARK: - 模型

    static func bundledModelURL() -> URL? {
        guard let url = Bundle.main.url(forResource: modelFolderName, withExtension: nil, subdirectory: bundledFolderName)
        else { return nil }
        let decoder = url.appendingPathComponent("TextDecoder.mlmodelc")
        return FileManager.default.fileExists(atPath: decoder.path) ? url : nil
    }

    static func bundledTokenizerURL() -> URL? {
        Bundle.main.url(forResource: tokenizerFolderName, withExtension: nil, subdirectory: bundledFolderName)
    }

    /// 模型是否随 App 打包（没有时跟读功能整体不可用，练习里直接跳过）
    static var isModelBundled: Bool { bundledModelURL() != nil }

    var isAvailable: Bool {
        if case .unavailable = engineState { return false }
        return Self.isModelBundled
    }

    /// 加载 Whisper（幂等）。首次会编译 Core ML 模型，约 20 到 40 秒；之后几秒。
    func prepare() async {
        if let prepareTask {
            await prepareTask.value
            return
        }
        if engineState == .ready { return }

        guard let modelURL = Self.bundledModelURL() else {
            engineState = .unavailable("App 里没有打包听力模型（BundledWhisper）")
            return
        }
        engineState = .preparing

        let task = Task { @MainActor in
            do {
                let config = WhisperKitConfig(
                    modelFolder: modelURL.path,
                    tokenizerFolder: Self.bundledTokenizerURL(),
                    verbose: false,
                    logLevel: .none,
                    prewarm: true,
                    load: true,
                    download: false
                )
                whisper = try await WhisperKit(config)
                engineState = .ready
                print("✅ WhisperKit 就绪")
            } catch {
                engineState = .unavailable("听力模型加载失败: \(error.localizedDescription)")
                print("⚠️ WhisperKit 加载失败: \(error)")
            }
        }
        prepareTask = task
        await task.value
        prepareTask = nil
    }

    func releaseEngine() {
        guard let whisper, recordingState == .idle else { return }
        Task { await whisper.unloadModels() }
        self.whisper = nil
        engineState = .idle
    }

    // MARK: - 权限

    static func requestMicrophonePermission() async -> Bool {
        await AudioProcessor.requestRecordPermission()
    }

    // MARK: - 录音 + 识别

    /// 录一段并打分：开始录音 → 说完停顿或到时自动结束（也可手动 stopRecording）→ 识别 → 打分。
    func recordAndEvaluate(target: String) async -> ReadAloudResult {
        await prepare()
        guard engineState == .ready else {
            return ReadAloudResult(target: target, transcript: "", stars: 0, similarity: 0, confidence: 0,
                                   wordMatches: Array(repeating: false, count: ReadAloudScorer.words(target).count))
        }

        do {
            try startRecording()
        } catch {
            print("⚠️ 录音启动失败: \(error)")
            return ReadAloudResult(target: target, transcript: "", stars: 0, similarity: 0, confidence: 0,
                                   wordMatches: Array(repeating: false, count: ReadAloudScorer.words(target).count))
        }

        // 等录音结束（自动或手动）
        while recordingState == .recording {
            try? await Task.sleep(for: .milliseconds(50))
        }

        let samples = Array(audio.audioSamples)
        let heard = heardSpeech && peakEnergy > 0.004
        defer { recordingState = .idle }

        guard heard else {
            return ReadAloudScorer.score(target: target, transcript: "", confidence: 0, heard: false)
        }

        let (transcript, confidence) = await transcribe(samples, hint: target)
        return ReadAloudScorer.score(target: target, transcript: transcript, confidence: confidence, heard: true)
    }

    private func startRecording() throws {
        guard recordingState == .idle else { return }
        heardSpeech = false
        level = 0
        peakEnergy = 0
        lastVoiceAt = nil

        try audio.startRecordingLive(callback: nil)
        recordingState = .recording
        recordingStart = Date()

        monitorTask?.cancel()
        monitorTask = Task { @MainActor in
            while recordingState == .recording, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                let energies = audio.relativeEnergy
                level = min(max(energies.last ?? 0, 0), 1)
                if let latest = audio.audioEnergy.last {
                    peakEnergy = max(peakEnergy, latest.avg)
                }

                let now = Date()
                let voice = AudioProcessor.isVoiceDetected(
                    in: energies, nextBufferInSeconds: 0.3, silenceThreshold: Self.voiceThreshold)
                if voice {
                    heardSpeech = true
                    lastVoiceAt = now
                }

                let elapsed = now.timeIntervalSince(recordingStart ?? now)
                if elapsed >= Self.maxDuration {
                    stopRecording()
                } else if heardSpeech, elapsed >= Self.minDuration,
                          let last = lastVoiceAt, now.timeIntervalSince(last) >= Self.silenceToStop {
                    stopRecording()
                }
            }
        }
    }

    /// 手动结束录音（自动停止也走这里）
    func stopRecording() {
        guard recordingState == .recording else { return }
        audio.stopRecording()
        monitorTask?.cancel()
        monitorTask = nil
        level = 0
        recordingState = .processing
    }

    private func transcribe(_ samples: [Float], hint: String) async -> (text: String, confidence: Double) {
        guard let whisper else { return ("", 0) }

        var options = DecodingOptions()
        options.language = "en"
        options.task = .transcribe
        options.temperature = 0
        options.temperatureFallbackCount = 2
        options.usePrefillPrompt = true
        options.skipSpecialTokens = true
        options.wordTimestamps = true
        options.suppressBlank = true
        options.noSpeechThreshold = 0.6
        options.compressionRatioThreshold = nil
        options.logProbThreshold = nil
        options.firstTokenLogProbThreshold = nil
        // WhisperKit 默认跳过音频末尾 1 秒防幻觉，单词录音往往不到 1 秒，会被整段跳掉
        options.windowClipTime = 0

        // 把目标词作为上文提示，识别会偏向这个词（近音词仍能区分）
        if let tokenizer = whisper.tokenizer {
            let promptTokens = tokenizer.encode(text: " " + hint)
                .filter { $0 < tokenizer.specialTokens.specialTokenBegin }
            if !promptTokens.isEmpty {
                options.promptTokens = promptTokens
            }
        }

        // 前后各补 0.5 秒静音：给模型一点上下文，也避免录音刚开始就说话被切掉
        let padding = [Float](repeating: 0, count: 8000)
        let padded = padding + samples + padding

        do {
            let results = try await whisper.transcribe(audioArray: padded, decodeOptions: options)
            let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            let words = results.flatMap(\.segments).flatMap { $0.words ?? [] }
            let confidence: Double
            if !words.isEmpty {
                confidence = Double(words.map(\.probability).reduce(0, +)) / Double(words.count)
            } else if let avg = results.flatMap(\.segments).map(\.avgLogprob).first {
                confidence = Double(exp(avg))
            } else {
                confidence = 0
            }
            print("🎤 跟读识别: \"\(text)\" (目标 \(hint), 置信度 \(String(format: "%.2f", confidence)))")
            return (text, confidence)
        } catch {
            print("⚠️ 识别失败: \(error)")
            return ("", 0)
        }
    }
}
