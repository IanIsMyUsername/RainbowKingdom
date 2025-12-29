//
//  MultiplicationQuizModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// 乘法题目模型
struct MultiplicationQuestion: Identifiable, Codable {
    let id = UUID()
    let number1: Int
    let number2: Int
    let question: String
    let correctAnswer: Int
    let options: [Int]? // 选择题选项
    
    init(number1: Int, number2: Int) {
        self.number1 = number1
        self.number2 = number2
        self.correctAnswer = number1 * number2
        self.question = "\(number1) × \(number2) = ?"
        
        // 生成选择题选项
        self.options = Self.generateOptions(correctAnswer: self.correctAnswer)
    }
    
    // 生成选择题选项
    static func generateOptions(correctAnswer: Int) -> [Int] {
        var options = [correctAnswer]
        var attempts = 0
        let maxAttempts = 20 // 防止无限循环
        
        // 生成3个错误选项
        while options.count < 4 && attempts < maxAttempts {
            let wrongAnswer = generateWrongAnswer(correctAnswer: correctAnswer)
            if !options.contains(wrongAnswer) && wrongAnswer > 0 {
                options.append(wrongAnswer)
            }
            attempts += 1
        }
        
        // 如果无法生成足够的唯一选项，添加一些默认值
        while options.count < 4 {
            let fallbackAnswer1 = max(1, correctAnswer + options.count)
            let fallbackAnswer2 = max(1, correctAnswer - options.count)
            
            if !options.contains(fallbackAnswer1) && fallbackAnswer1 > 0 {
                options.append(fallbackAnswer1)
            } else if !options.contains(fallbackAnswer2) && fallbackAnswer2 > 0 {
                options.append(fallbackAnswer2)
            } else {
                // 如果都重复，尝试其他值
                let alternative = max(1, correctAnswer + options.count * 2)
                if !options.contains(alternative) {
                    options.append(alternative)
                } else {
                    options.append(max(1, correctAnswer - options.count * 2))
                }
            }
        }
        
        return options.shuffled()
    }
    
    // 生成错误答案
    static private func generateWrongAnswer(correctAnswer: Int) -> Int {
        // 生成一个与正确答案相近但不相同的错误答案
        let rangeSize = max(6, correctAnswer / 2)
        let lowerBound = max(1, correctAnswer - rangeSize)
        let upperBound = correctAnswer + rangeSize
        
        let range = lowerBound...upperBound
        var wrongAnswer = Int.random(in: range)
        
        // 确保生成的错误答案不等于正确答案
        while wrongAnswer == correctAnswer {
            wrongAnswer = Int.random(in: range)
        }
        
        return wrongAnswer
    }
}

// 乘法练习结果模型
struct MultiplicationQuizResult: Identifiable, Codable {
    let id = UUID()
    let maxNumber: Int // 数字范围上限
    let totalQuestions: Int
    let correctAnswers: Int
    let score: Int
    let timeSpent: TimeInterval
    let completedDate: Date
    let questions: [MultiplicationQuestion]
    let userAnswers: [String]
    
    var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    var performance: String {
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
}

// 乘法练习配置
struct MultiplicationQuizConfig: Codable {
    var maxNumber: Int = 3 // 默认数字范围上限（小于3，即1-2）
    var questionCount: Int = 10 // 默认题目数量
    
