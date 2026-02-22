//
//  EnglishFillBlankView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/11/15.
//

import SwiftUI

struct EnglishFillBlankView: View {
    let targetDate: Date? // 补打卡的目标日期，nil表示正常打卡（使用今天）
    @EnvironmentObject var clockInManager: ClockInManager
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var configManager = PracticeConfigManager()
    
    @State private var currentQuestionIndex = 0
    @State private var userInputs: [[String]] = [] // 每题的用户输入字符数组
    @State private var quizStartTime: Date?
    @State private var questions: [FillBlankQuestion] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAnswerFeedback = false
    @State private var isAnswerCorrect = false
    @State private var showSummary = false
    @State private var submittedQuestions: Set<Int> = []
    @State private var focusedIndex: Int? = nil
    @State private var showKeyboard = false
    @State private var needsCorrection = false
    @State private var answeredCorrectly: Set<Int> = [] // 首次答对的题目
    @State private var initiallyWrong: Set<Int> = [] // 首次答错的题目
    
    init(targetDate: Date? = nil) {
        self.targetDate = targetDate
    }
    
    private var questionCount: Int {
        max(1, configManager.config.englishFillBlank.questionCount)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showSummary {
                    summaryView
                } else {
                    quizContent
                }
            }
            .navigationTitle("英语填空练习")
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
    
    private var quizContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressBar
                
                if let question = getCurrentQuestion() {
                    questionCard(question: question)
                }
                
