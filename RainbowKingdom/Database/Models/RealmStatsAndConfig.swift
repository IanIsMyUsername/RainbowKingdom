//
//  RealmStatsAndConfig.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

/// 每日一练统计模型
class RealmDailyPracticeStats: Object {
    @Persisted(primaryKey: true) var id: String = "singleton" // 单例模式
    @Persisted var totalDays: Int = 0
    @Persisted var completedDays: Int = 0
    @Persisted var currentStreak: Int = 0
    @Persisted var longestStreak: Int = 0
    @Persisted var averageScore: Double = 0.0
    @Persisted var lastPracticeDate: Date?
    
    var completionRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays) * 100
    }
}

/// 日历状态模型
class RealmCalendarState: Object {
    @Persisted(primaryKey: true) var id: String = "singleton" // 单例模式
    @Persisted var startDate: Date = Date()
    @Persisted var endDate: Date = Date()
    @Persisted var lastUpdateDate: Date = Date()
    
    override init() {
        super.init()
        let calendar = Calendar.current
        let today = Date()
        self.startDate = calendar.date(byAdding: .day, value: -14, to: today) ?? today
        self.endDate = calendar.date(byAdding: .day, value: 6, to: today) ?? today
        self.lastUpdateDate = today
    }
}

// MARK: - 练习配置模型

/// 英语翻译练习配置（嵌套对象）
class RealmEnglishTranslationConfig: EmbeddedObject {
    @Persisted var questionCount: Int = 30
    @Persisted var vocabularyWeeks: Int = 2 // 单词时间范围（月份）
}

/// 英语填空练习配置（嵌套对象）
class RealmEnglishFillBlankConfig: EmbeddedObject {
    @Persisted var questionCount: Int = 10
    @Persisted var vocabularyWeeks: Int = 1 // 单词时间范围（月份）
}

/// 加减法练习配置（嵌套对象）
class RealmAdditionSubtractionConfig: EmbeddedObject {
    @Persisted var questionCount: Int = 10
    @Persisted var maxNumber: Int = 40 // 多少以内
}

/// 乘法练习配置（嵌套对象）
class RealmMultiplicationQuizConfig: EmbeddedObject {
    @Persisted var maxNumber: Int = 3 // 默认数字范围上限（小于3，即1-2）
    @Persisted var questionCount: Int = 10 // 默认题目数量
}

/// 统一的练习配置模型
class RealmPracticeConfig: Object {
    @Persisted(primaryKey: true) var id: String = "singleton" // 单例模式
    @Persisted var englishTranslation: RealmEnglishTranslationConfig?
    @Persisted var englishFillBlank: RealmEnglishFillBlankConfig?
    @Persisted var additionSubtraction: RealmAdditionSubtractionConfig?
    @Persisted var multiplication: RealmMultiplicationQuizConfig?
    
    override init() {
        super.init()
        self.englishTranslation = RealmEnglishTranslationConfig()
        self.englishFillBlank = RealmEnglishFillBlankConfig()
        self.additionSubtraction = RealmAdditionSubtractionConfig()
        self.multiplication = RealmMultiplicationQuizConfig()
    }
}
