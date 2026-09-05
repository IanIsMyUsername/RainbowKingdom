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
            vocabularyWeeks: realmConfig.englishTranslation?.vocabularyWeeks ?? 2,
            isEnabled: realmConfig.englishTranslation?.isEnabled ?? true
        )
        self.englishFillBlank = EnglishFillBlankConfig(
            questionCount: realmConfig.englishFillBlank?.questionCount ?? 10,
            vocabularyWeeks: realmConfig.englishFillBlank?.vocabularyWeeks ?? 1,
            isEnabled: realmConfig.englishFillBlank?.isEnabled ?? true
        )
        self.additionSubtraction = AdditionSubtractionConfig(
            questionCount: realmConfig.additionSubtraction?.questionCount ?? 10,
            maxNumber: realmConfig.additionSubtraction?.maxNumber ?? 40,
            isEnabled: realmConfig.additionSubtraction?.isEnabled ?? true
        )
        self.multiplication = MultiplicationQuizConfig(
            maxNumber: realmConfig.multiplication?.maxNumber ?? 3,
            questionCount: realmConfig.multiplication?.questionCount ?? 10,
            isEnabled: realmConfig.multiplication?.isEnabled ?? true
        )
        self.animalBattle = AnimalBattleConfig(
            questionCount: realmConfig.animalBattle?.questionCount ?? 10,
            isEnabled: realmConfig.animalBattle?.isEnabled ?? true
        )
        self.readAloud = ReadAloudConfig(
            isEnabled: realmConfig.readAloud?.isEnabled ?? true,
            passStars: realmConfig.readAloud?.passStars ?? 2,
            maxAttempts: realmConfig.readAloud?.maxAttempts ?? 3
        )
    }

    /// 转换为RealmPracticeConfig
    func toRealm() -> RealmPracticeConfig {
        let realmConfig = RealmPracticeConfig()

        let realmEnglishTranslation = RealmEnglishTranslationConfig()
        realmEnglishTranslation.questionCount = englishTranslation.questionCount
        realmEnglishTranslation.vocabularyWeeks = englishTranslation.vocabularyWeeks
        realmEnglishTranslation.isEnabled = englishTranslation.isEnabled
        realmConfig.englishTranslation = realmEnglishTranslation

        let realmEnglishFillBlank = RealmEnglishFillBlankConfig()
        realmEnglishFillBlank.questionCount = englishFillBlank.questionCount
        realmEnglishFillBlank.vocabularyWeeks = englishFillBlank.vocabularyWeeks
        realmEnglishFillBlank.isEnabled = englishFillBlank.isEnabled
        realmConfig.englishFillBlank = realmEnglishFillBlank

        let realmAdditionSubtraction = RealmAdditionSubtractionConfig()
        realmAdditionSubtraction.questionCount = additionSubtraction.questionCount
        realmAdditionSubtraction.maxNumber = additionSubtraction.maxNumber
        realmAdditionSubtraction.isEnabled = additionSubtraction.isEnabled
        realmConfig.additionSubtraction = realmAdditionSubtraction

        let realmMultiplication = RealmMultiplicationQuizConfig()
        realmMultiplication.maxNumber = multiplication.maxNumber
        realmMultiplication.questionCount = multiplication.questionCount
        realmMultiplication.isEnabled = multiplication.isEnabled
        realmConfig.multiplication = realmMultiplication

        let realmAnimalBattle = RealmAnimalBattleConfig()
        realmAnimalBattle.questionCount = animalBattle.questionCount
        realmAnimalBattle.isEnabled = animalBattle.isEnabled
        realmConfig.animalBattle = realmAnimalBattle

        let realmReadAloud = RealmReadAloudConfig()
        realmReadAloud.isEnabled = readAloud.isEnabled
        realmReadAloud.passStars = readAloud.passStars
        realmReadAloud.maxAttempts = readAloud.maxAttempts
        realmConfig.readAloud = realmReadAloud

        return realmConfig
    }
}
