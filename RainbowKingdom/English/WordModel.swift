//
//  WordModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

// 词汇数据模型（支持单词和短语）
struct Vocabulary: Identifiable, Codable {
    let id: UUID
    var english: String
    var chinese: String
    var group: String
    var type: VocabularyType = .word
    var createdDate: Date
    var lastReviewedDate: Date?
    
    enum VocabularyType: String, CaseIterable, Codable {
        case word = "单词"
        case phrase = "短语"
    }
    
    init(id: UUID = UUID(), english: String, chinese: String, group: String, type: VocabularyType = .word, createdDate: Date = Date(), lastReviewedDate: Date? = nil) {
        self.id = id
        self.english = english
        self.chinese = chinese
        self.group = group
        self.type = type
        self.createdDate = createdDate
        self.lastReviewedDate = lastReviewedDate
    }
}

// 词汇组模型
struct VocabularyGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var color: String = "blue"
    
    init(id: UUID = UUID(), name: String, description: String, color: String = "blue") {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
    }
    
    static let defaultGroups = [
        VocabularyGroup(name: "基础词汇", description: "日常基础单词", color: "blue"),
        VocabularyGroup(name: "常用短语", description: "日常交流短语", color: "green"),
        VocabularyGroup(name: "商务英语", description: "商务场景词汇", color: "purple"),
        VocabularyGroup(name: "学术词汇", description: "学术写作词汇", color: "orange")
    ]
}

// 日期筛选模式
enum DateFilterMode: String, CaseIterable, Codable {
    case all = "全部"
    case today = "今天"
    case yesterday = "昨天"
    case thisWeek = "本周"
    case lastWeek = "上周"
    case thisMonth = "本月"
    case lastMonth = "上月"
    case custom = "自定义"
}

// 词汇管理器
class VocabularyManager: ObservableObject {
    @Published var vocabularies: [Vocabulary] = []
    @Published var groups: [VocabularyGroup] = []
    @Published var selectedGroup: String = ""
    @Published var selectedDate: Date = Date()
    @Published var dateFilterMode: DateFilterMode = .all
    
    private let dbManager = DatabaseManager.shared
    private let userDefaults = UserDefaults.standard
    private let selectedGroupKey = "SelectedGroup"
    
    init() {
        // 初始化默认组（如果Realm中没有）
        initializeDefaultGroups()
        
        // 从Realm加载数据
        loadFromRealm()
        
        // 如果Realm中没有数据，尝试从CSV导入
        if vocabularies.isEmpty {
            importFromCSVIfNeeded()
        }
        
        // 加载用户设置
        loadSelectedGroup()
        loadDateFilterSettings()
    }
    
    // 获取当前选中组的词汇（支持日期筛选）
    var currentGroupVocabularies: [Vocabulary] {
        var filteredVocabularies = vocabularies
        
        // 按组筛选
        if !selectedGroup.isEmpty {
            filteredVocabularies = filteredVocabularies.filter { $0.group == selectedGroup }
        }
        
        // 按日期筛选
        filteredVocabularies = filterVocabulariesByDate(filteredVocabularies)
        
        return filteredVocabularies
    }
    
    // 获取所有组名
    var groupNames: [String] {
        return groups.map { $0.name }
    }
    
    // 添加词汇
    func addVocabulary(_ vocabulary: Vocabulary) {
        do {
            let realmVocab = vocabulary.toRealm()
            try dbManager.add(realmVocab)
            vocabularies.append(vocabulary)
        } catch {
            print("添加词汇失败: \(error)")
        }
    }
    
    // 删除词汇
    func deleteVocabulary(at indexSet: IndexSet) {
        do {
            let vocabulariesToDelete = indexSet.map { vocabularies[$0] }
            for vocabulary in vocabulariesToDelete {
                if let realmVocab = try dbManager.object(ofType: RealmVocabulary.self, forPrimaryKey: vocabulary.id.uuidString) {
                    try dbManager.delete(realmVocab)
                }
            }
            vocabularies.remove(atOffsets: indexSet)
        } catch {
            print("删除词汇失败: \(error)")
        }
    }
    
