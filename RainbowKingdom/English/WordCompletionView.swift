//
//  WordCompletionView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct WordCompletionView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    @State private var currentVocabularyIndex = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var score = 0
    @State private var completedCount = 0
    @State private var showScore = false
    @State private var shuffledVocabularies: [Vocabulary] = []
    
    private var currentVocabulary: Vocabulary? {
        guard !shuffledVocabularies.isEmpty && currentVocabularyIndex < shuffledVocabularies.count else {
            return nil
        }
        return shuffledVocabularies[currentVocabularyIndex]
    }
    
    private var maskedVocabulary: String {
        guard let vocabulary = currentVocabulary else { return "" }
        let vocabularyLength = vocabulary.english.count
        let maskCount = max(1, vocabularyLength / 3) // 至少显示1个字母
        let visibleCount = vocabularyLength - maskCount
        
        let visiblePart = String(vocabulary.english.prefix(visibleCount))
        let maskedPart = String(repeating: "_", count: maskCount)
        
        return visiblePart + maskedPart
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if showScore {
                // 分数展示页面
                ScoreView(score: score, total: completedCount, vocabularyManager: vocabularyManager)
            } else if let vocabulary = currentVocabulary {
                // 练习页面
                VStack(spacing: 30) {
                    // 筛选器和进度指示器
                    VStack(spacing: 10) {
                        // 组选择器
                        HStack {
                            Text("选择组:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Picker("选择组", selection: $vocabularyManager.selectedGroup) {
                                Text("全部").tag("")
                                ForEach(vocabularyManager.groupNames, id: \.self) { groupName in
                                    Text(groupName).tag(groupName)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        // 日期筛选器
                        HStack {
                            Text("日期筛选:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Picker("日期筛选", selection: $vocabularyManager.dateFilterMode) {
                                ForEach(DateFilterMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .font(.caption)
                            .onChange(of: vocabularyManager.dateFilterMode) { newMode in
                                vocabularyManager.setDateFilterMode(newMode)
                            }
                            
                            if vocabularyManager.dateFilterMode == .custom {
                                DatePicker("", selection: $vocabularyManager.selectedDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .font(.caption)
                                    .onChange(of: vocabularyManager.selectedDate) { newDate in
                                        vocabularyManager.setCustomDate(newDate)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 进度指示器
                        HStack {
                            Text("\(currentVocabularyIndex + 1) / \(shuffledVocabularies.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("得分: \(score)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 类型标签
                    Text(vocabulary.type.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(typeColor)
                        .cornerRadius(12)
                    
                    // 中文提示
                    Text(vocabulary.chinese)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 被遮挡的英文词汇
                    Text(maskedVocabulary)
                        .font(.system(size: vocabulary.type == .phrase ? 28 : 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                        )
                    
                    // 用户输入
                    VStack(spacing: 15) {
                        TextField("请输入完整词汇", text: $userAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if showResult {
                            HStack {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                                    .font(.title2)
                                
                                Text(isCorrect ? "正确！" : "错误")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(isCorrect ? .green : .red)
                                
                                if !isCorrect {
                                    Text("正确答案: \(vocabulary.english)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 按钮组
                    VStack(spacing: 15) {
                        if !showResult {
                            Button(action: checkAnswer) {
                                Text("检查答案")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .disabled(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        } else {
                            Button(action: nextQuestion) {
                                Text(currentVocabularyIndex < shuffledVocabularies.count - 1 ? "下一题" : "查看成绩")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        
                        Button(action: resetGame) {
                            Text("重新开始")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            } else {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("当前组为空")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("请选择其他组或添加词汇")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("词汇补全")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            shuffleVocabularies()
        }
        .onChange(of: vocabularyManager.selectedGroup) { _ in
            shuffleVocabularies()
            currentVocabularyIndex = 0
            resetCurrentQuestion()
        }
        .onChange(of: vocabularyManager.dateFilterMode) { _ in
            shuffleVocabularies()
            currentVocabularyIndex = 0
            resetCurrentQuestion()
        }
    }
    
    private func checkAnswer() {
        guard let vocabulary = currentVocabulary else { return }
        
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = vocabulary.english.lowercased()
        
        isCorrect = trimmedAnswer == correctAnswer
        showResult = true
        
        if isCorrect {
            score += 1
        }
        
        completedCount += 1
    }
    
    private func nextQuestion() {
        if currentVocabularyIndex < shuffledVocabularies.count - 1 {
            currentVocabularyIndex += 1
            resetCurrentQuestion()
        } else {
            showScore = true
        }
    }
    
    private func resetCurrentQuestion() {
        userAnswer = ""
        showResult = false
        isCorrect = false
    }
    
    private func resetGame() {
        shuffleVocabularies()
        currentVocabularyIndex = 0
        score = 0
        completedCount = 0
        showScore = false
        resetCurrentQuestion()
    }
    
    private func shuffleVocabularies() {
        shuffledVocabularies = vocabularyManager.currentGroupVocabularies.shuffled()
    }
    
    private var typeColor: Color {
        guard let vocabulary = currentVocabulary else { return .gray }
        switch vocabulary.type {
        case .word:
            return .blue
        case .phrase:
            return .green
        }
    }
}

struct ScoreView: View {
    let score: Int
    let total: Int
    @ObservedObject var vocabularyManager: VocabularyManager
    @Environment(\.presentationMode) var presentationMode
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(score) / Double(total) * 100
    }
    
    private var performance: String {
        switch percentage {
        case 90...100:
            return "优秀！"
        case 80..<90:
            return "良好！"
        case 70..<80:
            return "及格"
        default:
            return "需要努力"
        }
    }
    
    private var performanceColor: Color {
        switch percentage {
        case 90...100:
            return .green
        case 80..<90:
            return .blue
        case 70..<80:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 成绩图标
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(performanceColor)
            
            // 成绩文字
            VStack(spacing: 10) {
                Text(performance)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(performanceColor)
                
                Text("\(score) / \(total)")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text("正确率: \(Int(percentage))%")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 按钮组
            VStack(spacing: 15) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("返回主菜单")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                Button(action: {
                    // 重新开始游戏
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("再玩一次")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        WordCompletionView(vocabularyManager: VocabularyManager())
    }
}
