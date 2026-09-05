//
//  SoundEffects.swift
//  RainbowKingdom
//
//  答题音效：答对 / 答错 / 完成练习 / 点击。
//  不依赖音频素材，启动时用正弦波合成几段很短的 PCM，放在内存里用 AVAudioPlayer 播放，
//  同时配合触觉反馈。
//

import AVFoundation
import UIKit

@MainActor
final class SoundEffects {
    static let shared = SoundEffects()

    enum Effect: CaseIterable {
        case correct  // 叮-叮 上行两音
        case wrong  // 低沉短促的"嗡"
        case complete  // 三音上行小旋律
        case tap  // 很轻的一声
    }

    /// 全局开关（设置页可控），默认开
    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEffects.enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEffects.enabled") }
    }

    private var players: [Effect: AVAudioPlayer] = [:]
    private let sampleRate: Double = 22_050

    private init() {
        for effect in Effect.allCases {
            if let player = try? AVAudioPlayer(data: Self.wavData(for: effect, sampleRate: sampleRate)) {
                player.prepareToPlay()
                player.volume = effect == .tap ? 0.35 : 0.8
                players[effect] = player
            }
        }
    }

    /// 播放音效并给触觉反馈
    func play(_ effect: Effect) {
        switch effect {
        case .correct: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .wrong: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .complete: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .tap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        guard Self.isEnabled, let player = players[effect] else { return }

        // 保证静音键打开时也有声音；和朗读共用 playback 类别
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback && session.category != .playAndRecord {
            try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        }
        try? session.setActive(true)

        player.currentTime = 0
        player.play()
    }

    // MARK: - 合成

    private struct Note {
        let frequency: Double
        let duration: Double  // 秒
        let gap: Double  // 与下一音之间的间隔
        var shape: Double = 1  // 1 纯正弦；>1 混入少量泛音，声音更亮
    }

    private static func notes(for effect: Effect) -> [Note] {
        switch effect {
        case .correct:
            return [Note(frequency: 880, duration: 0.10, gap: 0.03), Note(frequency: 1320, duration: 0.18, gap: 0)]
        case .wrong:
            return [Note(frequency: 220, duration: 0.14, gap: 0.05, shape: 2), Note(frequency: 185, duration: 0.20, gap: 0, shape: 2)]
        case .complete:
            return [
                Note(frequency: 660, duration: 0.11, gap: 0.02), Note(frequency: 880, duration: 0.11, gap: 0.02),
                Note(frequency: 1100, duration: 0.11, gap: 0.02), Note(frequency: 1320, duration: 0.28, gap: 0),
            ]
        case .tap:
            return [Note(frequency: 1000, duration: 0.04, gap: 0)]
        }
    }

    /// 生成 16-bit 单声道 WAV
    private static func wavData(for effect: Effect, sampleRate: Double) -> Data {
        var samples: [Int16] = []
        for note in notes(for: effect) {
            let count = Int(note.duration * sampleRate)
            for i in 0..<count {
                let t = Double(i) / sampleRate
                let progress = Double(i) / Double(max(count - 1, 1))
                // 包络：5% 起音，之后指数衰减，避免爆音
                let attack = min(1, progress / 0.05)
                let decay = pow(1 - progress, 1.6)
                let envelope = attack * decay
                var value = sin(2 * .pi * note.frequency * t)
                if note.shape > 1 {
                    value = 0.7 * value + 0.3 * sin(2 * .pi * note.frequency * 2 * t)
                }
                samples.append(Int16(max(-1, min(1, value * envelope)) * 32_000))
            }
            samples.append(contentsOf: [Int16](repeating: 0, count: Int(note.gap * sampleRate)))
        }
        // 结尾补一点静音，防止播放器截断
        samples.append(contentsOf: [Int16](repeating: 0, count: Int(0.03 * sampleRate)))

        var data = Data()
        let byteRate = UInt32(sampleRate) * 2
        let dataSize = UInt32(samples.count * 2)
        func append<T: FixedWidthInteger>(_ value: T) {
            var v = value.littleEndian
            data.append(Data(bytes: &v, count: MemoryLayout<T>.size))
        }
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36 + dataSize))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1))  // PCM, mono
        append(UInt32(sampleRate)); append(byteRate)
        append(UInt16(2)); append(UInt16(16))  // block align, bits
        data.append(contentsOf: Array("data".utf8)); append(dataSize)
        for s in samples { append(s) }
        return data
    }
}
