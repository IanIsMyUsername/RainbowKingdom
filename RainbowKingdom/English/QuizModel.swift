//
//  QuizModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// 测验题型枚举
enum QuizQuestionType: String, CaseIterable, Codable, PersistableEnum {
    case chineseToEnglish = "汉语翻译成英语"
    case englishToChinese = "英语翻译成汉语"
    
    var displayName: String {
        return self.rawValue
    }
}

// 测验类型枚举
enum QuizType: String, CaseIterable, Codable, PersistableEnum {
    case multipleChoice = "选择题"
    case fillInBlank = "填空题"
    
    var displayName: String {
        return self.rawValue
    }
}

// 测验分类枚举
enum QuizCategory: String, CaseIterable {
    case questionType = "测验题型"
    case quizType = "测验类型"
    
    var displayName: String {
        return self.rawValue
    }
    
    var questionTypes: [QuizQuestionType] {
        switch self {
        case .questionType:
            return [.chineseToEnglish, .englishToChinese]
        case .quizType:
            return []
        }
    }
    
    var quizTypes: [QuizType] {
        switch self {
        case .questionType:
            return []
        case .quizType:
            return [.multipleChoice, .fillInBlank]
        }
    }
}

// 题目类型枚举
enum QuestionType: String, CaseIterable, Codable, PersistableEnum {
    case translation = "翻译题"
    case multipleChoice = "选择题"
    case fillInBlank = "填空题"
}

// 测验范围枚举
enum QuizScope: String, CaseIterable, Codable, PersistableEnum {
    case all = "全部词汇"
    case selectedGroup = "选中组"
    case today = "今天添加"
    case thisWeek = "本周添加"
    case thisMonth = "本月添加"
    
    var displayName: String {
        return self.rawValue
    }
}

// 测验题目模型
struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let vocabulary: Vocabulary
    let questionType: QuestionType
    let question: String
    let correctAnswer: String
    let options: [String]? // 选择题选项
    let hint: String? // 提示信息
    var readAloudStars: Int? = nil // 跟读得分（0-3 星），没跟读为 nil
    
    init(id: UUID = UUID(), vocabulary: Vocabulary, questionType: QuestionType, question: String, correctAnswer: String, options: [String]? = nil, hint: String? = nil, readAloudStars: Int? = nil) {
        self.id = id
        self.vocabulary = vocabulary
        self.questionType = questionType
        self.question = question
        self.correctAnswer = correctAnswer
        self.options = options
        self.hint = hint
        self.readAloudStars = readAloudStars
    }
}

// 测验结果模型
struct QuizResult: Identifiable, Codable {
    let id: UUID
    let questionType: QuizQuestionType?
    let quizType: QuizType?
    let scope: QuizScope
    let totalQuestions: Int
    let correctAnswers: Int
    let score: Int
    let timeSpent: TimeInterval
    let completedDate: Date
    let questions: [QuizQuestion]
    let userAnswers: [String]
    
