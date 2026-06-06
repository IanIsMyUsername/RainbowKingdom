//
//  MathDailyPracticeView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct MathDailyPracticeView: View {
    let targetDate: Date? // 补打卡的目标日期，nil表示正常打卡（使用今天）
    @StateObject private var quizManager = MathQuizManager()
    @StateObject private var configManager = PracticeConfigManager()
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

    // 从配置中获取数字范围
    private var maxNumber: Int {
        configManager.config.additionSubtraction.maxNumber
    }

    init(targetDate: Date? = nil) {
        self.targetDate = targetDate
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showSummary {
                    // 总结界面
                    summaryView
                } else if !quizManager.isQuizActive {
                    // 练习开始界面
                    startView
                } else {
                    // 练习进行界面
                    quizView
                }
            }
            .navigationTitle("加减法练习")
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
    
    // MARK: - 开始界面
    private var startView: some View {
        VStack(spacing: 30) {
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("加减法每日一练")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.blue)
            
            Text("\(configManager.config.additionSubtraction.questionCount)道加减法题目，\(maxNumber)以内连续加减2个数")
                .font(.title2)
                .foregroundColor(.gray)

            VStack(spacing: 15) {
                Text("练习规则")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• 共\(configManager.config.additionSubtraction.questionCount)道题目")
                    Text("• 数字范围：\(maxNumber)以内")
                    Text("• 包含加法和减法")
                    Text("• 完成后自动打卡")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Button(action: startQuiz) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始练习")
                }
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
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
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 练习界面
    private var quizView: some View {
        VStack(spacing: 20) {
            // 进度条
            ProgressView(value: Double(quizManager.currentQuestionIndex + 1), total: Double(quizManager.currentQuiz.count))
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
    
    // MARK: - 结果界面
    private var resultView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("练习完成！")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.green)
            
            if let lastResult = quizManager.quizResults.last {
                VStack(spacing: 20) {
                    // 成绩显示
                    VStack(spacing: 10) {
                        Text("正确率")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(lastResult.percentage))%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text(lastResult.performance)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(performanceColor(lastResult.percentage))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // 详细信息
                    VStack(spacing: 15) {
                        HStack {
                            Text("答对题目：")
                            Spacer()
                            Text("\(lastResult.correctAnswers) / \(lastResult.totalQuestions)")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        
                        HStack {
                            Text("用时：")
                            Spacer()
                            Text(formatTime(lastResult.timeSpent))
                                .font(.system(size: 17, weight: .semibold))
                        }
                        
                        HStack {
                            Text("练习类型：")
                            Spacer()
                            Text(lastResult.operationType.displayName)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            VStack(spacing: 15) {
                Button("再来一次") {
                    resetQuiz()
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.blue)
                .cornerRadius(25)
                
                Button("返回首页") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 200, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(25)
            }
            
            Spacer()
        }
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
                            MathQuestionSummaryRow(
                                questionNumber: index + 1,
                                question: question,
                                userAnswer: index < lastResult.userAnswers.count ? lastResult.userAnswers[index] : "",
                                isCorrect: isMathAnswerCorrect(for: index, result: lastResult)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            // 底部操作按钮
            VStack(spacing: 15) {
                Button("返回主界面") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                
                Button("重新开始") {
                    resetQuiz()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 辅助方法
    private func startQuiz() {
        // 从配置读取题目数量和数字范围
        let questionCount = configManager.config.additionSubtraction.questionCount
        let maxNum = configManager.config.additionSubtraction.maxNumber
        quizManager.startQuiz(operationType: .mixed, questionCount: questionCount, maxNumber: maxNum)
        selectedAnswer = ""
        showAnswerFeedback = false
        isAnswerCorrect = false
        correctAnswer = ""
        showSummary = false
        showingResult = false
    }
    
    
    
    
    
    // 检查加减法答案是否正确
    private func isMathAnswerCorrect(for index: Int, result: MathQuizResult) -> Bool {
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
    private func optionsView(question: MathQuestion, options: [Int]) -> some View {
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
            // 将加减法题目转换为QuizQuestion格式
            let quizQuestions = convertMathQuestionsToQuizQuestions(result.questions)
            
            // 确定记录的日期：如果提供了targetDate（补打卡），使用targetDate；否则使用result.completedDate
            let recordDate = targetDate ?? result.completedDate
            
            let record = ClockInRecord(
                date: recordDate,
                subject: "加减法",
                score: result.score,
                totalQuestions: result.totalQuestions,
                timeSpent: result.timeSpent,
                completedDate: result.completedDate, // completedDate始终使用实际完成时间
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
    
    // 将加减法题目转换为QuizQuestion格式
    private func convertMathQuestionsToQuizQuestions(_ mathQuestions: [MathQuestion]) -> [QuizQuestion] {
        return mathQuestions.map { mathQuestion in
            // 创建一个虚拟的Vocabulary对象
            let vocabulary = Vocabulary(
                english: "Math Question",
                chinese: "加减法题目",
                group: "加减法练习",
                type: .word,
                createdDate: Date()
            )
            
            // 生成选择题选项
            let options = mathQuestion.options?.map { "\($0)" } ?? []
            
            let op1Name = mathQuestion.operation.displayName
            let op2Name = mathQuestion.operation2.displayName
            return QuizQuestion(
                vocabulary: vocabulary,
                questionType: .multipleChoice,
                question: mathQuestion.question,
                correctAnswer: "\(mathQuestion.correctAnswer)",
                options: options,
                hint: "类型：连续运算（\(op1Name) 和 \(op2Name)）"
            )
        }
    }
}

// 加减法题目总结行组件
struct MathQuestionSummaryRow: View {
    let questionNumber: Int
    let question: MathQuestion
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
    MathDailyPracticeView()
        .environmentObject(ClockInManager())
}
