//
//  ModelWarmUp.swift
//  RainbowKingdom
//
//  安装后首次启动的模型预热：把 Kokoro（朗读）、Stable Diffusion（画图）、Whisper（听力）
//  三套本地模型依次加载并编译一遍，Core ML 会把编译结果缓存，之后进练习就不用等。
//
//  每次重新安装（bundle 路径或版本变化）都会重新预热一次；用户可以跳过，
//  加载会在后台继续，全部完成后自动记录，下次不再弹出。
//

import CryptoKit
import SwiftUI

@MainActor
final class ModelWarmUpCoordinator: ObservableObject {
    static let shared = ModelWarmUpCoordinator()

    enum StepState: Equatable {
        case pending
        case running
        case done(seconds: Int)
        case unavailable(String)
        case skipped  // 模型没打包
    }

    struct Step: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        var state: StepState = .pending
    }

    @Published private(set) var steps: [Step] = [
        Step(id: "kokoro", title: "朗读", subtitle: "Kokoro 语音合成", icon: "speaker.wave.2.fill", color: .blue),
        Step(id: "sd", title: "画图", subtitle: "Stable Diffusion 动物配图", icon: "paintpalette.fill", color: .teal),
        Step(id: "whisper", title: "听力", subtitle: "Whisper 跟读识别", icon: "waveform.and.mic", color: .purple),
    ]
    @Published private(set) var isRunning = false
    @Published private(set) var isFinished = false

    private var runTask: Task<Void, Never>?
    private static let markerKey = "modelWarmUp.completedInstallIdentity"

    private init() {}

    var progress: Double {
        let done = steps.filter {
            switch $0.state {
            case .done, .unavailable, .skipped: return true
            default: return false
            }
        }.count
        return Double(done) / Double(max(steps.count, 1))
    }

    // MARK: - 是否需要预热

    /// 标识"这一次安装"：bundle 版本 + bundle 路径 + bundle 修改时间。
    /// Xcode 每次装机 bundle 路径都会变，Core ML 编译缓存随之失效，所以要重新预热。
    static var installIdentity: String {
        let path = Bundle.main.bundlePath
        let version = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
        let short = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        let modified = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date)?
            .timeIntervalSince1970 ?? 0
        let raw = "\(short)|\(version)|\(path)|\(Int(modified))"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    static var needsWarmUp: Bool {
        UserDefaults.standard.string(forKey: markerKey) != installIdentity
    }

    /// 设置页"重新预热"用：清掉标记并把步骤状态归零（正在跑的时候不打断）
    func reset() {
        UserDefaults.standard.removeObject(forKey: Self.markerKey)
        guard !isRunning else { return }
        isFinished = false
        for i in steps.indices { steps[i].state = .pending }
    }

    // MARK: - 执行

    func start() {
        guard runTask == nil, !isFinished else { return }
        isRunning = true
        runTask = Task { @MainActor in
            defer {
                isRunning = false
                runTask = nil
            }
            await runStep("kokoro") { await Self.warmUpKokoro() }
            await runStep("sd") { await Self.warmUpStableDiffusion() }
            await runStep("whisper") { await Self.warmUpWhisper() }

            isFinished = true
            UserDefaults.standard.set(Self.installIdentity, forKey: Self.markerKey)
            print("✅ 模型预热完成")
        }
    }

    private func runStep(_ id: String, _ body: () async -> StepState) async {
        guard let index = steps.firstIndex(where: { $0.id == id }) else { return }
        steps[index].state = .running
        let start = Date()
        var result = await body()
        if case .done = result {
            result = .done(seconds: Int(Date().timeIntervalSince(start).rounded()))
        }
        steps[index].state = result
    }

    private static func warmUpKokoro() async -> StepState {
        let speech = WordSpeechService.shared
        speech.warmUp()  // 幂等，App 启动时已经调过
        // 等它从 preparing 变成 ready / unavailable（首次最多几十秒）
        let deadline = ContinuousClock.now + .seconds(90)
        while speech.engineState == .idle || speech.engineState == .preparing, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(200))
        }
        switch speech.engineState {
        case .ready: return .done(seconds: 0)
        case .unavailable: return .unavailable("使用系统语音代替")
        default: return .unavailable("加载超时，进练习时会继续尝试")
        }
    }

    private static func warmUpStableDiffusion() async -> StepState {
        guard StableDiffusionModelStore.shared.isInstalled else {
            return .skipped
        }
        let service = AnimalImageService.shared
        await service.prepare()
        switch service.engineState {
        case .ready: return .done(seconds: 0)
        case .unavailable(let reason): return .unavailable(reason)
        case .modelMissing: return .skipped
        default: return .unavailable("未完成")
        }
    }

    private static func warmUpWhisper() async -> StepState {
        guard ReadAloudService.isModelBundled else { return .skipped }
        let service = ReadAloudService.shared
        await service.prepare()
        switch service.engineState {
        case .ready: return .done(seconds: 0)
        case .unavailable(let reason): return .unavailable(reason)
        default: return .unavailable("未完成")
        }
    }
}

// MARK: - 界面

struct ModelWarmUpView: View {
    @ObservedObject private var coordinator = ModelWarmUpCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    @State private var elapsed = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            VStack(spacing: 10) {
                Text(coordinator.isFinished ? "准备好了！" : "正在准备彩虹王国")
                    .font(.title)
                    .fontWeight(.bold)
                Text(coordinator.isFinished
                     ? "所有本地 AI 模型都已就绪，以后打开就很快。"
                     : "第一次打开需要把朗读、画图、听力三个本地模型准备好，大约 1 到 2 分钟。\n这一步只在安装后做一次。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 14) {
                ForEach(coordinator.steps) { step in
                    stepRow(step)
                }
            }
            .padding(.horizontal, 32)

            VStack(spacing: 8) {
                ProgressView(value: coordinator.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                HStack {
                    Text(coordinator.isFinished ? "完成" : "已用时 \(elapsed) 秒")
                    Spacer()
                    Text("\(Int(coordinator.progress * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)

            Spacer()

            if coordinator.isFinished {
                Button(action: { dismiss() }) {
                    Text("开始学习")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 320)
                        .background(
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                }
                .padding(.bottom, 30)
            } else {
                Button("先跳过，后台继续准备") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled(true)
        .onAppear { coordinator.start() }
        .onReceive(timer) { _ in
            if !coordinator.isFinished { elapsed += 1 }
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            // 全部完成后停一下让用户看到勾，再自动进入
            if finished {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
            }
        }
    }

    private func stepRow(_ step: ModelWarmUpCoordinator.Step) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: step.icon)
                    .foregroundColor(step.color)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.headline)
                Text(step.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            switch step.state {
            case .pending:
                Text("等待")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .running:
                HStack(spacing: 6) {
                    ProgressView()
                    Text("准备中…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .done(let seconds):
                HStack(spacing: 6) {
                    if seconds > 0 {
                        Text("\(seconds) 秒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            case .skipped:
                Text("未打包，跳过")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .unavailable(let reason):
                HStack(spacing: 6) {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    ModelWarmUpView()
}
