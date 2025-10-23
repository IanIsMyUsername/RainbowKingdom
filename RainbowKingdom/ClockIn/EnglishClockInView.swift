//
//  EnglishClockInView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct EnglishClockInView: View {
    @EnvironmentObject var clockInManager: ClockInManager
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [String] = []
    @State private var selectedAnswer: String = ""
    @State private var showingResult = false
    @State private var quizStartTime: Date?
    @State private var questions: [QuizQuestion] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAnswerFeedback = false
    @State private var isAnswerCorrect = false
    @State private var correctAnswer = ""
    @State private var showSummary = false
    @State private var submittedQuestions: Set<Int> = [] // 跟踪已提交的题目
    
    private let questionCount = 30
    
    var body: some View {
        NavigationView {
            VStack {
                if showSummary {
                    summaryView
                } else {
                    quizContent
                }
            }
            .navigationTitle("英语打卡练习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            startQuiz()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("错误"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // 测验内容
    private var quizContent: some View {
        VStack(spacing: 20) {
            // 进度条
            progressBar
            
            // 题目内容
            if let question = getCurrentQuestion() {
                questionCard(question: question)
            }
            
            // 选项按钮
            if let question = getCurrentQuestion(), let options = question.options {
                optionsView(question: question, options: options)
            }
            
            // 导航按钮
            navigationButtons
        }
        .padding()
    }
    
    // 进度条
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("题目 \(currentQuestionIndex + 1) / \(questions.count)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(questions.count > 0 ? Int(Double(currentQuestionIndex) / Double(questions.count) * 100) : 0)%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: questions.count > 0 ? Double(currentQuestionIndex) : 0, total: max(Double(questions.count), 1))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
    
    // 题目卡片
    private func questionCard(question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(question.question)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            if let hint = question.hint {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 选项视图
    private func optionsView(question: QuizQuestion, options: [String]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    if !showAnswerFeedback && !submittedQuestions.contains(currentQuestionIndex) {
                        selectedAnswer = option
                    }
                }) {
                    HStack {
                        Text(option)
                            .font(.body)
                            .foregroundColor(getOptionTextColor(option: option, correctAnswer: question.correctAnswer))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if selectedAnswer == option {
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
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // 导航按钮
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            if currentQuestionIndex > 0 {
                Button("上一题") {
                    previousQuestion()
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Spacer()
            
            if !showAnswerFeedback && !submittedQuestions.contains(currentQuestionIndex) {
                // 提交答案按钮
                Button("提交答案") {
                    submitAnswer()
                }
                .foregroundColor(.white)
                .padding()
                .background(selectedAnswer.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
                .disabled(selectedAnswer.isEmpty)
            } else {
                // 下一题/完成练习按钮
                Button(currentQuestionIndex == questions.count - 1 ? "完成练习" : "下一题") {
                    if currentQuestionIndex == questions.count - 1 {
                        completeQuiz()
                    } else {
                        nextQuestion()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            }
        }
    }
    
    
    // 总结界面
    private var summaryView: some View {
        VStack(spacing: 0) {
            // 顶部标题和成绩
            VStack(spacing: 20) {
                // 标题
                Text("练习总结")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                
                // 成绩概览
                let score = calculateScore()
                let percentage = questions.count > 0 ? Double(score) / Double(questions.count) * 100 : 0
                
                VStack(spacing: 15) {
                    Text("总成绩")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("\(score) / \(questions.count)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(getPerformanceText(percentage: percentage))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(getPerformanceColor(percentage: percentage))
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
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        QuestionSummaryRow(
                            questionNumber: index + 1,
                            question: question,
                            userAnswer: index < userAnswers.count ? userAnswers[index] : "",
                            isCorrect: isAnswerCorrect(for: index)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
                    restartQuiz()
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
    
    // 开始测验
    private func startQuiz() {
        // 强制重新加载CSV文件以确保获取最新数据
        print("开始重新加载CSV文件...")
        vocabularyManager.reloadFromCSV()
        print("CSV文件重新加载完成，当前词汇总数: \(vocabularyManager.vocabularies.count)")
        
        // 获取最近两周的词汇
        let recentVocabularies = getRecentVocabularies()
        print("筛选出的近两周词汇数: \(recentVocabularies.count)")
        
        // 生成15个选择题
        questions = generateQuestions(from: recentVocabularies)
        
        // 如果没有足够的词汇，显示错误
        if questions.isEmpty {
            errorMessage = "没有足够的词汇来生成练习题目，请先添加一些词汇。"
            showError = true
            return
        }
        
        // 初始化状态
        currentQuestionIndex = 0
        userAnswers = Array(repeating: "", count: min(questionCount, questions.count))
        selectedAnswer = ""
        quizStartTime = Date()
    }
    
    // 获取最近两周的词汇，如果不够则从全部词汇补全
    private func getRecentVocabularies() -> [Vocabulary] {
        let calendar = Calendar.current
        let today = Date()
        
        // 获取两周前的开始日期（00:00:00）
        let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: today) ?? today
        let twoWeeksAgoStart = calendar.startOfDay(for: twoWeeksAgo)
        
        // 获取今天的结束日期（23:59:59）
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        
        // 筛选最近两周的词汇（包括今天）
        let recentVocabularies = vocabularyManager.vocabularies.filter { vocab in
            let vocabDate = calendar.startOfDay(for: vocab.createdDate)
            let isInRange = vocabDate >= twoWeeksAgoStart && vocabDate < todayEnd
            if isInRange {
                print("选中词汇: \(vocab.english), 日期: \(vocab.createdDate)")
            }
            return isInRange
        }
        
        
        // 如果近两周的词汇不够15个，从全部词汇中补全
        if recentVocabularies.count < questionCount {
            let allVocabularies = vocabularyManager.vocabularies
            let remainingCount = questionCount - recentVocabularies.count
            let additionalVocabularies = allVocabularies
                .filter { calendar.startOfDay(for: $0.createdDate) < twoWeeksAgoStart }
                .shuffled()
                .prefix(remainingCount)
            
            
            return recentVocabularies + Array(additionalVocabularies)
        }
        
        return recentVocabularies
    }
    
    // 生成题目
    private func generateQuestions(from vocabularies: [Vocabulary]) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        // 如果词汇列表为空，返回空数组
        guard !vocabularies.isEmpty else { return questions }
        
        let shuffledVocabularies = vocabularies.shuffled()
        
        for i in 0..<min(questionCount, shuffledVocabularies.count) {
            let vocabulary = shuffledVocabularies[i]
            let isEnglishToChinese = Bool.random()
            
            let question: String
            let correctAnswer: String
            let options: [String]
            
            if isEnglishToChinese {
                question = "请选择以下英文的中文意思：\n\(vocabulary.english)"
                correctAnswer = vocabulary.chinese
                
                // 生成错误选项
                let wrongOptions = generateWrongOptions(for: vocabulary.chinese, isChinese: true, allVocabularies: vocabularies)
                options = ([correctAnswer] + wrongOptions).shuffled()
            } else {
                question = "请选择以下中文的英文翻译：\n\(vocabulary.chinese)"
                correctAnswer = vocabulary.english
                
                // 生成错误选项
                let wrongOptions = generateWrongOptions(for: vocabulary.english, isChinese: false, allVocabularies: vocabularies)
                options = ([correctAnswer] + wrongOptions).shuffled()
            }
            
            let quizQuestion = QuizQuestion(
                vocabulary: vocabulary,
                questionType: .multipleChoice,
                question: question,
                correctAnswer: correctAnswer,
                options: options,
                hint: "类型：\(vocabulary.type.rawValue)"
            )
            
            questions.append(quizQuestion)
        }
        
        return questions
    }
    
    // 生成错误选项
    private func generateWrongOptions(for correctAnswer: String, isChinese: Bool, allVocabularies: [Vocabulary]) -> [String] {
        var wrongOptions: [String] = []
        
        // 从所有词汇中随机选择3个不同的错误选项
        let otherVocabularies = allVocabularies.filter { vocab in
            if isChinese {
                vocab.chinese != correctAnswer
            } else {
                vocab.english != correctAnswer
            }
        }.shuffled()
        
        for vocab in otherVocabularies.prefix(3) {
            let wrongAnswer = isChinese ? vocab.chinese : vocab.english
            if !wrongOptions.contains(wrongAnswer) {
                wrongOptions.append(wrongAnswer)
            }
        }
        
        // 如果词汇不够，添加一些通用错误选项
        if wrongOptions.count < 3 {
            let genericWrongOptions = isChinese ? [
                "不知道", "忘记了", "不确定", "可能是", "大概"
            ] : [
                "unknown", "forgot", "maybe", "probably", "not sure"
            ]
            
            for option in genericWrongOptions {
                if !wrongOptions.contains(option) && wrongOptions.count < 3 {
                    wrongOptions.append(option)
                }
            }
        }
        
        return Array(wrongOptions.prefix(3))
    }
    
    // 获取当前题目
    private func getCurrentQuestion() -> QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    // 下一题
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            // 保存当前答案
            if currentQuestionIndex < userAnswers.count {
                userAnswers[currentQuestionIndex] = selectedAnswer
            }
            
            // 重置反馈状态
            showAnswerFeedback = false
            isAnswerCorrect = false
            correctAnswer = ""
            
            // 移动到下一题
            currentQuestionIndex += 1
            selectedAnswer = currentQuestionIndex < userAnswers.count ? userAnswers[currentQuestionIndex] : ""
        }
    }
    
    // 上一题
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            // 保存当前答案
            if currentQuestionIndex < userAnswers.count {
                userAnswers[currentQuestionIndex] = selectedAnswer
            }
            
            // 移动到上一题
            currentQuestionIndex -= 1
            selectedAnswer = currentQuestionIndex < userAnswers.count ? userAnswers[currentQuestionIndex] : ""
            
            // 如果上一题已经提交过，显示反馈状态
            if submittedQuestions.contains(currentQuestionIndex) {
                showAnswerFeedback = true
                if let question = getCurrentQuestion() {
                    isAnswerCorrect = selectedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    correctAnswer = question.correctAnswer
                }
            } else {
                // 重置反馈状态
                showAnswerFeedback = false
                isAnswerCorrect = false
                correctAnswer = ""
            }
        }
    }
    
    // 完成测验
    private func completeQuiz() {
        // 保存最后一题的答案
        if currentQuestionIndex < userAnswers.count {
            userAnswers[currentQuestionIndex] = selectedAnswer
        }
        
        // 计算成绩
        let score = calculateScore()
        let timeSpent = quizStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // 创建打卡记录
        let record = ClockInRecord(
            date: Date(),
            subject: "英语",
            score: score,
            totalQuestions: questions.count,
            timeSpent: timeSpent,
            completedDate: Date(),
            questions: questions,
            userAnswers: userAnswers
        )
        
        // 添加到打卡管理器
        clockInManager.addClockInRecord(record)
        
        // 显示总结界面
        showSummary = true
    }
    
    // 计算得分
    private func calculateScore() -> Int {
        var correctCount = 0
        for (index, question) in questions.enumerated() {
            if index < userAnswers.count {
                let userAnswer = userAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let correctAnswer = question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if userAnswer == correctAnswer {
                    correctCount += 1
                }
            }
        }
        return correctCount
    }
    
    // 获取表现文本
    private func getPerformanceText(percentage: Double) -> String {
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
    
    // 获取表现颜色
    private func getPerformanceColor(percentage: Double) -> Color {
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
    
    // 重新开始测验
    private func restartQuiz() {
        currentQuestionIndex = 0
        userAnswers = []
        selectedAnswer = ""
        showingResult = false
        questions = []
        showError = false
        errorMessage = ""
        showAnswerFeedback = false
        isAnswerCorrect = false
        correctAnswer = ""
        showSummary = false
        submittedQuestions = []
        quizStartTime = nil
        startQuiz()
    }
    
    // 提交答案
    private func submitAnswer() {
        guard !selectedAnswer.isEmpty else { return }
        
        // 保存当前答案
        if currentQuestionIndex < userAnswers.count {
            userAnswers[currentQuestionIndex] = selectedAnswer
        }
        
        // 标记当前题目为已提交
        submittedQuestions.insert(currentQuestionIndex)
        
        // 检查答案
        if let currentQuestion = getCurrentQuestion() {
            checkAnswer(selectedOption: selectedAnswer, correctAnswer: currentQuestion.correctAnswer)
        }
    }
    
    // 检查答案
    private func checkAnswer(selectedOption: String, correctAnswer: String) {
        self.correctAnswer = correctAnswer
        isAnswerCorrect = selectedOption.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        showAnswerFeedback = true
    }
    
    // 获取选项文字颜色
    private func getOptionTextColor(option: String, correctAnswer: String) -> Color {
        if !showAnswerFeedback {
            return selectedAnswer == option ? .white : .primary
        }
        
        if option == correctAnswer {
            return .white
        } else if selectedAnswer == option && !isAnswerCorrect {
            return .white
        } else {
            return .primary
        }
    }
    
    // 获取选项背景颜色
    private func getOptionBackgroundColor(option: String, correctAnswer: String) -> Color {
        if !showAnswerFeedback {
            return selectedAnswer == option ? Color.blue : Color(.systemGray6)
        }
        
        if option == correctAnswer {
            return .green
        } else if selectedAnswer == option && !isAnswerCorrect {
            return .red
        } else {
            return Color(.systemGray6)
        }
    }
    
    // 检查答案是否正确
    private func isAnswerCorrect(for index: Int) -> Bool {
        guard index < questions.count && index < userAnswers.count else { return false }
        let question = questions[index]
        let userAnswer = userAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return userAnswer == correctAnswer
    }
}

// 题目总结行组件
struct QuestionSummaryRow: View {
    let questionNumber: Int
    let question: QuizQuestion
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
                        Text(question.correctAnswer)
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
    EnglishClockInView()
        .environmentObject(ClockInManager())
        .environmentObject(VocabularyManager())
}
