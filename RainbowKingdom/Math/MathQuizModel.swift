//
//  MathQuizModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// 数学运算类型枚举
enum MathOperationType: String, CaseIterable, Codable {
    case addition = "加法"
    case subtraction = "减法"
    case mixed = "混合运算"
    
    var displayName: String {
        return self.rawValue
    }
}

// 数学题目模型
struct MathQuestion: Identifiable, Codable {
    let id = UUID()
    let number1: Int
    let number2: Int
    let operation: MathOperationType
    let question: String
    let correctAnswer: Int
    let options: [Int]? // 选择题选项
    
    init(number1: Int, number2: Int, operation: MathOperationType) {
        self.number1 = number1
        self.number2 = number2
        self.operation = operation
        
        // 先计算正确答案
        let correctAnswer: Int
        let question: String
        
        switch operation {
        case .addition:
            question = "\(number1) + \(number2) = ?"
            correctAnswer = number1 + number2
        case .subtraction:
            question = "\(number1) - \(number2) = ?"
            correctAnswer = number1 - number2
        case .mixed:
            // 这种情况不应该发生，因为我们在generateSingleQuestion中已经确定了具体运算类型
            question = "\(number1) + \(number2) = ?"
            correctAnswer = number1 + number2
        }
        
        self.question = question
        self.correctAnswer = correctAnswer
        
        // 生成选择题选项
        self.options = Self.generateOptions(correctAnswer: correctAnswer)
    }
    
    // 生成选择题选项
    static func generateOptions(correctAnswer: Int) -> [Int] {
        var options = [correctAnswer]
        var attempts = 0
        let maxAttempts = 20 // 防止无限循环
        
        // 生成3个错误选项
        while options.count < 4 && attempts < maxAttempts {
            let wrongAnswer = generateWrongAnswer(correctAnswer: correctAnswer)
            if !options.contains(wrongAnswer) {
                options.append(wrongAnswer)
            }
            attempts += 1
        }
        
        // 如果无法生成足够的唯一选项，添加一些默认值
        while options.count < 4 {
            let fallbackAnswer = correctAnswer + options.count
            if !options.contains(fallbackAnswer) && fallbackAnswer >= 1 && fallbackAnswer <= 40 {
                options.append(fallbackAnswer)
            } else {
                options.append(max(1, correctAnswer - options.count))
            }
        }
        
        return options.shuffled()
    }
    
    // 生成错误答案
    static private func generateWrongAnswer(correctAnswer: Int) -> Int {
        // 确保范围至少包含6个数字，以便生成足够的错误答案
        let rangeSize = 6
        let lowerBound = max(1, correctAnswer - rangeSize/2)
        let upperBound = min(40, correctAnswer + rangeSize/2)
        
        // 如果范围太小，扩展范围
        let actualLowerBound = max(1, min(lowerBound, upperBound - rangeSize + 1))
        let actualUpperBound = min(40, max(upperBound, actualLowerBound + rangeSize - 1))
        
        let range = actualLowerBound...actualUpperBound
        var wrongAnswer = Int.random(in: range)
        
        // 确保生成的错误答案不等于正确答案
        while wrongAnswer == correctAnswer {
            wrongAnswer = Int.random(in: range)
        }
        
        return wrongAnswer
    }
}

// 数学练习结果模型
struct MathQuizResult: Identifiable, Codable {
    let id = UUID()
    let operationType: MathOperationType
    let totalQuestions: Int
    let correctAnswers: Int
    let score: Int
    let timeSpent: TimeInterval
    let completedDate: Date
    let questions: [MathQuestion]
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

// 数学练习管理器
class MathQuizManager: ObservableObject {
    @Published var currentQuiz: [MathQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var userAnswers: [String] = []
    @Published var quizResults: [MathQuizResult] = []
    @Published var isQuizActive = false
    @Published var quizStartTime: Date?
    @Published var currentOperationType: MathOperationType = .mixed
    
    private let userDefaults = UserDefaults.standard
    private let mathQuizResultsKey = "SavedMathQuizResults"
    
    init() {
        loadQuizResults()
    }
    
    // 开始新的数学练习
    func startQuiz(operationType: MathOperationType, questionCount: Int = 10) {
        currentOperationType = operationType
        currentQuiz = generateMathQuestions(operationType: operationType, count: questionCount)
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
        
        let result = MathQuizResult(
            operationType: currentOperationType,
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
    var currentQuestion: MathQuestion? {
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
    
    // 生成数学题目
    private func generateMathQuestions(operationType: MathOperationType, count: Int) -> [MathQuestion] {
        var questions: [MathQuestion] = []
        var usedQuestions: Set<String> = [] // 用于检查重复题目
        var attempts = 0
        let maxAttempts = count * 10 // 防止无限循环
        
        while questions.count < count && attempts < maxAttempts {
            let question = generateSingleQuestion(operationType: operationType)
            let questionKey = "\(question.number1)\(question.operation.rawValue)\(question.number2)"
            
            // 检查是否重复
            if !usedQuestions.contains(questionKey) {
                questions.append(question)
                usedQuestions.insert(questionKey)
            }
            attempts += 1
        }
        
        return questions
    }
    
    // 生成单个题目
    private func generateSingleQuestion(operationType: MathOperationType) -> MathQuestion {
        let number1: Int
        let number2: Int
        let actualOperation: MathOperationType
        
        switch operationType {
        case .addition:
            // 加法：确保结果在1-40之间
            number1 = Int.random(in: 1...39)
            number2 = Int.random(in: 1...40-number1)
            actualOperation = .addition
            
        case .subtraction:
            // 减法：确保被减数大于减数，结果在1-40之间
            number1 = Int.random(in: 2...40)
            number2 = Int.random(in: 1...number1-1)
            actualOperation = .subtraction
            
        case .mixed:
            // 混合运算：随机选择加法或减法
            if Bool.random() {
                // 加法
                number1 = Int.random(in: 1...39)
                number2 = Int.random(in: 1...40-number1)
                actualOperation = .addition
            } else {
                // 减法
                number1 = Int.random(in: 2...40)
                number2 = Int.random(in: 1...number1-1)
                actualOperation = .subtraction
            }
        }
        
        return MathQuestion(number1: number1, number2: number2, operation: actualOperation)
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
            userDefaults.set(encoded, forKey: mathQuizResultsKey)
        }
    }
    
    // 加载练习结果
    private func loadQuizResults() {
        if let data = userDefaults.data(forKey: mathQuizResultsKey),
           let decoded = try? JSONDecoder().decode([MathQuizResult].self, from: data) {
            quizResults = decoded
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
    func getRecentResults(limit: Int = 10) -> [MathQuizResult] {
        return Array(quizResults.sorted { $0.completedDate > $1.completedDate }.prefix(limit))
    }
    
    // 获取指定操作类型的最佳成绩
    func getBestScore(for operationType: MathOperationType) -> MathQuizResult? {
        return quizResults
            .filter { $0.operationType == operationType }
            .max { $0.percentage < $1.percentage }
    }
}
