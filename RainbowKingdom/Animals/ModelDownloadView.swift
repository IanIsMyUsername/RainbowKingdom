//
//  ModelDownloadView.swift
//  RainbowKingdom
//
//  Stable Diffusion 模型下载界面：说明体积、显示进度、可取消。
//  下载状态保存在 StableDiffusionModelStore 单例里，关掉界面下载也会继续。
//

import SwiftUI

struct ModelDownloadView: View {
    /// 是否允许"先用表情玩"跳过（从练习进入时为 true，从设置进入时为 false）
    var allowSkip: Bool = true
    var onFinished: () -> Void = {}
    var onSkip: () -> Void = {}

    @ObservedObject private var store = StableDiffusionModelStore.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                Spacer(minLength: 10)

                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: [.teal, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                VStack(spacing: 10) {
                    Text("下载画画模型")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("动物大作战会在这台 iPad 上用本地 AI 模型画出每只小动物。\n模型约 \(StableDiffusionModelStore.formatBytes(StableDiffusionModelStore.totalBytes))，只需下载一次，建议连接 Wi-Fi。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                statusSection
                    .padding(.horizontal, 30)

                Spacer()

                buttons
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(store.state.isDownloading)
        .onChange(of: store.state) { _, newState in
            if newState == .installed {
                AnimalImageService.shared.modelAvailabilityChanged()
                onFinished()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch store.state {
        case .downloading(let completed, let total):
            VStack(spacing: 10) {
                ProgressView(value: Double(completed), total: Double(max(total, 1)))
                    .progressViewStyle(LinearProgressViewStyle(tint: .teal))
                    .scaleEffect(x: 1, y: 2.5, anchor: .center)
                HStack {
                    Text("正在下载…")
                    Spacer()
                    Text("\(StableDiffusionModelStore.formatBytes(completed)) / \(StableDiffusionModelStore.formatBytes(total))")
                    Text("\(Int(Double(completed) / Double(max(total, 1)) * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(.teal)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                Text("下载期间请保持 App 在前台")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.1)))

        case .installed:
            Label("模型已就绪", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)

        case .notInstalled:
            Text("下载完成后，第一次画图需要约一分钟准备模型，之后每张图大约 10 到 20 秒。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 12) {
            if store.state.isDownloading {
                Button("取消下载") {
                    store.cancelDownload()
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            } else if store.state != .installed {
                Button(action: { store.startDownload() }) {
                    Label(
                        store.state == .notInstalled ? "开始下载" : "重试",
                        systemImage: "arrow.down.circle.fill"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.teal, .green], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }

                if allowSkip {
                    Button("先用表情玩，以后再下载") {
                        onSkip()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ModelDownloadView()
}
