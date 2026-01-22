//
//  RealmMultiplicationQuiz.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

/// 乘法题目模型（嵌套对象）
class RealmMultiplicationQuestion: EmbeddedObject {
    @Persisted var number1: Int = 0
    @Persisted var number2: Int = 0
    @Persisted var question: String = ""
    @Persisted var correctAnswer: Int = 0
    @Persisted var options: List<Int> = List<Int>()
}

/// 乘法练习结果模型
class RealmMultiplicationQuizResult: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var maxNumber: Int = 0 // 数字范围上限
    @Persisted var totalQuestions: Int = 0
    @Persisted var correctAnswers: Int = 0
    @Persisted var score: Int = 0
    @Persisted var timeSpent: Double = 0.0 // TimeInterval
    @Persisted var completedDate: Date = Date()
    @Persisted var questions: List<RealmMultiplicationQuestion> = List<RealmMultiplicationQuestion>()
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