    init(id: UUID = UUID(), questionType: QuizQuestionType? = nil, quizType: QuizType? = nil, scope: QuizScope, totalQuestions: Int, correctAnswers: Int, score: Int, timeSpent: TimeInterval, completedDate: Date, questions: [QuizQuestion], userAnswers: [String]) {
        self.id = id
        self.questionType = questionType
        self.quizType = quizType
        self.scope = scope
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.score = score
        self.timeSpent = timeSpent
        self.completedDate = completedDate
        self.questions = questions
        self.userAnswers = userAnswers
    }
    
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

// 测验管理器
class QuizManager: ObservableObject {
    @Published var currentQuiz: [QuizQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var userAnswers: [String] = []
    @Published var quizResults: [QuizResult] = []
    @Published var isQuizActive = false
    @Published var quizStartTime: Date?
    @Published var currentQuestionType: QuizQuestionType?
    @Published var currentQuizType: QuizType?
    
    private let dbManager = DatabaseManager.shared
    
    init() {
        loadFromRealm()
    }
    
    // 开始新测验
    func startQuiz(questionType: QuizQuestionType?, quizType: QuizType?, scope: QuizScope, vocabularies: [Vocabulary], questionCount: Int = 10) {
        let filteredVocabularies = filterVocabulariesByScope(vocabularies, scope: scope)
        guard !filteredVocabularies.isEmpty else { return }
        
        // 存储当前选择的类型
        currentQuestionType = questionType
        currentQuizType = quizType
        
        let selectedVocabularies = Array(filteredVocabularies.shuffled().prefix(min(questionCount, filteredVocabularies.count)))
        currentQuiz = generateQuestions(from: selectedVocabularies, questionType: questionType, quizType: quizType)
        currentQuestionIndex = 0
        userAnswers = Array(repeating: "", count: currentQuiz.count)
        isQuizActive = true
        quizStartTime = Date()
    }
    
    // 结束测验
    func endQuiz() {
        guard let startTime = quizStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        let correctAnswers = calculateCorrectAnswers()
        let score = correctAnswers
        
        let result = QuizResult(
            questionType: currentQuestionType,
            quizType: currentQuizType,
            scope: .all, // 这里可以根据实际选择的范围设置
            totalQuestions: currentQuiz.count,
            correctAnswers: correctAnswers,
            score: score,
            timeSpent: timeSpent,
            completedDate: Date(),
            questions: currentQuiz,
            userAnswers: userAnswers
        )
        
        quizResults.append(result)
        saveToRealm(result)
        
        isQuizActive = false
        quizStartTime = nil
    }
    
    // 获取当前题目
    var currentQuestion: QuizQuestion? {
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
    
    // 根据范围筛选词汇
    private func filterVocabulariesByScope(_ vocabularies: [Vocabulary], scope: QuizScope) -> [Vocabulary] {
        switch scope {
        case .all:
            return vocabularies
        case .selectedGroup:
            // 这里需要从外部传入已选择的组，暂时返回全部
            return vocabularies
        case .today:
            return vocabularies.filter { Calendar.current.isDateInToday($0.createdDate) }
        case .thisWeek:
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: Date(), toGranularity: .month) }
        }
    }
    
    // 生成题目
    private func generateQuestions(from vocabularies: [Vocabulary], questionType: QuizQuestionType?, quizType: QuizType?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        for vocabulary in vocabularies {
            // 根据测验题型和测验类型的组合生成题目
            if let questionType = questionType, let quizType = quizType {
                // 同时选择了测验题型和测验类型，生成组合题目
                switch (questionType, quizType) {
                case (.chineseToEnglish, .multipleChoice):
                    let question = generateMultipleChoiceQuestion(for: vocabulary, allVocabularies: vocabularies, isEnglishToChinese: false)
                    questions.append(question)
                    
                case (.englishToChinese, .multipleChoice):
                    let question = generateMultipleChoiceQuestion(for: vocabulary, allVocabularies: vocabularies, isEnglishToChinese: true)
                    questions.append(question)
                    
                case (.chineseToEnglish, .fillInBlank):
                    let question = generateFillInBlankQuestion(for: vocabulary, isEnglishToChinese: false)
                    questions.append(question)
                    
                case (.englishToChinese, .fillInBlank):
                    let question = generateFillInBlankQuestion(for: vocabulary, isEnglishToChinese: true)
                    questions.append(question)
                }
            } else if let questionType = questionType {
                // 只选择了测验题型：翻译类
                switch questionType {
                case .chineseToEnglish:
                    let question = QuizQuestion(
                        vocabulary: vocabulary,
                        questionType: .translation,
                        question: "请将以下中文翻译成英文：\n\(vocabulary.chinese)",
                        correctAnswer: vocabulary.english,
                        hint: "类型：\(vocabulary.type.rawValue)"
                    )
                    questions.append(question)
                    
                case .englishToChinese:
                    let question = QuizQuestion(
                        vocabulary: vocabulary,
                        questionType: .translation,
                        question: "请将以下英文翻译成中文：\n\(vocabulary.english)",
                        correctAnswer: vocabulary.chinese,
                        hint: "类型：\(vocabulary.type.rawValue)"
                    )
                    questions.append(question)
                }
            } else if let quizType = quizType {
                // 只选择了测验类型：选择题或填空题
                switch quizType {
                case .multipleChoice:
                    let question = generateMultipleChoiceQuestion(for: vocabulary, allVocabularies: vocabularies)
                    questions.append(question)
                    
                case .fillInBlank:
                    let question = generateFillInBlankQuestion(for: vocabulary)
                    questions.append(question)
                }
            }
        }
        
        return questions
    }
    
