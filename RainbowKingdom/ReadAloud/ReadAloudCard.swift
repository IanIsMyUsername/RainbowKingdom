//
//  ReadAloudCard.swift
//  RainbowKingdom
//
//  跟读卡片：先听示范，再按麦克风读，自动打分。
//  达到 passStars 或用完 maxAttempts 次机会后才允许继续（软门）。
//

import SwiftUI

struct ReadAloudCard: View {
    let target: String
    let chinese: String
    var passStars: Int = 2
    var maxAttempts: Int = 3
    var accent: Color = .teal
    /// (最好成绩星数, 是否达到通过线)
    let onFinished: (Int, Bool) -> Void

    @ObservedObject private var service = ReadAloudService.shared
    @ObservedObject private var speech = WordSpeechService.shared

    @State private var attempts = 0
    @State private var bestStars = 0
    @State private var lastResult: ReadAloudResult?
    @State private var isBusy = false
    @State private var permissionDenied = false
    @State private var didAutoPlay = false
    @State private var pulse = false

    private var passed: Bool { bestStars >= passStars }
    private var outOfAttempts: Bool { attempts >= maxAttempts }
    private var canContinue: Bool { passed || outOfAttempts }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.and.mic")
                    .foregroundColor(accent)
                Text("跟着读一读")
                    .font(.headline)
                Spacer()
                Text("第 \(min(attempts + 1, maxAttempts)) / \(maxAttempts) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 目标词 + 示范
            HStack(spacing: 12) {
                Text(target)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Button(action: { speech.speak(target) }) {
                    if speech.isPreparing {
                        ProgressView().tint(accent)
                    } else {
                        Image(systemName: speech.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.title2)
                            .foregroundColor(accent)
                    }
                }
                .buttonStyle(.plain)
            }
            Text(chinese)
                .font(.subheadline)
                .foregroundColor(.secondary)

            content

            if let result = lastResult {
                resultView(result)
            }

            buttons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1.5)
        )
        .task {
            // 先示范朗读，再在后台加载听力模型（首次要几十秒，不能让示范等它）
            if !didAutoPlay {
                didAutoPlay = true
                speech.speak(target)
            }
            await service.prepare()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    // MARK: - 中间区域：模型状态 / 麦克风

    @ViewBuilder
    private var content: some View {
        switch service.engineState {
        case .idle, .preparing:
            VStack(spacing: 8) {
                ProgressView()
                Text("正在准备听力模型…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 110)

        case .unavailable(let reason):
            VStack(spacing: 6) {
                Image(systemName: "mic.slash")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 110)

        case .ready:
            micButton
        }
    }

    private var micButton: some View {
        let recording = service.recordingState == .recording
        let processing = service.recordingState == .processing || (isBusy && !recording)
        return VStack(spacing: 10) {
            ZStack {
                if recording {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 96 + CGFloat(service.level) * 60, height: 96 + CGFloat(service.level) * 60)
                        .animation(.easeOut(duration: 0.1), value: service.level)
                } else if !processing && !canContinue {
                    Circle()
                        .stroke(accent.opacity(0.35), lineWidth: 3)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.12 : 0.96)
                }

                Button(action: tapMic) {
                    ZStack {
                        Circle()
                            .fill(recording ? Color.red : accent)
                            .frame(width: 84, height: 84)
                        if processing {
                            ProgressView().tint(.white).scaleEffect(1.3)
                        } else {
                            Image(systemName: recording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(processing || (canContinue && !recording && lastResult != nil && passed))
            }
            .frame(height: 130)

            Text(recording ? "在听… 读完会自动停下"
                 : processing ? "正在听你说的是什么…"
                 : permissionDenied ? "没有麦克风权限，请在系统设置里允许"
                 : lastResult == nil ? "点一下麦克风，然后读出这个词"
                 : (canContinue ? "" : "点麦克风再读一次"))
                .font(.caption)
                .foregroundColor(permissionDenied ? .red : .secondary)
        }
    }

    // MARK: - 结果

    private func resultView(_ result: ReadAloudResult) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < result.stars ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(i < result.stars ? .yellow : .gray.opacity(0.4))
                        .scaleEffect(i < result.stars ? 1.1 : 1)
                }
            }
            if result.heard {
                // 我听到：逐词着色（短语时能看出哪个词没对上）
                let targetWords = ReadAloudScorer.words(target)
                HStack(spacing: 4) {
                    Text("我听到：")
                        .foregroundColor(.secondary)
                    Text(result.transcript.isEmpty ? "…" : result.transcript)
                        .fontWeight(.semibold)
                        .foregroundColor(result.stars >= 2 ? .green : .red)
                }
                .font(.subheadline)
                if targetWords.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(Array(targetWords.enumerated()), id: \.offset) { i, w in
                            Text(w)
                                .font(.caption)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(
                                    Capsule().fill((i < result.wordMatches.count && result.wordMatches[i]) ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                )
                        }
                    }
                }
            }
            Text(result.message)
                .font(.subheadline)
                .foregroundColor(result.stars >= passStars ? .green : .orange)
                .multilineTextAlignment(.center)
        }
        .transition(.opacity)
    }

    // MARK: - 按钮

    @ViewBuilder
    private var buttons: some View {
        if case .unavailable = service.engineState {
            Button("跳过跟读，继续") { onFinished(0, true) }
                .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                .background(accent).cornerRadius(10)
        } else if canContinue, lastResult != nil {
            HStack(spacing: 14) {
                if !passed {
                    Text("已经很努力了，下次再练")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button(passed ? "读得好，继续" : "继续") { onFinished(bestStars, passed) }
                    .fontWeight(.semibold)
                    .foregroundColor(.white).padding(.horizontal, 22).padding(.vertical, 10)
                    .background(passed ? Color.green : accent).cornerRadius(10)
            }
        }
    }

    // MARK: - 动作

    private func tapMic() {
        if service.recordingState == .recording {
            service.stopRecording()
            return
        }
        guard !isBusy else { return }
        Task { @MainActor in
            isBusy = true
            defer { isBusy = false }

            guard await ReadAloudService.requestMicrophonePermission() else {
                permissionDenied = true
                return
            }
            permissionDenied = false
            withAnimation { lastResult = nil }
            let result = await service.recordAndEvaluate(target: target)
            // 没听到不消耗次数
            if result.heard { attempts += 1 }
            bestStars = max(bestStars, result.stars)
            withAnimation { lastResult = result }
            if result.heard {
                SoundEffects.shared.play(result.stars >= passStars ? .correct : .wrong)
            }
        }
    }
}

#Preview {
    ReadAloudCard(target: "elephant", chinese: "大象") { _, _ in }
        .padding()
}
