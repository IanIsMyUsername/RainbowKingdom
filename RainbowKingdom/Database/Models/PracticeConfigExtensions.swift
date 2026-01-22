//
//  PracticeConfigExtensions.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// MARK: - PracticeConfig转换扩展

extension PracticeConfig {
    /// 从RealmPracticeConfig创建PracticeConfig
    init(from realmConfig: RealmPracticeConfig) {
        self.englishTranslation = EnglishTranslationConfig(
            questionCount: realmConfig.englishTranslation?.questionCount ?? 30,
            vocabularyWeeks: realmConfig.englishTranslation?.vocabularyWeeks ?? 2
        )
        self.englishFillBlank = EnglishFillBlankConfig(
            questionCount: realmConfig.englishFillBlank?.questionCount ?? 10,
            vocabularyWeeks: realmConfig.englishFillBlank?.vocabularyWeeks ?? 2
        )
        self.additionSubtraction = AdditionSubtractionConfig(
            questionCount: realmConfig.additionSubtraction?.questionCount ?? 10,
            maxNumber: realmConfig.additionSubtraction?.maxNumber ?? 40
        )
        self.multiplication = MultiplicationQuizConfig(
            maxNumber: realmConfig.multiplication?.maxNumber ?? 3,
            questionCount: realmConfig.multiplication?.questionCount ?? 10
        )
    }
    
    /// 转换为RealmPracticeConfig
    func toRealm() -> RealmPracticeConfig {
        let realmConfig = RealmPracticeConfig()
        
        let realmEnglishTranslation = RealmEnglishTranslationConfig()
        realmEnglishTranslation.questionCount = englishTranslation.questionCount
        realmEnglishTranslation.vocabularyWeeks = englishTranslation.vocabularyWeeks
        realmConfig.englishTranslation = realmEnglishTranslation
        
        let realmEnglishFillBlank = RealmEnglishFillBlankConfig()
        realmEnglishFillBlank.questionCount = englishFillBlank.questionCount
        realmEnglishFillBlank.vocabularyWeeks = englishFillBlank.vocabularyWeeks
        realmConfig.englishFillBlank = realmEnglishFillBlank
        
        let realmAdditionSubtraction = RealmAdditionSubtractionConfig()
        realmAdditionSubtraction.questionCount = additionSubtraction.questionCount
        realmAdditionSubtraction.maxNumber = additionSubtraction.maxNumber
        realmConfig.additionSubtraction = realmAdditionSubtraction
        
        let realmMultiplication = RealmMultiplicationQuizConfig()
        realmMultiplication.maxNumber = multiplication.maxNumber
        realmMultiplication.questionCount = multiplication.questionCount
        realmConfig.multiplication = realmMultiplication
        
        return realmConfig
    }
}
