//
//  QuizView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    @StateObject private var quizManager = QuizManager()
    @State private var selectedQuestionType: QuizQuestionType? = .chineseToEnglish
    @State private var selectedQuizType: QuizType? = .multipleChoice
    @State private var selectedScope: QuizScope = .all
    @State private var questionCount = 10
    @State private var showQuizSettings = true
    @State private var showQuiz = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showQuizSettings {
                // 测验设置页面
                quizSettingsView
            } else if showQuiz {
                // 测验进行页面
                QuizQuestionView(
                    quizManager: quizManager,
                    vocabularyManager: vocabularyManager,
                    onQuizComplete: {
                        showQuiz = false
                        showQuizSettings = true
                    }
                )
            }
        }
        .navigationTitle("英语测验")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var quizSettingsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 30) {
                    // 标题
                    VStack(spacing: 10) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("英语测验")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("选择测验类型和范围开始测试")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                
                    // 测验题型选择
                    VStack(alignment: .leading, spacing: 15) {
                        Text("测验题型")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            ForEach(QuizQuestionType.allCases, id: \.self) { questionType in
                                Button(action: {
                                    selectedQuestionType = questionType
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconForQuestionType(questionType))
                                            .font(.title2)
                                            .foregroundColor(selectedQuestionType == questionType ? .white : .blue)
                                        
                                        Text(questionType.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedQuestionType == questionType ? .white : .primary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(height: 80)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedQuestionType == questionType ? 
                                                  LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                                  LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedQuestionType == questionType ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 测验类型选择
                    VStack(alignment: .leading, spacing: 15) {
                        Text("测验类型")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            ForEach(QuizType.allCases, id: \.self) { quizType in
                                Button(action: {
                                    selectedQuizType = quizType
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconForQuizType(quizType))
                                            .font(.title2)
                                            .foregroundColor(selectedQuizType == quizType ? .white : .blue)
                                        
                                        Text(quizType.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedQuizType == quizType ? .white : .primary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(height: 80)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedQuizType == quizType ? 
                                                  LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                                  LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedQuizType == quizType ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 测验范围选择
                    VStack(alignment: .leading, spacing: 15) {
                        Text("测验范围")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 10) {
                            ForEach(QuizScope.allCases, id: \.self) { scope in
                                Button(action: {
                                    selectedScope = scope
                                }) {
                                    HStack {
                                        Image(systemName: selectedScope == scope ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedScope == scope ? .blue : .gray)
                                        
                                        Text(scope.displayName)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if scope == .selectedGroup && !vocabularyManager.selectedGroup.isEmpty {
                                            Text(vocabularyManager.selectedGroup)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedScope == scope ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 题目数量选择
                    VStack(alignment: .leading, spacing: 15) {
                        Text("题目数量")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("\(questionCount) 题")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Stepper("", value: $questionCount, in: 5...50, step: 5)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // 开始测验按钮 - 固定在底部
            VStack {
                Button(action: startQuiz) {
                    Text("开始测验")
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
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
        }
    }
    
    private func iconForQuestionType(_ questionType: QuizQuestionType) -> String {
        switch questionType {
        case .chineseToEnglish:
            return "arrow.right.circle"
        case .englishToChinese:
            return "arrow.left.circle"
        }
    }
    
    private func iconForQuizType(_ quizType: QuizType) -> String {
        switch quizType {
        case .multipleChoice:
            return "list.bullet.circle"
        case .fillInBlank:
            return "pencil.circle"
        }
    }
    
    private func startQuiz() {
        let vocabularies = getVocabulariesForScope()
        guard !vocabularies.isEmpty else {
            // 显示错误提示
            return
        }
        
        // 检查用户是否选择了至少一个选项
        guard selectedQuestionType != nil || selectedQuizType != nil else {
            // 显示错误提示，要求用户选择至少一个选项
            return
        }
        
        quizManager.startQuiz(
            questionType: selectedQuestionType,
            quizType: selectedQuizType,
            scope: selectedScope,
            vocabularies: vocabularies,
            questionCount: questionCount
        )
        
        showQuizSettings = false
        showQuiz = true
    }
    
    private func getVocabulariesForScope() -> [Vocabulary] {
        switch selectedScope {
        case .all:
            return vocabularyManager.vocabularies
        case .selectedGroup:
            return vocabularyManager.currentGroupVocabularies
        case .today:
            return vocabularyManager.vocabularies.filter { Calendar.current.isDateInToday($0.createdDate) }
        case .thisWeek:
            return vocabularyManager.vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            return vocabularyManager.vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: Date(), toGranularity: .month) }
        }
    }
}

struct QuizQuestionView: View {
    @ObservedObject var quizManager: QuizManager
    @ObservedObject var vocabularyManager: VocabularyManager
    let onQuizComplete: () -> Void
    
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 30) {
                    if let question = quizManager.currentQuestion {
                        // 进度指示器
                        VStack(spacing: 10) {
                            HStack {
                                Text("\(quizManager.currentQuestionIndex + 1) / \(quizManager.currentQuiz.count)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("类型: \(question.questionType.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            ProgressView(value: Double(quizManager.currentQuestionIndex + 1), total: Double(quizManager.currentQuiz.count))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        }
                        .padding(.horizontal)
                        
                        // 题目内容
                        VStack(spacing: 20) {
                            // 类型标签
                            Text(question.vocabulary.type.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(typeColor)
                                .cornerRadius(12)
                            
                            // 题目文本
                            Text(question.question)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                            
                            // 提示信息
                            if let hint = question.hint {
                                Text(hint)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                        
                        // 答案输入区域
                        answerInputView(for: question)
                        
                        // 结果提示区域 - 固定高度避免布局变化
                        Group {
                            if showResult {
                                resultView
                                    .padding(.horizontal)
                            } else {
                                // 占位空间，保持布局稳定
                                Color.clear
                            }
                        }
                        .frame(height: 80) // 固定高度
                        
                        Spacer(minLength: 20)
                    } else {
                        // 测验完成
                        QuizResultView(
                            quizManager: quizManager,
                            onRestart: {
                                onQuizComplete()
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 按钮组 - 固定在底部
            VStack {
                buttonGroup
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("英语测验")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let question = quizManager.currentQuestion {
                userAnswer = quizManager.userAnswers[quizManager.currentQuestionIndex]
            }
        }
    }
    
    @ViewBuilder
    private func answerInputView(for question: QuizQuestion) -> some View {
        VStack(spacing: 15) {
            switch question.questionType {
            case .translation, .fillInBlank:
                TextField("请输入答案", text: $userAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
            case .multipleChoice:
                if let options = question.options {
                    VStack(spacing: 10) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            Button(action: {
                                userAnswer = option
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if userAnswer == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(userAnswer == option ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var resultView: some View {
        HStack {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isCorrect ? .green : .red)
                .font(.title2)
            
            Text(isCorrect ? "正确！" : "错误")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isCorrect ? .green : .red)
            
            if !isCorrect {
                Text("正确答案: \(quizManager.currentQuestion?.correctAnswer ?? "")")
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
    
    private var buttonGroup: some View {
        VStack(spacing: 15) {
            if !showResult {
                Button(action: checkAnswer) {
                    Text("提交答案")
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
                    Text(quizManager.currentQuestionIndex < quizManager.currentQuiz.count - 1 ? "下一题" : "完成测验")
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
            
            if quizManager.currentQuestionIndex > 0 {
                Button(action: previousQuestion) {
                    Text("上一题")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
    }
    
    private var typeColor: Color {
        guard let question = quizManager.currentQuestion else { return .gray }
        switch question.vocabulary.type {
        case .word:
            return .blue
        case .phrase:
            return .green
        }
    }
    
    private func checkAnswer() {
        guard let question = quizManager.currentQuestion else { return }
        
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        isCorrect = trimmedAnswer == correctAnswer
        showResult = true
        SoundEffects.shared.play(isCorrect ? .correct : .wrong)
        
        // 保存答案
        quizManager.submitAnswer(userAnswer)
    }
    
    private func nextQuestion() {
        if quizManager.currentQuestionIndex < quizManager.currentQuiz.count - 1 {
            quizManager.nextQuestion()
            resetCurrentQuestion()
        } else {
            quizManager.endQuiz()
            onQuizComplete()
        }
    }
    
    private func previousQuestion() {
        quizManager.previousQuestion()
        resetCurrentQuestion()
    }
    
    private func resetCurrentQuestion() {
        userAnswer = quizManager.userAnswers[quizManager.currentQuestionIndex]
        showResult = false
        isCorrect = false
    }
}

struct QuizResultView: View {
    @ObservedObject var quizManager: QuizManager
    let onRestart: () -> Void
    
    private var lastResult: QuizResult? {
        quizManager.quizResults.last
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
                
                if let result = lastResult {
                    Text("\(result.correctAnswers) / \(result.totalQuestions)")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text("正确率: \(Int(result.percentage))%")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("用时: \(formatTime(result.timeSpent))")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 按钮组
            VStack(spacing: 15) {
                Button(action: onRestart) {
                    Text("重新开始")
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
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .navigationBarHidden(true)
    }
    
    private var performance: String {
        guard let result = lastResult else { return "未知" }
        return result.performance
    }
    
    private var performanceColor: Color {
        guard let result = lastResult else { return .gray }
        switch result.percentage {
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
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
}

#Preview {
    NavigationView {
        QuizView(vocabularyManager: VocabularyManager())
    }
}
