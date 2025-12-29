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
    let number3: Int
    let operation: MathOperationType
    let operation2: MathOperationType
    let question: String
    let correctAnswer: Int
    let options: [Int]? // 选择题选项
    
    init(number1: Int, number2: Int, number3: Int, operation: MathOperationType, operation2: MathOperationType) {
        self.number1 = number1
        self.number2 = number2
        self.number3 = number3
        self.operation = operation
        self.operation2 = operation2
        
        // 先计算中间结果和最终答案
        let intermediateResult: Int
        let correctAnswer: Int
        let question: String
        
        // 计算第一个运算的结果
        switch operation {
        case .addition:
            intermediateResult = number1 + number2
        case .subtraction:
            intermediateResult = number1 - number2
        case .mixed:
            intermediateResult = number1 + number2
        }
        
        // 计算第二个运算的结果（最终答案）
        switch operation2 {
        case .addition:
            correctAnswer = intermediateResult + number3
        case .subtraction:
            correctAnswer = intermediateResult - number3
        case .mixed:
            correctAnswer = intermediateResult + number3
        }
        
        // 构建题目字符串
        let op1Symbol = operation == .addition ? "+" : "-"
        let op2Symbol = operation2 == .addition ? "+" : "-"
        question = "\(number1) \(op1Symbol) \(number2) \(op2Symbol) \(number3) = ?"
        
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
        
        // 如果无法生成足够的唯一选项，添加一些默认值（确保在1-70范围内）
        while options.count < 4 {
            let fallbackAnswer1 = min(70, max(1, correctAnswer + options.count))
            let fallbackAnswer2 = min(70, max(1, correctAnswer - options.count))
            
            if !options.contains(fallbackAnswer1) && fallbackAnswer1 >= 1 && fallbackAnswer1 <= 70 {
                options.append(fallbackAnswer1)
            } else if !options.contains(fallbackAnswer2) && fallbackAnswer2 >= 1 && fallbackAnswer2 <= 70 {
                options.append(fallbackAnswer2)
            } else {
                // 如果都重复，尝试其他值
                let alternative = min(70, max(1, correctAnswer + options.count * 2))
                if !options.contains(alternative) {
                    options.append(alternative)
                } else {
                    options.append(max(1, min(70, correctAnswer - options.count * 2)))
                }
            }
        }
        
        return options.shuffled()
    }
    
    // 生成错误答案
    static private func generateWrongAnswer(correctAnswer: Int) -> Int {
        // 确保范围至少包含6个数字，以便生成足够的错误答案
        let rangeSize = 6
        let lowerBound = max(1, correctAnswer - rangeSize/2)
        let upperBound = min(70, correctAnswer + rangeSize/2)
        
        // 如果范围太小，扩展范围
        let actualLowerBound = max(1, min(lowerBound, upperBound - rangeSize + 1))
        let actualUpperBound = min(70, max(upperBound, actualLowerBound + rangeSize - 1))
        
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
            let questionKey = "\(question.number1)\(question.operation.rawValue)\(question.number2)\(question.operation2.rawValue)\(question.number3)"
            
            // 检查是否重复
            if !usedQuestions.contains(questionKey) {
                questions.append(question)
                usedQuestions.insert(questionKey)
            }
            attempts += 1
        }
        
        return questions
    }
    
    // 生成单个题目（连续加减2个数）
    private func generateSingleQuestion(operationType: MathOperationType) -> MathQuestion {
        // 初始化默认值（确保所有变量都有初始值）
        var number1 = 10
        var number2 = 5
        var number3 = 3
        var operation1: MathOperationType = .addition
        var operation2: MathOperationType = .subtraction
        var attempts = 0
        let maxAttempts = 100 // 防止无限循环
        
        repeat {
            // 随机生成第一个数字（范围1-70）
            number1 = Int.random(in: 1...70)
            
            // 随机选择第一个运算符
            if operationType == .addition {
                operation1 = .addition
            } else if operationType == .subtraction {
                operation1 = .subtraction
            } else {
                // mixed: 随机选择
                operation1 = Bool.random() ? .addition : .subtraction
            }
            
            // 根据第一个运算符生成第二个数字，确保中间结果在1-70之间
            let intermediateResult: Int
            if operation1 == .addition {
                // 加法：中间结果 = number1 + number2，需要 >= 1 且 <= 70
                // number2 可以是 1 到 (70 - number1)
                let maxNumber2 = 70 - number1
                guard maxNumber2 >= 1 else {
                    attempts += 1
                    continue
                }
                number2 = Int.random(in: 1...maxNumber2)
                intermediateResult = number1 + number2
            } else {
                // 减法：中间结果 = number1 - number2，需要 >= 1 且 <= 70
                // 确保 number1 > number2，且中间结果 >= 1
                guard number1 > 1 else {
                    attempts += 1
                    continue
                }
                number2 = Int.random(in: 1...(number1 - 1))
                intermediateResult = number1 - number2
            }
            
            // 确保中间结果在1-70之间
            guard intermediateResult >= 1 && intermediateResult <= 70 else {
                attempts += 1
                continue
            }
            
            // 随机选择第二个运算符
            if operationType == .addition {
                operation2 = .addition
            } else if operationType == .subtraction {
                operation2 = .subtraction
            } else {
                // mixed: 随机选择
                operation2 = Bool.random() ? .addition : .subtraction
            }
            
            // 根据第二个运算符生成第三个数字，确保最终结果在1-70之间
            let finalResult: Int
            if operation2 == .addition {
                // 加法：最终结果 = intermediateResult + number3，需要 >= 1 且 <= 70
                // number3 可以是 1 到 (70 - intermediateResult)
                let maxNumber3 = 70 - intermediateResult
                guard maxNumber3 >= 1 else {
                    attempts += 1
                    continue
                }
                number3 = Int.random(in: 1...maxNumber3)
                finalResult = intermediateResult + number3
            } else {
                // 减法：最终结果 = intermediateResult - number3，需要 >= 1 且 <= 70
                // 确保 intermediateResult > number3，且最终结果 >= 1
                guard intermediateResult > 1 else {
                    attempts += 1
                    continue
                }
                number3 = Int.random(in: 1...(intermediateResult - 1))
                finalResult = intermediateResult - number3
            }
            
            // 确保最终结果在1-70之间
            guard finalResult >= 1 && finalResult <= 70 else {
                attempts += 1
                continue
            }
            
            // 成功生成有效题目，退出循环
            break
            
        } while attempts < maxAttempts
        
        // 如果尝试次数过多，变量已经使用默认值（10 + 5 - 3 = 12）
        // 验证默认值：10 + 5 = 15 (<= 40), 15 - 3 = 12 (1-40范围内) ✓
        
        return MathQuestion(number1: number1, number2: number2, number3: number3, operation: operation1, operation2: operation2)
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
