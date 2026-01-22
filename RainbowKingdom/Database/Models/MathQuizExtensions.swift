//
//  MathQuizExtensions.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// MARK: - MathQuiz转换扩展

extension MathQuestion {
    /// 从RealmMathQuestion创建MathQuestion
    init(from realmQuestion: RealmMathQuestion) {
        self.init(
            id: UUID(),
            number1: realmQuestion.number1,
            number2: realmQuestion.number2,
            number3: realmQuestion.number3,
            operation: realmQuestion.operation,
            operation2: realmQuestion.operation2
        )
    }
    
    /// 转换为RealmMathQuestion
    func toRealm() -> RealmMathQuestion {
        let realmQuestion = RealmMathQuestion()
        realmQuestion.number1 = number1
        realmQuestion.number2 = number2
        realmQuestion.number3 = number3
        realmQuestion.operation = operation
        realmQuestion.operation2 = operation2
        realmQuestion.question = question
        realmQuestion.correctAnswer = correctAnswer
        realmQuestion.options.append(objectsIn: options ?? [])
        return realmQuestion
    }
}

extension MathQuizResult {
    /// 从RealmMathQuizResult创建MathQuizResult
    init(from realmResult: RealmMathQuizResult) {
        let uuid = UUID(uuidString: realmResult.id) ?? UUID()
        self.id = uuid
        self.operationType = realmResult.operationType
        self.totalQuestions = realmResult.totalQuestions
        self.correctAnswers = realmResult.correctAnswers
        self.score = realmResult.score
        self.timeSpent = realmResult.timeSpent
        self.completedDate = realmResult.completedDate
        self.questions = realmResult.questions.map { MathQuestion(from: $0) }
        self.userAnswers = Array(realmResult.userAnswers)
    }
    
    /// 转换为RealmMathQuizResult
    func toRealm() -> RealmMathQuizResult {
        let realmResult = RealmMathQuizResult()
        realmResult.id = id.uuidString
        realmResult.operationType = operationType
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
