//
//  PracticeConfigModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

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
}

// 英语翻译练习配置
struct EnglishTranslationConfig: Codable {
    var questionCount: Int = 30
    var vocabularyWeeks: Int = 2 // 单词时间范围（周数）
}

// 英语填空练习配置
struct EnglishFillBlankConfig: Codable {
    var questionCount: Int = 10
    var vocabularyWeeks: Int = 2 // 单词时间范围（周数）
}

// 加减法练习配置
struct AdditionSubtractionConfig: Codable {
    var questionCount: Int = 10
    var maxNumber: Int = 40 // 多少以内
}

// 练习配置管理器
class PracticeConfigManager: ObservableObject {
    @Published var config: PracticeConfig = PracticeConfig()
    
    private let userDefaults = UserDefaults.standard
    private let practiceConfigKey = "PracticeConfig"
    
    init() {
        loadConfig()
    }
    
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            userDefaults.set(encoded, forKey: practiceConfigKey)
        }
    }
    
    func loadConfig() {
        if let data = userDefaults.data(forKey: practiceConfigKey),
           let decoded = try? JSONDecoder().decode(PracticeConfig.self, from: data) {
            config = decoded
        }
    }
}

