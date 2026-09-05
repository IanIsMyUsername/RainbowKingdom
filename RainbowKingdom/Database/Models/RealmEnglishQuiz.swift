//
//  RealmEnglishQuiz.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// 注意：QuestionType, QuizQuestionType, QuizType, QuizScope 枚举已在 QuizModel.swift 中定义

/// 测验题目模型（嵌套对象）
class RealmQuizQuestion: EmbeddedObject {
    @Persisted var vocabularyId: String = "" // 关联到RealmVocabulary的id
    @Persisted var vocabularyEnglish: String = "" // 冗余存储，便于查询
    @Persisted var vocabularyChinese: String = "" // 冗余存储，便于查询
    @Persisted var questionType: QuestionType = .translation
    @Persisted var question: String = ""
    @Persisted var correctAnswer: String = ""
    @Persisted var options: List<String> = List<String>()
    @Persisted var hint: String?
    @Persisted var readAloudStars: Int? // 跟读得分（0-3 星）
}

/// 英语测验结果模型
class RealmQuizResult: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var questionType: QuizQuestionType?
    @Persisted var quizType: QuizType?
    @Persisted var scope: QuizScope = .all
    @Persisted var totalQuestions: Int = 0
    @Persisted var correctAnswers: Int = 0
    @Persisted var score: Int = 0
    @Persisted var timeSpent: Double = 0.0 // TimeInterval
    @Persisted var completedDate: Date = Date()
    @Persisted var questions: List<RealmQuizQuestion> = List<RealmQuizQuestion>()
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