    // 更新词汇
    func updateVocabulary(_ vocabulary: Vocabulary) {
        do {
            if let realmVocab = try dbManager.object(ofType: RealmVocabulary.self, forPrimaryKey: vocabulary.id.uuidString) {
                try dbManager.update(realmVocab) { vocab in
                    vocab.english = vocabulary.english
                    vocab.chinese = vocabulary.chinese
                    vocab.group = vocabulary.group
                    vocab.vocabularyType = vocabulary.type
                    vocab.createdDate = vocabulary.createdDate
                    vocab.lastReviewedDate = vocabulary.lastReviewedDate
                }
                // 更新本地数组
                if let index = vocabularies.firstIndex(where: { $0.id == vocabulary.id }) {
                    vocabularies[index] = vocabulary
                }
            }
        } catch {
            print("更新词汇失败: \(error)")
        }
    }
    
    // 添加组
    func addGroup(_ group: VocabularyGroup) {
        do {
            let realmGroup = group.toRealm()
            try dbManager.add(realmGroup)
            groups.append(group)
        } catch {
            print("添加组失败: \(error)")
        }
    }
    
    // 更新组
    func updateGroup(_ group: VocabularyGroup) {
        do {
            if let realmGroup = try dbManager.object(ofType: RealmVocabularyGroup.self, forPrimaryKey: group.id.uuidString) {
                try dbManager.update(realmGroup) { g in
                    g.name = group.name
                    g.groupDescription = group.description
                    g.color = group.color
                }
                // 更新本地数组
                if let index = groups.firstIndex(where: { $0.id == group.id }) {
                    groups[index] = group
                }
            }
        } catch {
            print("更新组失败: \(error)")
        }
    }
    
    // 删除组
    func deleteGroup(_ group: VocabularyGroup) {
        do {
            // 删除组
            if let realmGroup = try dbManager.object(ofType: RealmVocabularyGroup.self, forPrimaryKey: group.id.uuidString) {
                try dbManager.delete(realmGroup)
            }
            
            // 删除该组下的所有词汇
            let vocabulariesToDelete = vocabularies.filter { $0.group == group.name }
            for vocabulary in vocabulariesToDelete {
                if let realmVocab = try dbManager.object(ofType: RealmVocabulary.self, forPrimaryKey: vocabulary.id.uuidString) {
                    try dbManager.delete(realmVocab)
                }
            }
            
            groups.removeAll { $0.id == group.id }
            vocabularies.removeAll { $0.group == group.name }
        } catch {
            print("删除组失败: \(error)")
        }
    }
    
    // 选择组
    func selectGroup(_ groupName: String) {
        selectedGroup = groupName
        userDefaults.set(groupName, forKey: selectedGroupKey)
    }
    
    // 设置日期筛选模式
    func setDateFilterMode(_ mode: DateFilterMode) {
        dateFilterMode = mode
        userDefaults.set(mode.rawValue, forKey: "DateFilterMode")
    }
    
    // 设置自定义日期
    func setCustomDate(_ date: Date) {
        selectedDate = date
        userDefaults.set(date, forKey: "SelectedDate")
    }
    