    init(maxNumber: Int = 3, questionCount: Int = 10) {
        self.maxNumber = maxNumber
        self.questionCount = questionCount
    }
}

// 乘法练习管理器
class MultiplicationQuizManager: ObservableObject {
    @Published var currentQuiz: [MultiplicationQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var userAnswers: [String] = []
    @Published var quizResults: [MultiplicationQuizResult] = []
    @Published var isQuizActive = false
    @Published var quizStartTime: Date?
    @Published var config: MultiplicationQuizConfig = MultiplicationQuizConfig()
    
    private let userDefaults = UserDefaults.standard
    private let multiplicationQuizResultsKey = "SavedMultiplicationQuizResults"
    private let multiplicationQuizConfigKey = "MultiplicationQuizConfig"
    
    init() {
        loadQuizResults()
        loadConfig()
    }
    
    // 开始新的乘法练习
    func startQuiz(config: MultiplicationQuizConfig? = nil) {
        if let config = config {
            self.config = config
            saveConfig()
        }
        
        currentQuiz = generateMultiplicationQuestions(
            maxNumber: self.config.maxNumber,
            count: self.config.questionCount
        )
        currentQuestionIndex = 0
        userAnswers = Array(repeating: "", count: currentQuiz.count)
        isQuizActive = true
        quizStartTime = Date()
    }
    
    // 结束练习
    func endQuiz() {
        guard let startTime = quizStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        let correctAnswers = calculateCorrectAnswers()
        let score = correctAnswers
        
        let result = MultiplicationQuizResult(
            maxNumber: config.maxNumber,
            totalQuestions: currentQuiz.count,
            correctAnswers: correctAnswers,
            score: score,
            timeSpent: timeSpent,
            completedDate: Date(),
            questions: currentQuiz,
            userAnswers: userAnswers
        )
        
        quizResults.append(result)
        saveQuizResults()
        
        isQuizActive = false
        quizStartTime = nil
    }
    
    // 获取当前题目
    var currentQuestion: MultiplicationQuestion? {
        guard currentQuestionIndex < currentQuiz.count else { return nil }
        return currentQuiz[currentQuestionIndex]
    }
    
    // 提交答案
    func submitAnswer(_ answer: String) {
        if currentQuestionIndex < userAnswers.count {
            userAnswers[currentQuestionIndex] = answer
        }
    }
    
    // 下一题
    func nextQuestion() {
        if currentQuestionIndex < currentQuiz.count - 1 {
            currentQuestionIndex += 1
        } else {
            endQuiz()
        }
    }
    
    // 上一题
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    // 生成乘法题目
    private func generateMultiplicationQuestions(maxNumber: Int, count: Int) -> [MultiplicationQuestion] {
        var questions: [MultiplicationQuestion] = []
        var usedQuestions: Set<String> = [] // 用于检查重复题目
        var attempts = 0
        let maxAttempts = count * 10 // 防止无限循环
        
        while questions.count < count && attempts < maxAttempts {
            // 生成两个数字，范围是1到maxNumber（不包括maxNumber，即1到maxNumber-1）
            let number1 = Int.random(in: 1..<maxNumber)
            let number2 = Int.random(in: 1..<maxNumber)
            
            let questionKey = "\(number1)×\(number2)"
            
            // 检查是否重复
            if !usedQuestions.contains(questionKey) {
                let question = MultiplicationQuestion(number1: number1, number2: number2)
                questions.append(question)
                usedQuestions.insert(questionKey)
            }
            attempts += 1
        }
        
        return questions
    }
    
    // 计算正确答案数量
    private func calculateCorrectAnswers() -> Int {
        var correctCount = 0
        for (index, question) in currentQuiz.enumerated() {
            if index < userAnswers.count {
                let userAnswer = userAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines)
                if let userAnswerInt = Int(userAnswer), userAnswerInt == question.correctAnswer {
                    correctCount += 1
                }
            }
        }
        return correctCount
    }
    
    // 保存练习结果
    private func saveQuizResults() {
        if let encoded = try? JSONEncoder().encode(quizResults) {
            userDefaults.set(encoded, forKey: multiplicationQuizResultsKey)
        }
    }
    
    // 加载练习结果
    private func loadQuizResults() {
        if let data = userDefaults.data(forKey: multiplicationQuizResultsKey),
           let decoded = try? JSONDecoder().decode([MultiplicationQuizResult].self, from: data) {
            quizResults = decoded
        }
    }
    
    // 保存配置
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            userDefaults.set(encoded, forKey: multiplicationQuizConfigKey)
        }
    }
    
    // 加载配置
    private func loadConfig() {
        if let data = userDefaults.data(forKey: multiplicationQuizConfigKey),
           let decoded = try? JSONDecoder().decode(MultiplicationQuizConfig.self, from: data) {
            config = decoded
        }
    }
    
    // 重置练习
    func resetQuiz() {
        currentQuiz = []
        currentQuestionIndex = 0
        userAnswers = []
        isQuizActive = false
        quizStartTime = nil
    }
    
    // 获取最近的练习结果
    func getRecentResults(limit: Int = 10) -> [MultiplicationQuizResult] {
        return Array(quizResults.sorted { $0.completedDate > $1.completedDate }.prefix(limit))
    }
}

