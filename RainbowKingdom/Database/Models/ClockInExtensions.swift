//
//  ClockInExtensions.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// MARK: - ClockInRecord转换扩展

extension ClockInRecord {
    /// 从RealmClockInRecord创建ClockInRecord
    init(from realmRecord: RealmClockInRecord) {
        let uuid = UUID(uuidString: realmRecord.id) ?? UUID()
        self.id = uuid
        self.date = realmRecord.date
        self.subject = realmRecord.subject
        self.score = realmRecord.score
        self.totalQuestions = realmRecord.totalQuestions
        self.timeSpent = realmRecord.timeSpent
        self.completedDate = realmRecord.completedDate
        
        // 转换questions
        if !realmRecord.questions.isEmpty {
            self.questions = realmRecord.questions.map { realmQuestion in
                QuizQuestion(
                    id: UUID(uuidString: realmQuestion.vocabularyId) ?? UUID(),
                    vocabulary: Vocabulary(
                        id: UUID(uuidString: realmQuestion.vocabularyId) ?? UUID(),
                        english: realmQuestion.vocabularyEnglish,
                        chinese: realmQuestion.vocabularyChinese,
                        group: "",
                        type: .word,
                        createdDate: Date()
                    ),
                    questionType: realmQuestion.questionType,
                    question: realmQuestion.question,
                    correctAnswer: realmQuestion.correctAnswer,
                    options: Array(realmQuestion.options),
                    hint: realmQuestion.hint,
                    readAloudStars: realmQuestion.readAloudStars
                )
            }
        } else {
            self.questions = nil
        }
        
        self.userAnswers = Array(realmRecord.userAnswers)
    }
    
    /// 转换为RealmClockInRecord
    func toRealm() -> RealmClockInRecord {
        let realmRecord = RealmClockInRecord()
        realmRecord.id = id.uuidString
        realmRecord.date = date
        realmRecord.subject = subject
        realmRecord.score = score
        realmRecord.totalQuestions = totalQuestions
        realmRecord.timeSpent = timeSpent
        realmRecord.completedDate = completedDate
        
        // 转换questions
        if let questions = questions {
            for question in questions {
                let realmQuestion = RealmQuizQuestion()
                realmQuestion.vocabularyId = question.vocabulary.id.uuidString
                realmQuestion.vocabularyEnglish = question.vocabulary.english
                realmQuestion.vocabularyChinese = question.vocabulary.chinese
                realmQuestion.questionType = question.questionType
                realmQuestion.question = question.question
                realmQuestion.correctAnswer = question.correctAnswer
                realmQuestion.options.append(objectsIn: question.options ?? [])
                realmQuestion.hint = question.hint
                realmQuestion.readAloudStars = question.readAloudStars
                realmRecord.questions.append(realmQuestion)
            }
        }
        
        realmRecord.userAnswers.append(objectsIn: userAnswers)
        return realmRecord
    }
}

extension DailyPracticeStats {
    /// 从RealmDailyPracticeStats创建DailyPracticeStats
    init(from realmStats: RealmDailyPracticeStats) {
        self.totalDays = realmStats.totalDays
        self.completedDays = realmStats.completedDays
        self.currentStreak = realmStats.currentStreak
        self.longestStreak = realmStats.longestStreak
        self.averageScore = realmStats.averageScore
        self.lastPracticeDate = realmStats.lastPracticeDate
    }
    
    /// 转换为RealmDailyPracticeStats
    func toRealm() -> RealmDailyPracticeStats {
        let realmStats = RealmDailyPracticeStats()
        realmStats.totalDays = totalDays
        realmStats.completedDays = completedDays
        realmStats.currentStreak = currentStreak
        realmStats.longestStreak = longestStreak
        realmStats.averageScore = averageScore
        realmStats.lastPracticeDate = lastPracticeDate
        return realmStats
    }
}

extension CalendarState {
    /// 从RealmCalendarState创建CalendarState
    init(from realmState: RealmCalendarState) {
        self.startDate = realmState.startDate
        self.endDate = realmState.endDate
        self.lastUpdateDate = realmState.lastUpdateDate
    }
    
    /// 转换为RealmCalendarState
    func toRealm() -> RealmCalendarState {
        let realmState = RealmCalendarState()
        realmState.startDate = startDate
        realmState.endDate = endDate
        realmState.lastUpdateDate = lastUpdateDate
        return realmState
    }
}
