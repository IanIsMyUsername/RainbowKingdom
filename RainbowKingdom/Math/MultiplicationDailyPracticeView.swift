//
//  MultiplicationDailyPracticeView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct MultiplicationDailyPracticeView: View {
    @StateObject private var quizManager = MultiplicationQuizManager()
    @EnvironmentObject var clockInManager: ClockInManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedAnswer = ""
    @State private var showingResult = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showSummary = false
    @State private var showAnswerFeedback = false
    @State private var isAnswerCorrect = false
    @State private var correctAnswer = ""
    @State private var submittedQuestions: Set<Int> = [] // 跟踪已提交的题目
    
    var body: some View {
        NavigationView {
            VStack {
                if showSummary {
                    // 总结界面
                    summaryView
                } else {
                    // 练习进行界面
                    quizView
                }
            }
            .navigationTitle("乘法练习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
        }
        .onAppear {
            if !quizManager.isQuizActive {
                startQuiz()
            }
        }
    }
    
    // MARK: - 练习界面
    private var quizView: some View {
        VStack(spacing: 20) {
            // 进度条
            ProgressView(
                value: Double(min(quizManager.currentQuestionIndex + 1, quizManager.currentQuiz.count)),
                total: Double(max(quizManager.currentQuiz.count, 1))
            )
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("第 \(quizManager.currentQuestionIndex + 1) 题")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("共 \(quizManager.currentQuiz.count) 题")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 题目显示
            if let question = quizManager.currentQuestion {
                VStack(spacing: 30) {
                    Text(question.question)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        )
                    
                    // 选择题选项
                    if let options = question.options {
                        optionsView(question: question, options: options)
                    }
                }
            }
            
            Spacer()
            
            // 导航按钮
            HStack(spacing: 20) {
                if quizManager.currentQuestionIndex > 0 {
                    Button("上一题") {
                        previousQuestion()
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 100, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                if !showAnswerFeedback && !submittedQuestions.contains(quizManager.currentQuestionIndex) {
                    // 提交答案按钮
                    Button("提交答案") {
                        submitAnswer()
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 40)
                    .background(selectedAnswer.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(20)
                    .disabled(selectedAnswer.isEmpty)
                } else {
                    // 下一题/完成练习按钮
                    Button(quizManager.currentQuestionIndex == quizManager.currentQuiz.count - 1 ? "完成练习" : "下一题") {
                        if quizManager.currentQuestionIndex == quizManager.currentQuiz.count - 1 {
                            completeQuiz()
                        } else {
                            nextQuestion()
                        }
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 40)
                    .background(Color.green)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
    }
    
    // MARK: - 总结界面
    private var summaryView: some View {
        VStack(spacing: 0) {
            // 顶部标题和成绩
            VStack(spacing: 20) {
                // 标题
                Text("练习总结")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                
                // 成绩概览
                let score = quizManager.quizResults.last?.correctAnswers ?? 0
                let total = quizManager.quizResults.last?.totalQuestions ?? 0
                let percentage = total > 0 ? Double(score) / Double(total) * 100 : 0
                
                VStack(spacing: 15) {
                    Text("总成绩")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("\(score) / \(total)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(quizManager.quizResults.last?.performance ?? "需要努力")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(performanceColor(percentage))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 题目详情列表
            if let lastResult = quizManager.quizResults.last {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(Array(lastResult.questions.enumerated()), id: \.offset) { index, question in
                            MultiplicationQuestionSummaryRow(
                                questionNumber: index + 1,
                                question: question,
                                userAnswer: index < lastResult.userAnswers.count ? lastResult.userAnswers[index] : "",
                                isCorrect: isMultiplicationAnswerCorrect(for: index, result: lastResult)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            // 底部操作按钮
            VStack(spacing: 15) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("返回主界面")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                .contentShape(Rectangle())
                
                Button(action: {
                    resetQuiz()
                }) {
                    Text("重新开始")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 辅助方法
    private func startQuiz() {
        // 使用默认配置：10道题目，数字范围1到2（maxNumber=3）
        let config = MultiplicationQuizConfig(maxNumber: 3, questionCount: 10)
        quizManager.startQuiz(config: config)
        selectedAnswer = ""
        showAnswerFeedback = false
        isAnswerCorrect = false
        correctAnswer = ""
        showSummary = false
        showingResult = false
        submittedQuestions = []
    }
    
    // 检查乘法答案是否正确
    private func isMultiplicationAnswerCorrect(for index: Int, result: MultiplicationQuizResult) -> Bool {
        guard index < result.questions.count && index < result.userAnswers.count else { return false }
        let question = result.questions[index]
        let userAnswer = result.userAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let userAnswerInt = Int(userAnswer) else { return false }
        return userAnswerInt == question.correctAnswer
    }
    
    private func performanceColor(_ percentage: Double) -> Color {
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
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 选项视图
    private func optionsView(question: MultiplicationQuestion, options: [Int]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    if !showAnswerFeedback && !submittedQuestions.contains(quizManager.currentQuestionIndex) {
                        selectedAnswer = "\(option)"
                    }
                }) {
                    HStack {
                        Text("\(option)")
                            .font(.body)
                            .foregroundColor(getOptionTextColor(option: option, correctAnswer: question.correctAnswer))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if selectedAnswer == "\(option)" {
                            if showAnswerFeedback {
                                Image(systemName: isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isAnswerCorrect ? .green : .red)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        } else if option == question.correctAnswer && showAnswerFeedback {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(getOptionBackgroundColor(option: option, correctAnswer: question.correctAnswer))
                    )
                }
                .disabled(showAnswerFeedback || submittedQuestions.contains(quizManager.currentQuestionIndex))
            }
        }
    }
    
    // 提交答案
    private func submitAnswer() {
        guard !selectedAnswer.isEmpty else { return }
        
        // 保存当前答案
        if quizManager.currentQuestionIndex < quizManager.userAnswers.count {
            quizManager.userAnswers[quizManager.currentQuestionIndex] = selectedAnswer
        }
        
        // 标记当前题目为已提交
        submittedQuestions.insert(quizManager.currentQuestionIndex)
        
        // 检查答案
        if let currentQuestion = quizManager.currentQuestion {
            checkAnswer(selectedOption: selectedAnswer, correctAnswer: "\(currentQuestion.correctAnswer)")
        }
    }
    
    // 检查答案
    private func checkAnswer(selectedOption: String, correctAnswer: String) {
        self.correctAnswer = correctAnswer
        isAnswerCorrect = selectedOption == correctAnswer
        showAnswerFeedback = true
    }
    
    // 获取选项文字颜色
    private func getOptionTextColor(option: Int, correctAnswer: Int) -> Color {
        if !showAnswerFeedback {
            return selectedAnswer == "\(option)" ? .white : .primary
        } else {
            if option == correctAnswer {
                return .white
            } else if selectedAnswer == "\(option)" && !isAnswerCorrect {
                return .white
            } else {
                return .primary
            }
        }
    }
    
    // 获取选项背景颜色
    private func getOptionBackgroundColor(option: Int, correctAnswer: Int) -> Color {
        if !showAnswerFeedback {
            return selectedAnswer == "\(option)" ? Color.blue : Color(.systemGray6)
        } else {
            if option == correctAnswer {
                return Color.green
            } else if selectedAnswer == "\(option)" && !isAnswerCorrect {
                return Color.red
            } else {
                return Color(.systemGray6)
            }
        }
    }
    
    // 下一题
    private func nextQuestion() {
        if quizManager.currentQuestionIndex < quizManager.currentQuiz.count - 1 {
            // 保存当前答案
            if quizManager.currentQuestionIndex < quizManager.userAnswers.count {
                quizManager.userAnswers[quizManager.currentQuestionIndex] = selectedAnswer
            }
            
            // 重置反馈状态
            showAnswerFeedback = false
            isAnswerCorrect = false
            correctAnswer = ""
            
            // 移动到下一题
            quizManager.currentQuestionIndex += 1
            selectedAnswer = quizManager.currentQuestionIndex < quizManager.userAnswers.count ? quizManager.userAnswers[quizManager.currentQuestionIndex] : ""
        }
    }
    
    // 上一题
    private func previousQuestion() {
        if quizManager.currentQuestionIndex > 0 {
            // 保存当前答案
            if quizManager.currentQuestionIndex < quizManager.userAnswers.count {
                quizManager.userAnswers[quizManager.currentQuestionIndex] = selectedAnswer
            }
            
            // 移动到上一题
            quizManager.currentQuestionIndex -= 1
            selectedAnswer = quizManager.currentQuestionIndex < quizManager.userAnswers.count ? quizManager.userAnswers[quizManager.currentQuestionIndex] : ""
            
            // 如果上一题已经提交过，显示反馈状态
            if submittedQuestions.contains(quizManager.currentQuestionIndex) {
                showAnswerFeedback = true
                if let currentQuestion = quizManager.currentQuestion {
                    isAnswerCorrect = selectedAnswer == "\(currentQuestion.correctAnswer)"
                    correctAnswer = "\(currentQuestion.correctAnswer)"
                }
            } else {
                // 重置反馈状态
                showAnswerFeedback = false
                isAnswerCorrect = false
                correctAnswer = ""
            }
        }
    }
    
    // 完成练习
    private func completeQuiz() {
        // 保存最后一题的答案
        if quizManager.currentQuestionIndex < quizManager.userAnswers.count {
            quizManager.userAnswers[quizManager.currentQuestionIndex] = selectedAnswer
        }
        
        // 完成练习
        quizManager.endQuiz()
        
        // 创建打卡记录
        if let result = quizManager.quizResults.last {
            // 将乘法题目转换为QuizQuestion格式
            let quizQuestions = convertMultiplicationQuestionsToQuizQuestions(result.questions)
            
            let record = ClockInRecord(
                date: result.completedDate,
                subject: "乘法",
                score: result.score,
                totalQuestions: result.totalQuestions,
                timeSpent: result.timeSpent,
                completedDate: result.completedDate,
                questions: quizQuestions,
                userAnswers: result.userAnswers
            )
            
            // 添加到打卡管理器
            clockInManager.addClockInRecord(record)
        }
        
        showSummary = true
    }
    
    // 重置练习
    private func resetQuiz() {
        showSummary = false
        showAnswerFeedback = false
        isAnswerCorrect = false
        correctAnswer = ""
        selectedAnswer = ""
        submittedQuestions = []
        quizManager.resetQuiz()
    }
    
    // 将乘法题目转换为QuizQuestion格式
    private func convertMultiplicationQuestionsToQuizQuestions(_ multiplicationQuestions: [MultiplicationQuestion]) -> [QuizQuestion] {
        return multiplicationQuestions.map { multiplicationQuestion in
            // 创建一个虚拟的Vocabulary对象
            let vocabulary = Vocabulary(
                english: "Multiplication Question",
                chinese: "乘法题目",
                group: "乘法练习",
                type: .word,
                createdDate: Date()
            )
            
            // 生成选择题选项
            let options = multiplicationQuestion.options?.map { "\($0)" } ?? []
            
            return QuizQuestion(
                vocabulary: vocabulary,
                questionType: .multipleChoice,
                question: multiplicationQuestion.question,
                correctAnswer: "\(multiplicationQuestion.correctAnswer)",
                options: options,
                hint: "类型：乘法（\(multiplicationQuestion.number1) × \(multiplicationQuestion.number2)）"
            )
        }
    }
}

// 乘法题目总结行组件
struct MultiplicationQuestionSummaryRow: View {
    let questionNumber: Int
    let question: MultiplicationQuestion
    let userAnswer: String
    let isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 题目编号和状态
            HStack {
                // 题目编号
                Text("第 \(questionNumber) 题")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 状态标识
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    Text(isCorrect ? "正确" : "错误")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isCorrect ? .green : .red)
                }
            }
            
            // 题目内容
            VStack(alignment: .leading, spacing: 12) {
                Text(question.question)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 答案对比区域
                VStack(spacing: 10) {
                    // 用户答案
                    HStack {
                        Text("你的答案:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(userAnswer.isEmpty ? "未作答" : userAnswer)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(userAnswer.isEmpty ? .gray : (isCorrect ? .green : .red))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCorrect ? Color.green : Color.red, lineWidth: 1)
                            )
                        
                        Spacer()
                    }
                    
                    // 正确答案
                    HStack {
                        Text("正确答案:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(question.correctAnswer)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: isCorrect ? .green.opacity(0.2) : .red.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    MultiplicationDailyPracticeView()
        .environmentObject(ClockInManager())
}