    // 生成选择题
    private func generateMultipleChoiceQuestion(for vocabulary: Vocabulary, allVocabularies: [Vocabulary], isEnglishToChinese: Bool? = nil) -> QuizQuestion {
        let isEnglishToChinese = isEnglishToChinese ?? Bool.random()
        let question: String
        let correctAnswer: String
        let options: [String]
        
        if isEnglishToChinese {
            question = "请选择以下英文的中文意思：\n\(vocabulary.english)"
            correctAnswer = vocabulary.chinese
            
            // 生成错误选项
            let wrongOptions = generateWrongOptions(for: vocabulary.chinese, isChinese: true, allVocabularies: allVocabularies)
            options = ([correctAnswer] + wrongOptions).shuffled()
        } else {
            question = "请选择以下中文的英文翻译：\n\(vocabulary.chinese)"
            correctAnswer = vocabulary.english
            
            // 生成错误选项
            let wrongOptions = generateWrongOptions(for: vocabulary.english, isChinese: false, allVocabularies: allVocabularies)
            options = ([correctAnswer] + wrongOptions).shuffled()
        }
        
        return QuizQuestion(
            vocabulary: vocabulary,
            questionType: .multipleChoice,
            question: question,
            correctAnswer: correctAnswer,
            options: options,
            hint: "类型：\(vocabulary.type.rawValue)"
        )
    }
    
    // 生成填空题
    private func generateFillInBlankQuestion(for vocabulary: Vocabulary, isEnglishToChinese: Bool? = nil) -> QuizQuestion {
        let isEnglishToChinese = isEnglishToChinese ?? Bool.random()
        let question: String
        let correctAnswer: String
        
        if isEnglishToChinese {
            question = "请填写以下英文的中文意思：\n\(vocabulary.english) = _____"
            correctAnswer = vocabulary.chinese
        } else {
            question = "请填写以下中文的英文翻译：\n\(vocabulary.chinese) = _____"
            correctAnswer = vocabulary.english
        }
        
        return QuizQuestion(
            vocabulary: vocabulary,
            questionType: .fillInBlank,
            question: question,
            correctAnswer: correctAnswer,
            hint: "类型：\(vocabulary.type.rawValue)"
        )
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
    
    // 计算正确答案数量
    private func calculateCorrectAnswers() -> Int {
        var correctCount = 0
        for (index, question) in currentQuiz.enumerated() {
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
    
    // MARK: - Realm数据加载和保存
    
    /// 从Realm加载练习结果
    private func loadFromRealm() {
        do {
            let realmResults = try dbManager.objects(RealmQuizResult.self)
            quizResults = realmResults.map { QuizResult(from: $0) }
            print("从Realm加载了 \(quizResults.count) 条英语测验结果")
        } catch {
            print("从Realm加载英语测验结果失败: \(error)")
        }
    }
    
    /// 保存练习结果到Realm
    private func saveToRealm(_ result: QuizResult) {
        do {
            let realmResult = result.toRealm()
            try dbManager.add(realmResult)
            print("已保存英语测验结果到Realm")
        } catch {
            print("保存英语测验结果失败: \(error)")
        }
    }
    
    // 重置测验
    func resetQuiz() {
        currentQuiz = []
        currentQuestionIndex = 0
        userAnswers = []
        isQuizActive = false
        quizStartTime = nil
    }
}
