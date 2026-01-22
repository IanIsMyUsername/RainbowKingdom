//
//  VocabularyExtensions.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// MARK: - Vocabulary转换扩展

extension Vocabulary {
    /// 从RealmVocabulary创建Vocabulary
    init(from realmVocabulary: RealmVocabulary) {
        let uuid = UUID(uuidString: realmVocabulary.id) ?? UUID()
        self.id = uuid
        self.english = realmVocabulary.english
        self.chinese = realmVocabulary.chinese
        self.group = realmVocabulary.group
        self.type = realmVocabulary.vocabularyType
        self.createdDate = realmVocabulary.createdDate
        self.lastReviewedDate = realmVocabulary.lastReviewedDate
    }
    
    /// 转换为RealmVocabulary
    func toRealm() -> RealmVocabulary {
        let realmVocab = RealmVocabulary()
        realmVocab.id = id.uuidString
        realmVocab.english = english
        realmVocab.chinese = chinese
        realmVocab.group = group
        realmVocab.vocabularyType = type
        realmVocab.createdDate = createdDate
        realmVocab.lastReviewedDate = lastReviewedDate
        return realmVocab
    }
}

extension VocabularyGroup {
    /// 从RealmVocabularyGroup创建VocabularyGroup
    init(from realmGroup: RealmVocabularyGroup) {
        self.init(
            id: UUID(uuidString: realmGroup.id) ?? UUID(),
            name: realmGroup.name,
            description: realmGroup.groupDescription,
            color: realmGroup.color
        )
    }
    
    /// 转换为RealmVocabularyGroup
    func toRealm() -> RealmVocabularyGroup {
        let realmGroup = RealmVocabularyGroup()
        realmGroup.id = id.uuidString
        realmGroup.name = name
        realmGroup.groupDescription = description
        realmGroup.color = color
        return realmGroup
    }
}
