//
//  MultiplicationConfigView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct MultiplicationConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var configManager = PracticeConfigManager()
    
    // 英语翻译配置
    @State private var englishTranslationEnabled: Bool = true
    @State private var englishTranslationQuestionCount: Int = 30
    @State private var englishTranslationWeeks: Int = 2

    // 英语填空配置
    @State private var englishFillBlankEnabled: Bool = true
    @State private var englishFillBlankQuestionCount: Int = 10
    @State private var englishFillBlankWeeks: Int = 1

    // 加减法配置
    @State private var additionSubtractionEnabled: Bool = true
    @State private var additionSubtractionQuestionCount: Int = 10
    @State private var additionSubtractionMaxNumber: Int = 40

    // 乘法配置
    @State private var multiplicationEnabled: Bool = true
    @State private var multiplicationQuestionCount: Int = 10
    @State private var multiplicationMaxNumber: Int = 3

    // 动物大作战配置
    @State private var animalBattleEnabled: Bool = true
    @State private var animalBattleQuestionCount: Int = 10
    @State private var showModelDownload = false
    @State private var confirmDeleteModel = false
    @ObservedObject private var modelStore = StableDiffusionModelStore.shared
    
    var body: some View {
        NavigationView {
            Form {
                // 英语翻译练习配置
                Section(header: Text("英语翻译练习")) {
                    Toggle("启用英语翻译练习", isOn: $englishTranslationEnabled)
                        .tint(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("题目数量: \(englishTranslationQuestionCount)")
                            .font(.headline)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(englishTranslationQuestionCount) },
                            set: { englishTranslationQuestionCount = Int($0) }
                        ), in: 10...50, step: 1)
                        .accentColor(.blue)
                        
                        HStack {
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("50")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("单词时间范围: 最近 \(englishTranslationWeeks) 个月")
                            .font(.headline)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(englishTranslationWeeks) },
                            set: { englishTranslationWeeks = Int($0) }
                        ), in: 1...6, step: 1)
                        .accentColor(.purple)
                        
                        HStack {
                            Text("1个月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("6个月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 英语填空练习配置
                Section(header: Text("英语填空练习")) {
                    Toggle("启用英语填空练习", isOn: $englishFillBlankEnabled)
                        .tint(.purple)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("题目数量: \(englishFillBlankQuestionCount)")
                            .font(.headline)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(englishFillBlankQuestionCount) },
                            set: { englishFillBlankQuestionCount = Int($0) }
                        ), in: 5...30, step: 1)
                        .accentColor(.green)
                        
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("30")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("单词时间范围: 最近 \(englishFillBlankWeeks) 个月")
                            .font(.headline)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(englishFillBlankWeeks) },
                            set: { englishFillBlankWeeks = Int($0) }
                        ), in: 1...6, step: 1)
                        .accentColor(.purple)
                        
                        HStack {
                            Text("1个月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("6个月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 加减法练习配置
                Section(header: Text("加减法练习")) {
                    Toggle("启用加减法练习", isOn: $additionSubtractionEnabled)
                        .tint(.green)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("题目数量: \(additionSubtractionQuestionCount)")
                            .font(.headline)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(additionSubtractionQuestionCount) },
                            set: { additionSubtractionQuestionCount = Int($0) }
                        ), in: 5...30, step: 1)
                        .accentColor(.orange)
                        
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("30")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("数字范围: \(additionSubtractionMaxNumber) 以内")
                            .font(.headline)

                        Slider(value: Binding<Double>(
                            get: { Double(additionSubtractionMaxNumber) },
                            set: { additionSubtractionMaxNumber = Int($0) }
                        ), in: 10...100, step: 10)
                        .accentColor(.red)

                        HStack {
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 乘法练习配置
                Section(header: Text("乘法练习")) {
                    Toggle("启用乘法练习", isOn: $multiplicationEnabled)
                        .tint(.orange)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("题目数量: \(multiplicationQuestionCount)")
                            .font(.headline)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(multiplicationQuestionCount) },
                            set: { multiplicationQuestionCount = Int($0) }
                        ), in: 5...30, step: 1)
                        .accentColor(.blue)
                        
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("30")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("数字范围: 1 到 \(multiplicationMaxNumber - 1)")
                            .font(.headline)
                        
                        Text("说明：数字范围是 1 到 \(multiplicationMaxNumber - 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding<Double>(
                            get: { Double(multiplicationMaxNumber) },
                            set: { multiplicationMaxNumber = Int($0) }
                        ), in: 3...10, step: 1)
                        .accentColor(.green)
                        
                        HStack {
                            Text("1-2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("1-9")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 动物大作战配置
                Section(header: Text("动物大作战"), footer: Text("看图拼写动物单词。图片由本机 Stable Diffusion 模型生成，词表在 Resources/animals.csv 中维护。")) {
                    Toggle("启用动物大作战", isOn: $animalBattleEnabled)
                        .tint(.teal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("题目数量: \(animalBattleQuestionCount)")
                            .font(.headline)

                        Slider(value: Binding<Double>(
                            get: { Double(animalBattleQuestionCount) },
                            set: { animalBattleQuestionCount = Int($0) }
                        ), in: 3...20, step: 1)
                        .accentColor(.teal)

                        HStack {
                            Text("3")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("20")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    modelStatusRow
                }
            }
            .navigationTitle("练习配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveConfig()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .onAppear {
            loadConfig()
        }
    }
    
    /// 画画模型状态：已下载 / 下载中 / 未下载，附下载或删除操作
    @ViewBuilder
    private var modelStatusRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("画画模型（Stable Diffusion）")
                    .font(.headline)
                switch modelStore.state {
                case .installed where modelStore.isBundled:
                    Text("已随 App 内置，占用 \(StableDiffusionModelStore.formatBytes(modelStore.installedBytes))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .installed:
                    Text("已下载，占用 \(StableDiffusionModelStore.formatBytes(modelStore.installedBytes))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .downloading(let completed, let total):
                    Text("下载中 \(Int(Double(completed) / Double(max(total, 1)) * 100))%")
                        .font(.caption)
                        .foregroundColor(.teal)
                case .failed(let message):
                    Text("下载失败：\(message)")
                        .font(.caption)
                        .foregroundColor(.red)
                case .notInstalled:
                    Text("未下载，约 \(StableDiffusionModelStore.formatBytes(StableDiffusionModelStore.totalBytes))。未下载时用表情代替图片")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            switch modelStore.state {
            case .installed where modelStore.isBundled:
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            case .installed:
                Button("删除") {
                    confirmDeleteModel = true
                }
                .foregroundColor(.red)
            default:
                Button(modelStore.state.isDownloading ? "查看进度" : "下载") {
                    showModelDownload = true
                }
                .foregroundColor(.teal)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showModelDownload) {
            ModelDownloadView(allowSkip: false)
        }
        .alert("删除画画模型？", isPresented: $confirmDeleteModel) {
            Button("删除", role: .destructive) {
                modelStore.deleteModel()
                AnimalImageService.shared.modelAvailabilityChanged()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("已经画好的动物图片会保留，删除后新动物将用表情代替，需要时可重新下载。")
        }
    }

    private func loadConfig() {
        // 加载英语翻译配置
        englishTranslationEnabled = configManager.config.englishTranslation.isEnabled
        englishTranslationQuestionCount = configManager.config.englishTranslation.questionCount
        englishTranslationWeeks = configManager.config.englishTranslation.vocabularyWeeks

        // 加载英语填空配置
        englishFillBlankEnabled = configManager.config.englishFillBlank.isEnabled
        englishFillBlankQuestionCount = configManager.config.englishFillBlank.questionCount
        englishFillBlankWeeks = configManager.config.englishFillBlank.vocabularyWeeks

        // 加载加减法配置
        additionSubtractionEnabled = configManager.config.additionSubtraction.isEnabled
        additionSubtractionQuestionCount = configManager.config.additionSubtraction.questionCount
        additionSubtractionMaxNumber = configManager.config.additionSubtraction.maxNumber

        // 加载乘法配置
        multiplicationEnabled = configManager.config.multiplication.isEnabled
        multiplicationQuestionCount = configManager.config.multiplication.questionCount
        multiplicationMaxNumber = configManager.config.multiplication.maxNumber

        // 加载动物大作战配置
        animalBattleEnabled = configManager.config.animalBattle.isEnabled
        animalBattleQuestionCount = configManager.config.animalBattle.questionCount
    }

    private func saveConfig() {
        // 保存英语翻译配置
        configManager.config.englishTranslation.isEnabled = englishTranslationEnabled
        configManager.config.englishTranslation.questionCount = englishTranslationQuestionCount
        configManager.config.englishTranslation.vocabularyWeeks = englishTranslationWeeks

        // 保存英语填空配置
        configManager.config.englishFillBlank.isEnabled = englishFillBlankEnabled
        configManager.config.englishFillBlank.questionCount = englishFillBlankQuestionCount
        configManager.config.englishFillBlank.vocabularyWeeks = englishFillBlankWeeks

        // 保存加减法配置
        configManager.config.additionSubtraction.isEnabled = additionSubtractionEnabled
        configManager.config.additionSubtraction.questionCount = additionSubtractionQuestionCount
        configManager.config.additionSubtraction.maxNumber = additionSubtractionMaxNumber

        // 保存乘法配置
        configManager.config.multiplication.isEnabled = multiplicationEnabled
        configManager.config.multiplication.questionCount = multiplicationQuestionCount
        configManager.config.multiplication.maxNumber = multiplicationMaxNumber

        // 保存动物大作战配置
        configManager.config.animalBattle.isEnabled = animalBattleEnabled
        configManager.config.animalBattle.questionCount = animalBattleQuestionCount
        
        configManager.saveConfig()
        
        // 同时更新乘法配置管理器（保持兼容性）
        let multiplicationManager = MultiplicationQuizManager()
        multiplicationManager.config = configManager.config.multiplication
        multiplicationManager.saveConfig()
    }
}

#Preview {
    MultiplicationConfigView()
}

