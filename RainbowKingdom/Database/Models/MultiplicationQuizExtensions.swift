//
//  MultiplicationQuizExtensions.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// MARK: - MultiplicationQuiz转换扩展

extension MultiplicationQuestion {
    /// 从RealmMultiplicationQuestion创建MultiplicationQuestion
    init(from realmQuestion: RealmMultiplicationQuestion) {
        self.init(
            id: UUID(),
            number1: realmQuestion.number1,
            number2: realmQuestion.number2
        )
    }
    
    /// 转换为RealmMultiplicationQuestion
    func toRealm() -> RealmMultiplicationQuestion {
        let realmQuestion = RealmMultiplicationQuestion()
        realmQuestion.number1 = number1
        realmQuestion.number2 = number2
        realmQuestion.question = question
        realmQuestion.correctAnswer = correctAnswer
        realmQuestion.options.append(objectsIn: options ?? [])
        return realmQuestion
    }
}

extension MultiplicationQuizResult {
    /// 从RealmMultiplicationQuizResult创建MultiplicationQuizResult
    init(from realmResult: RealmMultiplicationQuizResult) {
        let uuid = UUID(uuidString: realmResult.id) ?? UUID()
        self.id = uuid
        self.maxNumber = realmResult.maxNumber
        self.totalQuestions = realmResult.totalQuestions
        self.correctAnswers = realmResult.correctAnswers
        self.score = realmResult.score
        self.timeSpent = realmResult.timeSpent
        self.completedDate = realmResult.completedDate
        self.questions = realmResult.questions.map { MultiplicationQuestion(from: $0) }
        self.userAnswers = Array(realmResult.userAnswers)
    }
    
    /// 转换为RealmMultiplicationQuizResult
    func toRealm() -> RealmMultiplicationQuizResult {
        let realmResult = RealmMultiplicationQuizResult()
        realmResult.id = id.uuidString
        realmResult.maxNumber = maxNumber
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
