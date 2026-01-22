//
//  RealmVocabulary.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

/// 词汇数据模型（支持单词和短语）
class RealmVocabulary: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var english: String = ""
    @Persisted var chinese: String = ""
    @Persisted var group: String = ""
    @Persisted var type: String = "单词" // VocabularyType的rawValue
    @Persisted var createdDate: Date = Date()
    @Persisted var lastReviewedDate: Date?
    
    var vocabularyType: Vocabulary.VocabularyType {
        get { Vocabulary.VocabularyType(rawValue: type) ?? .word }
        set { type = newValue.rawValue }
    }
}

/// 词汇组模型
class RealmVocabularyGroup: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String = ""
    @Persisted var groupDescription: String = "" // 重命名避免与Object.description冲突
    @Persisted var color: String = "blue"
    
    static let defaultGroups = [
        RealmVocabularyGroup(name: "基础词汇", description: "日常基础单词", color: "blue"),
        RealmVocabularyGroup(name: "常用短语", description: "日常交流短语", color: "green"),
        RealmVocabularyGroup(name: "商务英语", description: "商务场景词汇", color: "purple"),
        RealmVocabularyGroup(name: "学术词汇", description: "学术写作词汇", color: "orange")
    ]
    
    convenience init(name: String, description: String, color: String = "blue") {
        self.init()
        self.name = name
        self.groupDescription = description
        self.color = color
    }
}
