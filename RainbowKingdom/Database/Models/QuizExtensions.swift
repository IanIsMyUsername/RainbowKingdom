//
//  QuizExtensions.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// MARK: - Quiz转换扩展

extension QuizQuestion {
    /// 从RealmQuizQuestion创建QuizQuestion
    init(from realmQuestion: RealmQuizQuestion) {
        let uuid = UUID(uuidString: realmQuestion.vocabularyId) ?? UUID()
        self.init(
            id: uuid,
            vocabulary: Vocabulary(
                id: uuid,
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
            hint: realmQuestion.hint
        )
    }
    
    /// 转换为RealmQuizQuestion
    func toRealm() -> RealmQuizQuestion {
        let realmQuestion = RealmQuizQuestion()
        realmQuestion.vocabularyId = vocabulary.id.uuidString
        realmQuestion.vocabularyEnglish = vocabulary.english
        realmQuestion.vocabularyChinese = vocabulary.chinese
        realmQuestion.questionType = questionType
        realmQuestion.question = question
        realmQuestion.correctAnswer = correctAnswer
        realmQuestion.options.append(objectsIn: options ?? [])
        realmQuestion.hint = hint
        return realmQuestion
    }
}

extension QuizResult {
    /// 从RealmQuizResult创建QuizResult
    init(from realmResult: RealmQuizResult) {
        let uuid = UUID(uuidString: realmResult.id) ?? UUID()
        self.id = uuid
        self.questionType = realmResult.questionType
        self.quizType = realmResult.quizType
        self.scope = realmResult.scope
        self.totalQuestions = realmResult.totalQuestions
        self.correctAnswers = realmResult.correctAnswers
        self.score = realmResult.score
        self.timeSpent = realmResult.timeSpent
        self.completedDate = realmResult.completedDate
        self.questions = realmResult.questions.map { QuizQuestion(from: $0) }
        self.userAnswers = Array(realmResult.userAnswers)
    }
    
    /// 转换为RealmQuizResult
    func toRealm() -> RealmQuizResult {
        let realmResult = RealmQuizResult()
        realmResult.id = id.uuidString
        realmResult.questionType = questionType
        realmResult.quizType = quizType
        realmResult.scope = scope
        realmResult.totalQuestions = totalQuestions
        realmResult.correctAnswers = correctAnswers
        realmResult.score = score
        realmResult.timeSpent = timeSpent
        realmResult.completedDate = completedDate
        
        for question in questions {
            realmResult.questions.append(question.toRealm())
        }
        
        realmResult.userAnswers.append(objectsIn: userAnswers)
        return realmResult
    }
}
