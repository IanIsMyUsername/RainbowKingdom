//
//  RealmMathQuiz.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// 注意：MathOperationType 枚举已在 MathQuizModel.swift 中定义

/// 数学题目模型（嵌套对象）
class RealmMathQuestion: EmbeddedObject {
    @Persisted var number1: Int = 0
    @Persisted var number2: Int = 0
    @Persisted var number3: Int = 0
    @Persisted var operation: MathOperationType = .addition
    @Persisted var operation2: MathOperationType = .addition
    @Persisted var question: String = ""
    @Persisted var correctAnswer: Int = 0
    @Persisted var options: List<Int> = List<Int>()
}

/// 数学练习结果模型
class RealmMathQuizResult: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var operationType: MathOperationType = .mixed
    @Persisted var totalQuestions: Int = 0
    @Persisted var correctAnswers: Int = 0
    @Persisted var score: Int = 0
    @Persisted var timeSpent: Double = 0.0 // TimeInterval
    @Persisted var completedDate: Date = Date()
    @Persisted var questions: List<RealmMathQuestion> = List<RealmMathQuestion>()
    @Persisted var userAnswers: List<String> = List<String>()
    
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
