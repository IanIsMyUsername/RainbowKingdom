//
//  PracticeConfigModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// 统一的练习配置模型
struct PracticeConfig: Codable {
    // 英语翻译练习配置
    var englishTranslation: EnglishTranslationConfig = EnglishTranslationConfig()
    
    // 英语填空练习配置
    var englishFillBlank: EnglishFillBlankConfig = EnglishFillBlankConfig()
    
    // 加减法练习配置
    var additionSubtraction: AdditionSubtractionConfig = AdditionSubtractionConfig()
    
    // 乘法练习配置
    var multiplication: MultiplicationQuizConfig = MultiplicationQuizConfig()

    // 动物大作战配置
    var animalBattle: AnimalBattleConfig = AnimalBattleConfig()

    // 跟读配置（拼对单词后跟读打分，达标才能下一题）
    var readAloud: ReadAloudConfig = ReadAloudConfig()
}

// 英语翻译练习配置
struct EnglishTranslationConfig: Codable {
    var questionCount: Int = 30
    var vocabularyWeeks: Int = 2 // 单词时间范围（月份）
    var isEnabled: Bool = true
}

// 英语填空练习配置
struct EnglishFillBlankConfig: Codable {
    var questionCount: Int = 10
    var vocabularyWeeks: Int = 1 // 单词时间范围（月份）
    var isEnabled: Bool = true
}

// 加减法练习配置
struct AdditionSubtractionConfig: Codable {
    var questionCount: Int = 10
    var maxNumber: Int = 40 // 多少以内
    var isEnabled: Bool = true
}

// 动物大作战配置（看图拼写动物单词）
struct AnimalBattleConfig: Codable {
    var questionCount: Int = 10
    var isEnabled: Bool = true
}

// 跟读配置
struct ReadAloudConfig: Codable {
    var isEnabled: Bool = true
    var passStars: Int = 2  // 几颗星算过（1-3）
    var maxAttempts: Int = 3  // 最多读几次，用完不管几星都放行
}

// 练习配置管理器
class PracticeConfigManager: ObservableObject {
    @Published var config: PracticeConfig = PracticeConfig()
    
    private let dbManager = DatabaseManager.shared
    
    init() {
        loadFromRealm()
    }
    
    func saveConfig() {
        do {
            if let realmConfig = try dbManager.object(ofType: RealmPracticeConfig.self, forPrimaryKey: "singleton") {
                try dbManager.update(realmConfig) { realm in
                    realm.englishTranslation?.questionCount = self.config.englishTranslation.questionCount
                    realm.englishTranslation?.vocabularyWeeks = self.config.englishTranslation.vocabularyWeeks
                    realm.englishTranslation?.isEnabled = self.config.englishTranslation.isEnabled
                    realm.englishFillBlank?.questionCount = self.config.englishFillBlank.questionCount
                    realm.englishFillBlank?.vocabularyWeeks = self.config.englishFillBlank.vocabularyWeeks
                    realm.englishFillBlank?.isEnabled = self.config.englishFillBlank.isEnabled
                    realm.additionSubtraction?.questionCount = self.config.additionSubtraction.questionCount
                    realm.additionSubtraction?.maxNumber = self.config.additionSubtraction.maxNumber
                    realm.additionSubtraction?.isEnabled = self.config.additionSubtraction.isEnabled
                    realm.multiplication?.maxNumber = self.config.multiplication.maxNumber
                    realm.multiplication?.questionCount = self.config.multiplication.questionCount
                    realm.multiplication?.isEnabled = self.config.multiplication.isEnabled
                    if realm.animalBattle == nil {
                        // 旧版本数据库里没有这个嵌套对象，写入时补建
                        realm.animalBattle = RealmAnimalBattleConfig()
                    }
                    realm.animalBattle?.questionCount = self.config.animalBattle.questionCount
                    realm.animalBattle?.isEnabled = self.config.animalBattle.isEnabled
                    if realm.readAloud == nil {
                        realm.readAloud = RealmReadAloudConfig()
                    }
                    realm.readAloud?.isEnabled = self.config.readAloud.isEnabled
                    realm.readAloud?.passStars = self.config.readAloud.passStars
                    realm.readAloud?.maxAttempts = self.config.readAloud.maxAttempts
                }
            } else {
                let realmConfig = config.toRealm()
                try dbManager.add(realmConfig)
            }
            print("已保存练习配置到Realm")
        } catch {
            print("保存练习配置失败: \(error)")
        }
    }
    
    func loadConfig() {
        loadFromRealm()
    }
    
    private func loadFromRealm() {
        do {
            if let realmConfig = try dbManager.object(ofType: RealmPracticeConfig.self, forPrimaryKey: "singleton") {
                config = PracticeConfig(from: realmConfig)
                print("从Realm加载了练习配置")
            } else {
                // 如果没有配置，创建默认配置
                let defaultConfig = PracticeConfig()
                try dbManager.add(defaultConfig.toRealm())
                config = defaultConfig
                print("创建了默认练习配置")
            }
        } catch {
            print("从Realm加载练习配置失败: \(error)")
        }
    }
}

