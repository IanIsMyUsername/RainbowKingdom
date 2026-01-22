//
//  RealmClockIn.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

/// 打卡记录模型（每日一练结果）
class RealmClockInRecord: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var date: Date = Date()
    @Persisted var subject: String = "" // 科目：英语翻译、英语填空、加减法、乘法
    @Persisted var score: Int = 0
    @Persisted var totalQuestions: Int = 0
    @Persisted var timeSpent: Double = 0.0 // TimeInterval
    @Persisted var completedDate: Date = Date()
    @Persisted var questions: List<RealmQuizQuestion> = List<RealmQuizQuestion>() // 可选，支持数学练习
    @Persisted var userAnswers: List<String> = List<String>()
    
    var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
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
    
    var isCompleted: Bool {
        return score > 0
    }
}