    // 按日期筛选词汇
    private func filterVocabulariesByDate(_ vocabularies: [Vocabulary]) -> [Vocabulary] {
        switch dateFilterMode {
        case .all:
            return vocabularies
        case .today:
            return vocabularies.filter { Calendar.current.isDateInToday($0.createdDate) }
        case .yesterday:
            return vocabularies.filter { Calendar.current.isDateInYesterday($0.createdDate) }
        case .thisWeek:
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: Date(), toGranularity: .weekOfYear) }
        case .lastWeek:
            let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: lastWeek, toGranularity: .weekOfYear) }
        case .thisMonth:
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: Date(), toGranularity: .month) }
        case .lastMonth:
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, equalTo: lastMonth, toGranularity: .month) }
        case .custom:
            return vocabularies.filter { Calendar.current.isDate($0.createdDate, inSameDayAs: selectedDate) }
        }
    }
    
    // MARK: - Realm数据加载
    
    /// 从Realm加载词汇和组
    func loadFromRealm() {
        do {
            // 加载词汇
            let realmVocabularies = try dbManager.objects(RealmVocabulary.self)
            vocabularies = realmVocabularies.map { Vocabulary(from: $0) }
            
            // 加载组
            let realmGroups = try dbManager.objects(RealmVocabularyGroup.self)
            groups = realmGroups.map { VocabularyGroup(from: $0) }
            
            // 如果没有组，使用默认组
            if groups.isEmpty {
                groups = VocabularyGroup.defaultGroups
            }
            
            print("从Realm加载了 \(vocabularies.count) 个词汇，\(groups.count) 个组")
        } catch {
            print("从Realm加载数据失败: \(error)")
        }
    }
    
    /// 初始化默认组
    private func initializeDefaultGroups() {
        do {
            let existingGroups = try dbManager.objects(RealmVocabularyGroup.self)
            if existingGroups.isEmpty {
                // 添加默认组
                let defaultRealmGroups = RealmVocabularyGroup.defaultGroups
                try dbManager.add(defaultRealmGroups)
                print("已初始化默认组")
            }
        } catch {
            print("初始化默认组失败: \(error)")
        }
    }
    
    /// 如果需要，从CSV导入数据
    private func importFromCSVIfNeeded() {
        // 检查是否已经导入过（通过检查Realm中是否有数据）
        do {
            let count = try dbManager.objects(RealmVocabulary.self).count
            if count == 0 {
                // 从CSV导入
                importFromCSV()
            }
        } catch {
            print("检查CSV导入状态失败: \(error)")
        }
    }
    
    /// 从CSV导入词汇到Realm
    func importFromCSV() {
        print("开始从CSV导入词汇...")
        
        // 同步CSV文件到Documents
        syncCSVFromBundleToDocuments()
        
        // 从CSV加载
        let documentsCSVURL = getDocumentsCSVURL()
        if FileManager.default.fileExists(atPath: documentsCSVURL.path) {
            loadCSVFromURL(documentsCSVURL)
            
            // 保存到Realm
            do {
                let realmVocabularies = vocabularies.map { $0.toRealm() }
                try dbManager.add(realmVocabularies)
                print("已从CSV导入 \(vocabularies.count) 个词汇到Realm")
            } catch {
                print("保存到Realm失败: \(error)")
            }
        }
    }
    
    // MARK: - CSV导入导出（用于维护）
    
    // 手动重新加载CSV文件（用于开发调试）
    func reloadFromCSV() {
        print("手动重新加载CSV文件...")
        importFromCSV()
        loadFromRealm()
    }
    
    // 手动同步Bundle中的CSV到Documents（供外部调用）
    func syncFromBundle() {
        print("手动同步Bundle中的CSV文件...")
        syncCSVFromBundleToDocuments()
        importFromCSV()
        loadFromRealm()
    }
    
    // 强制重新同步（清除所有数据，完全从Bundle重新加载）
    func forceResyncFromBundle() {
        print("强制重新同步，清除所有现有数据...")
        
        do {
            // 删除所有词汇
            try dbManager.deleteAll(RealmVocabulary.self)
            
            // 重新导入
            importFromCSV()
            loadFromRealm()
            
            print("强制重新同步完成，当前词汇数量: \(vocabularies.count)")
        } catch {
            print("强制重新同步失败: \(error)")
        }
    }
    
    /// 导出词汇到CSV（用于维护）
    func exportToCSV() {
        let csvURL = getDocumentsCSVURL()
        saveVocabulariesToCSV(vocabularies, to: csvURL)
    }
    
    // 获取Documents目录中的CSV文件路径
    private func getDocumentsCSVURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("vocabularies.csv")
    }
    
    // 每次启动都从Bundle同步CSV到Documents（完全覆盖）
    private func syncCSVFromBundleToDocuments() {
        // 获取Bundle中的CSV文件
        var bundleCSVURL: URL?
        
        if let bundleURL = Bundle.main.url(forResource: "vocabularies", withExtension: "csv", subdirectory: "Resources") {
            bundleCSVURL = bundleURL
        } else if let bundleURL = Bundle.main.url(forResource: "vocabularies", withExtension: "csv") {
            bundleCSVURL = bundleURL
        }
        
        guard let bundleURL = bundleCSVURL else {
            print("Bundle中未找到vocabularies.csv文件")
            return
        }
        
        let documentsCSVURL = getDocumentsCSVURL()
        
        // 直接拷贝Bundle中的CSV文件到Documents，完全覆盖
        do {
            // 如果目标文件已存在，先删除
            if FileManager.default.fileExists(atPath: documentsCSVURL.path) {
                try FileManager.default.removeItem(at: documentsCSVURL)
                print("已删除Documents中的旧CSV文件")
            }
            
            try FileManager.default.copyItem(at: bundleURL, to: documentsCSVURL)
            print("已从Bundle同步CSV文件到Documents: \(documentsCSVURL.path)")
        } catch {
            print("同步CSV文件失败: \(error)")
        }
    }
    
    // 从CSV文件加载词汇（临时存储到内存，不保存到Realm）
    private func loadCSVFromURL(_ csvURL: URL) {
        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines)
            
            var newVocabularies: [Vocabulary] = []
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("英文") { continue } // 跳过空行和标题行
                
                let components = trimmedLine.components(separatedBy: ",")
                if components.count >= 3 {
                    let english = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let chinese = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let group = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let type = components.count > 3 ? Vocabulary.VocabularyType(rawValue: components[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? .word : .word
                    
                    // 解析日期字段（第5列，索引4）
                    var createdDate = Date() // 默认使用当前日期
                    if components.count > 4 {
                        let dateString = components[4].trimmingCharacters(in: .whitespacesAndNewlines)
                        if let parsedDate = parseDate(from: dateString) {
                            createdDate = parsedDate
                        }
                    }
                    
                    if !english.isEmpty && !chinese.isEmpty && !group.isEmpty {
                        let vocabulary = Vocabulary(english: english, chinese: chinese, group: group, type: type, createdDate: createdDate)
                        newVocabularies.append(vocabulary)
                    }
                }
            }
            
            vocabularies = newVocabularies
            print("从CSV加载了 \(vocabularies.count) 个词汇")
            
        } catch {
            print("读取CSV文件失败: \(error)")
        }
    }
    
    // 保存词汇到指定的CSV文件
    private func saveVocabulariesToCSV(_ vocabularies: [Vocabulary], to csvURL: URL) {
        var csvContent = "英文,中文,分类,类型,创建日期\n"
        
        for vocabulary in vocabularies {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: vocabulary.createdDate)
            
            let line = "\(vocabulary.english),\(vocabulary.chinese),\(vocabulary.group),\(vocabulary.type.rawValue),\(dateString)\n"
            csvContent += line
        }
        
        do {
            try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
            print("词汇已保存到CSV文件: \(csvURL.path)")
        } catch {
            print("保存CSV文件失败: \(error)")
        }
    }
    
    // 解析日期字符串
    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        
        // 尝试不同的日期格式
        let formats = [
            "yyyy-MM-dd",      // 2025-01-11
            "yyyy/MM/dd",      // 2025/01/11
            "MM/dd/yyyy",      // 01/11/2025
            "dd/MM/yyyy",      // 11/01/2025
            "yyyy-MM-dd HH:mm:ss", // 2025-01-11 10:30:00
            "yyyy/MM/dd HH:mm:ss"  // 2025/01/11 10:30:00
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        print("无法解析日期: \(dateString)")
        return nil
    }
    
    
    
    // 加载选中的组
    private func loadSelectedGroup() {
        selectedGroup = userDefaults.string(forKey: selectedGroupKey) ?? ""
    }
    
    // 加载日期筛选设置
    private func loadDateFilterSettings() {
        if let modeString = userDefaults.string(forKey: "DateFilterMode"),
           let mode = DateFilterMode(rawValue: modeString) {
            dateFilterMode = mode
        }
        
        if let savedDate = userDefaults.object(forKey: "SelectedDate") as? Date {
            selectedDate = savedDate
        }
    }
    
    // 添加示例词汇
    private func addSampleVocabularies() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        
        let sampleVocabularies = [
            Vocabulary(english: "apple", chinese: "苹果", group: "基础词汇", type: .word, createdDate: now),
            Vocabulary(english: "banana", chinese: "香蕉", group: "基础词汇", type: .word, createdDate: yesterday),
            Vocabulary(english: "good morning", chinese: "早上好", group: "常用短语", type: .phrase, createdDate: now),
            Vocabulary(english: "thank you", chinese: "谢谢你", group: "常用短语", type: .phrase, createdDate: yesterday),
            Vocabulary(english: "meeting", chinese: "会议", group: "商务英语", type: .word, createdDate: lastWeek),
            Vocabulary(english: "deadline", chinese: "截止日期", group: "商务英语", type: .word, createdDate: lastWeek),
            Vocabulary(english: "analysis", chinese: "分析", group: "学术词汇", type: .word, createdDate: now),
            Vocabulary(english: "research", chinese: "研究", group: "学术词汇", type: .word, createdDate: yesterday)
        ]
        
        vocabularies = sampleVocabularies
        // 保存到Realm
        do {
            let realmVocabularies = sampleVocabularies.map { $0.toRealm() }
            try dbManager.add(realmVocabularies)
        } catch {
            print("保存示例词汇失败: \(error)")
        }
    }
}
