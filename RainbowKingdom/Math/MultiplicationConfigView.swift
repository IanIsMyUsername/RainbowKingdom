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
    @State private var englishTranslationQuestionCount: Int = 30
    @State private var englishTranslationWeeks: Int = 2
    
    // 英语填空配置
    @State private var englishFillBlankQuestionCount: Int = 10
    @State private var englishFillBlankWeeks: Int = 1
    
    // 加减法配置
    @State private var additionSubtractionQuestionCount: Int = 10
    @State private var additionSubtractionMaxNumber: Int = 40
    
    // 乘法配置
    @State private var multiplicationQuestionCount: Int = 10
    @State private var multiplicationMaxNumber: Int = 3
    
    var body: some View {
        NavigationView {
            Form {
                // 英语翻译练习配置
                Section(header: Text("英语翻译练习")) {
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
                        ), in: 20...100, step: 10)
                        .accentColor(.red)
                        
                        HStack {
                            Text("20")
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
    
    private func loadConfig() {
        // 加载英语翻译配置
        englishTranslationQuestionCount = configManager.config.englishTranslation.questionCount
        englishTranslationWeeks = configManager.config.englishTranslation.vocabularyWeeks
        
        // 加载英语填空配置
        englishFillBlankQuestionCount = configManager.config.englishFillBlank.questionCount
        englishFillBlankWeeks = configManager.config.englishFillBlank.vocabularyWeeks
        
        // 加载加减法配置
        additionSubtractionQuestionCount = configManager.config.additionSubtraction.questionCount
        additionSubtractionMaxNumber = configManager.config.additionSubtraction.maxNumber
        
        // 加载乘法配置
        multiplicationQuestionCount = configManager.config.multiplication.questionCount
        multiplicationMaxNumber = configManager.config.multiplication.maxNumber
    }
    
    private func saveConfig() {
        // 保存英语翻译配置
        configManager.config.englishTranslation.questionCount = englishTranslationQuestionCount
        configManager.config.englishTranslation.vocabularyWeeks = englishTranslationWeeks
        
        // 保存英语填空配置
        configManager.config.englishFillBlank.questionCount = englishFillBlankQuestionCount
        configManager.config.englishFillBlank.vocabularyWeeks = englishFillBlankWeeks
        
        // 保存加减法配置
        configManager.config.additionSubtraction.questionCount = additionSubtractionQuestionCount
        configManager.config.additionSubtraction.maxNumber = additionSubtractionMaxNumber
        
        // 保存乘法配置
        configManager.config.multiplication.questionCount = multiplicationQuestionCount
        configManager.config.multiplication.maxNumber = multiplicationMaxNumber
        
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