                navigationButtons
            }
            .padding()
        }
    }
    
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
            
            // 统计信息
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("已做:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(submittedQuestions.count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack(spacing: 4) {
                    Text("正确:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(answeredCorrectly.count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 4) {
                    Text("错误:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(submittedQuestions.count - answeredCorrectly.count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
    }
    
    private func questionCard(question: FillBlankQuestion) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // 第一行：带提示的英文
            Text(question.partialWord)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // 第二行：中文翻译
            Text(question.chineseTranslation)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // 第三行：输入区域
            HStack {
                Spacer()
                inputAreaView(word: question.correctAnswer)
                Spacer()
            }
            .padding(.horizontal)
            
            // 反馈信息
            if showAnswerFeedback {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isAnswerCorrect ? .green : .red)
                            .font(.title2)
                        
                        Text(isAnswerCorrect ? "正确！" : "错误")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isAnswerCorrect ? .green : .red)
                        
                        if !isAnswerCorrect {
                            Text("正确答案: \(question.correctAnswer)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isAnswerCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    private func inputAreaView(word: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                    if char.isLetter {
                        let letterIndex = getLetterIndex(upTo: index, in: word)
                        Button(action: {
                            if !showAnswerFeedback || needsCorrection {
                                // 如果需要订正，清除之前填写的单词
                                if needsCorrection {
                                    // 确保数组足够大
                                    while userInputs.count <= currentQuestionIndex {
                                        userInputs.append([])
                                    }
                                    // 清空当前题目的所有输入
                                    userInputs[currentQuestionIndex] = []
                                    // 重置反馈状态，允许重新输入
                                    showAnswerFeedback = false
                                }
                                
                                // 如果键盘未展开，自动定位到第一个空白位置
                                if !showKeyboard {
                                    focusedIndex = findFirstEmptyPosition(in: word)
                                } else {
                                    focusedIndex = letterIndex
                                }
                                showKeyboard = true
                            }
                        }) {
                            Text(getCurrentInput(at: letterIndex))
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(letterIndex == focusedIndex ? .blue : .primary)
                                .frame(width: 32, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(letterIndex == focusedIndex ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .disabled(showAnswerFeedback && !needsCorrection)
                    } else if char == " " {
                        Spacer()
                            .frame(width: 16, height: 40)
                    } else {
                        Text(String(char))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 40)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            if showKeyboard, let index = focusedIndex {
                KeyboardView(
                    onInput: { char in
                        handleInput(char, at: index)
                    },
                    onDelete: {
                        handleDelete(at: index)
                    },
                    onDone: {
                        showKeyboard = false
                        focusedIndex = nil
                    }
                )
            }
        }
    }
    
    private func getCurrentInput(at index: Int) -> String {
        let currentInputs = getCurrentQuestionInputs()
        if index < currentInputs.count && !currentInputs[index].isEmpty {
            return currentInputs[index]
        }
        return "_"
    }
    
    private func getCurrentQuestionInputs() -> [String] {
        if currentQuestionIndex < userInputs.count {
            return userInputs[currentQuestionIndex]
        }
        return []
    }
    
    private func getLetterIndex(upTo position: Int, in word: String) -> Int {
        var count = 0
        for (index, char) in word.enumerated() {
            if index >= position { break }
            if char.isLetter {
                count += 1
            }
        }
        return count
    }
    
    private func findFirstEmptyPosition(in word: String) -> Int {
        let currentInputs = getCurrentQuestionInputs()
        let letterCount = word.filter { $0.isLetter }.count
        
        for i in 0..<letterCount {
            if i >= currentInputs.count || currentInputs[i].isEmpty {
                return i
            }
        }
        
        return 0
    }
    
    private func handleInput(_ char: String, at index: Int) {
        guard char.count == 1 else { return }
        
        // 确保数组足够大
        while userInputs.count <= currentQuestionIndex {
            userInputs.append([])
        }
        
        while userInputs[currentQuestionIndex].count <= index {
            userInputs[currentQuestionIndex].append("")
        }
        
        userInputs[currentQuestionIndex][index] = char.lowercased()
        
        // 自动移动到下一个空白位置
        if let question = getCurrentQuestion() {
            let letterCount = question.correctAnswer.filter { $0.isLetter }.count
            for i in (index + 1)..<letterCount {
                let currentInputs = getCurrentQuestionInputs()
                if i >= currentInputs.count || currentInputs[i].isEmpty {
                    focusedIndex = i
                    return
                }
            }
        }
        
        focusedIndex = nil
    }
    
    private func handleDelete(at index: Int) {
        guard currentQuestionIndex < userInputs.count else { return }
        
        // 确保数组足够大
        while userInputs[currentQuestionIndex].count <= index {
            userInputs[currentQuestionIndex].append("")
        }
        
        // 清空当前位置的内容
        userInputs[currentQuestionIndex][index] = ""
        
        // 如果当前位置已经是空的，删除前一个位置的内容并移动光标
        let currentInputs = getCurrentQuestionInputs()
        if index < currentInputs.count && currentInputs[index].isEmpty && index > 0 {
            // 移动到前一个位置
            focusedIndex = index - 1
            // 清空前一个位置
            if index - 1 < userInputs[currentQuestionIndex].count {
                userInputs[currentQuestionIndex][index - 1] = ""
            }
        }
    }
    
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
            
            if showKeyboard {
                Button("确认") {
                    showKeyboard = false
                    focusedIndex = nil
                    // 直接提交答案
                    submitAnswer()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            } else if !showAnswerFeedback {
                Button("提交答案") {
                    submitAnswer()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            } else if needsCorrection {
                Button("订正") {
                    showAnswerFeedback = false
                    needsCorrection = false
                    // 清空当前题目的所有输入
                    if currentQuestionIndex < userInputs.count {
                        userInputs[currentQuestionIndex] = []
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(10)
            } else {
                Button(currentQuestionIndex == questions.count - 1 ? "完成练习" : "下一题") {
                    if currentQuestionIndex == questions.count - 1 {
                        completeQuiz()
                    } else {
                        nextQuestion()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
    }
    
    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    Text("练习总结")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                    let score = answeredCorrectly.count
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
                
                // 所有题目展示
                VStack(spacing: 15) {
                    Text("题目详情")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        questionSummaryCard(
                            question: question,
                            index: index,
                            userAnswer: getQuestionUserAnswer(index: index),
                            isCorrect: answeredCorrectly.contains(index)
                        )
                    }
                }
                .padding(.bottom, 20)
                
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
    }
    
    private func questionSummaryCard(question: FillBlankQuestion, index: Int, userAnswer: String, isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("题目 \(index + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.title3)
                    
                    Text(isCorrect ? "正确" : "错误")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCorrect ? .green : .red)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("中文翻译")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(question.chineseTranslation)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("提示")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(question.partialWord)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("你的答案")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(userAnswer.isEmpty ? "未作答" : userAnswer)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(userAnswer.isEmpty ? .gray : .primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("正确答案")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(question.correctAnswer)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private func getQuestionUserAnswer(index: Int) -> String {
        if index < userInputs.count {
            return userInputs[index].joined()
        }
        return ""
    }
    
    private func startQuiz() {
        let months = max(1, configManager.config.englishFillBlank.vocabularyWeeks)
        let recentVocabularies = getRecentVocabularies(recentMonths: months, questionCount: questionCount)
        
        questions = generateQuestions(from: recentVocabularies)
        
        if questions.isEmpty {
            errorMessage = "没有足够的词汇来生成练习题目，请先添加一些词汇。"
            showError = true
            return
        }
        
        currentQuestionIndex = 0
        userInputs = Array(repeating: [], count: questions.count)
        quizStartTime = Date()
    }
    
    private func getRecentVocabularies(recentMonths: Int, questionCount: Int) -> [Vocabulary] {
        let calendar = Calendar.current
        let today = Date()
        
        let monthsAgo = calendar.date(byAdding: .month, value: -recentMonths, to: today) ?? today
        let monthsAgoStart = calendar.startOfDay(for: monthsAgo)
        
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        
        let recentVocabularies = vocabularyManager.vocabularies.filter { vocab in
            let vocabDate = calendar.startOfDay(for: vocab.createdDate)
            return vocabDate >= monthsAgoStart && vocabDate < todayEnd
        }
        
        if recentVocabularies.count >= questionCount {
            return recentVocabularies
        }
        
        let recentIds = Set(recentVocabularies.map { $0.id })
        let remainingCount = questionCount - recentVocabularies.count
        let additionalVocabularies = vocabularyManager.vocabularies
            .filter { !recentIds.contains($0.id) }
            .shuffled()
            .prefix(remainingCount)
        
        return recentVocabularies + Array(additionalVocabularies)
    }
    
    private func generateQuestions(from vocabularies: [Vocabulary]) -> [FillBlankQuestion] {
        var questions: [FillBlankQuestion] = []
        
        guard !vocabularies.isEmpty else { return questions }
        
        let shuffledVocabularies = vocabularies.shuffled()
        
        for i in 0..<min(questionCount, shuffledVocabularies.count) {
            let vocabulary = shuffledVocabularies[i]
            
            let english = vocabulary.english
            let displayedWord = createPartialWord(from: english)
            
            let question = FillBlankQuestion(
                vocabulary: vocabulary,
                chineseTranslation: vocabulary.chinese,
                partialWord: displayedWord,
                correctAnswer: english
            )
            
            questions.append(question)
        }
        
        return questions
    }
    
    private func createPartialWord(from word: String) -> String {
        let words = word.components(separatedBy: " ")
        if words.count > 1 {
            return maskSentenceWords(words)
        }
        return createPartialSingleWord(from: word)
    }
    
    private func createPartialSingleWord(from word: String) -> String {
        let letters = word.filter { $0.isLetter }
        let letterCount = letters.count
        
        guard letterCount > 1 else { return word }
        
        let hideCount = max(1, (letterCount + 1) / 2)
        let visibleLetterCount = letterCount - hideCount
        let maskPrefix = Bool.random()
        
        var displayedWord = ""
        var letterIndex = 0
        
        for char in word {
            if char.isLetter {
                let shouldShow: Bool
                if maskPrefix {
                    shouldShow = letterIndex >= hideCount
                } else {
                    shouldShow = letterIndex < visibleLetterCount
                }
                displayedWord.append(shouldShow ? char : "_")
                letterIndex += 1
            } else {
                displayedWord.append(char)
            }
        }
        
        return displayedWord
    }

    private func maskSentenceWords(_ words: [String]) -> String {
        guard !words.isEmpty else { return "" }
        let maskWordCount = max(1, (words.count + 1) / 2)
        let startMaskIndex = max(0, words.count - maskWordCount)
        
        let maskedWords = words.enumerated().map { index, word in
            if index >= startMaskIndex {
                return maskWholeWord(word)
            }
            return word
        }
        
        return maskedWords.joined(separator: " ")
    }

    private func maskWholeWord(_ word: String) -> String {
        var result = ""
        for char in word {
            if char.isLetter {
                result.append("_")
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private func getCurrentQuestion() -> FillBlankQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            showAnswerFeedback = false
            isAnswerCorrect = false
            needsCorrection = false
            
            currentQuestionIndex += 1
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            
            if submittedQuestions.contains(currentQuestionIndex) {
                showAnswerFeedback = true
                if let question = getCurrentQuestion() {
                    isAnswerCorrect = checkCurrentAnswer(question)
                    needsCorrection = !isAnswerCorrect && !answeredCorrectly.contains(currentQuestionIndex)
                }
            } else {
                showAnswerFeedback = false
                isAnswerCorrect = false
                needsCorrection = false
            }
        }
    }
    
    private func completeQuiz() {
        let score = answeredCorrectly.count
        let timeSpent = quizStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        let quizQuestions = questions.map { fillBlankQuestion in
            QuizQuestion(
                vocabulary: fillBlankQuestion.vocabulary,
                questionType: .fillInBlank,
                question: "请根据中文填写英文: \(fillBlankQuestion.chineseTranslation)\n\(fillBlankQuestion.partialWord)",
                correctAnswer: fillBlankQuestion.correctAnswer,
                options: nil,
                hint: nil
            )
        }
        
        let userAnswersStrings = userInputs.map { $0.joined() }
        
        // 确定记录的日期：如果提供了targetDate（补打卡），使用targetDate；否则使用今天
        let recordDate = targetDate ?? Date()
        
        let record = ClockInRecord(
            date: recordDate,
            subject: "英语填空",
            score: score,
            totalQuestions: questions.count,
            timeSpent: timeSpent,
            completedDate: Date(), // completedDate始终使用当前时间
            questions: quizQuestions,
            userAnswers: userAnswersStrings
        )
        
        clockInManager.addClockInRecord(record)
        
        showSummary = true
    }
    
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
    
    private func restartQuiz() {
        currentQuestionIndex = 0
        userInputs = []
        showError = false
        errorMessage = ""
        showAnswerFeedback = false
        isAnswerCorrect = false
        showSummary = false
        submittedQuestions = []
        focusedIndex = nil
        showKeyboard = false
        needsCorrection = false
        answeredCorrectly = []
        initiallyWrong = []
        quizStartTime = nil
        startQuiz()
    }
    
    private func submitAnswer() {
        guard let question = getCurrentQuestion() else { return }
        
        let isFirstSubmission = !submittedQuestions.contains(currentQuestionIndex)
        submittedQuestions.insert(currentQuestionIndex)
        
        isAnswerCorrect = checkCurrentAnswer(question)
        showAnswerFeedback = true
        
        if isAnswerCorrect {
            // 只有首次答对且之前没有答错过才记录
            if isFirstSubmission && !initiallyWrong.contains(currentQuestionIndex) {
                answeredCorrectly.insert(currentQuestionIndex)
            }
            needsCorrection = false
        } else {
            // 如果首次提交就错了，标记为初始错误
            if isFirstSubmission {
                initiallyWrong.insert(currentQuestionIndex)
                // 如果之前在answeredCorrectly中（不应该发生，但为了安全），移除它
                answeredCorrectly.remove(currentQuestionIndex)
            }
            needsCorrection = true
        }
    }
    
    private func checkCurrentAnswer(_ question: FillBlankQuestion) -> Bool {
        let correctAnswer = question.correctAnswer.lowercased().filter { $0.isLetter }
        let currentInputs = getCurrentQuestionInputs()
        let userAnswer = currentInputs.joined().lowercased()
        
        return userAnswer == correctAnswer
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct FillBlankQuestion {
    let vocabulary: Vocabulary
    let chineseTranslation: String
    let partialWord: String
    let correctAnswer: String
}

// 简化的键盘视图
struct KeyboardView: View {
    let onInput: (String) -> Void
    let onDelete: () -> Void
    let onDone: () -> Void
    
    let letters = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    var body: some View {
        VStack(spacing: 14) {
            ForEach(letters, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { letter in
                        Button(action: {
                            onInput(letter)
                        }) {
                            Text(letter)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 56)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                        .frame(width: 100, height: 56)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                
                Button(action: onDone) {
                    Text("完成")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 56)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
    }
}

#Preview {
    EnglishFillBlankView()
        .environmentObject(ClockInManager())
        .environmentObject(VocabularyManager())
}
