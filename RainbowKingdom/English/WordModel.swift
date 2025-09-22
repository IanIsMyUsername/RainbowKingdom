//
//  WordModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// 词汇数据模型（支持单词和短语）
struct Vocabulary: Identifiable, Codable {
    let id = UUID()
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
    
    init(english: String, chinese: String, group: String, type: VocabularyType = .word, createdDate: Date = Date(), lastReviewedDate: Date? = nil) {
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
    let id = UUID()
    var name: String
    var description: String
    var color: String = "blue"
    
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
    
    private let userDefaults = UserDefaults.standard
    private let vocabulariesKey = "SavedVocabularies"
    private let groupsKey = "SavedGroups"
    private let selectedGroupKey = "SelectedGroup"
    
    init() {
        // 每次启动都从Bundle同步CSV到Documents
        syncCSVFromBundleToDocuments()
        
        // 从Documents的CSV文件加载词汇
        loadFromDocumentsCSV()
        
        // 设置默认组（不从UserDefaults加载）
        groups = VocabularyGroup.defaultGroups
        
        // 加载用户设置
        loadSelectedGroup()
        loadDateFilterSettings()
        
//        // 如果仍然为空，添加示例词汇
//        if vocabularies.isEmpty {
//            addSampleVocabularies()
//        }
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
        vocabularies.append(vocabulary)
        saveVocabularies()
    }
    
    // 删除词汇
    func deleteVocabulary(at indexSet: IndexSet) {
        vocabularies.remove(atOffsets: indexSet)
        saveVocabularies()
    }
    
    // 更新词汇
    func updateVocabulary(_ vocabulary: Vocabulary) {
        if let index = vocabularies.firstIndex(where: { $0.id == vocabulary.id }) {
            vocabularies[index] = vocabulary
            saveVocabularies()
        }
    }
    
    // 添加组
    func addGroup(_ group: VocabularyGroup) {
        groups.append(group)
        saveGroups()
    }
    
    // 更新组
    func updateGroup(_ group: VocabularyGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        }
    }
    
    // 删除组
    func deleteGroup(_ group: VocabularyGroup) {
        groups.removeAll { $0.id == group.id }
        // 删除该组下的所有词汇
        vocabularies.removeAll { $0.group == group.name }
        saveGroups()
        saveVocabularies()
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
    
    // 手动重新加载CSV文件（用于开发调试）
    func reloadFromCSV() {
        print("手动重新加载CSV文件...")
        loadFromDocumentsCSV()
    }
    
    // 手动同步Bundle中的CSV到Documents（供外部调用）
    func syncFromBundle() {
        print("手动同步Bundle中的CSV文件...")
        syncCSVFromBundleToDocuments()
        // 同步后重新加载数据
        loadFromDocumentsCSV()
    }
    
    // 强制重新同步（清除所有数据，完全从Bundle重新加载）
    func forceResyncFromBundle() {
        print("强制重新同步，清除所有现有数据...")
        
        // 清空当前词汇
        vocabularies = []
        
        // 重新同步
        syncCSVFromBundleToDocuments()
        
        // 重新加载
        loadFromDocumentsCSV()
        
        print("强制重新同步完成，当前词汇数量: \(vocabularies.count)")
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
    
    // 从Documents的CSV文件加载词汇
    private func loadFromDocumentsCSV() {
        let documentsCSVURL = getDocumentsCSVURL()
        
        if FileManager.default.fileExists(atPath: documentsCSVURL.path) {
            print("从Documents/vocabularies.csv加载文件")
            loadCSVFromURL(documentsCSVURL)
        } else {
            print("Documents中不存在vocabularies.csv文件")
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
    
    // 从CSV文件加载词汇
    func loadFromCSV() {
        // 首先尝试从Resources文件夹读取
        if let csvURL = Bundle.main.url(forResource: "vocabularies", withExtension: "csv", subdirectory: "Resources") {
            print("从Resources/vocabularies.csv加载文件")
            loadCSVFromURL(csvURL)
            return
        }
        
        // 如果Resources文件夹中没有，尝试从根目录读取
        if let csvURL = Bundle.main.url(forResource: "vocabularies", withExtension: "csv") {
            print("从根目录vocabularies.csv加载文件")
            loadCSVFromURL(csvURL)
            return
        }
        
        print("CSV文件未找到，请确保vocabularies.csv已添加到Xcode项目中")
    }
    
    // 从指定URL加载CSV文件
    private func loadCSVFromURL(_ csvURL: URL) {
        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines)
            
            var newVocabularies: [Vocabulary] = []
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty { continue }
                
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
    
    // 保存词汇到Documents的CSV文件
    private func saveVocabularies() {
        let csvURL = getDocumentsCSVURL()
        saveVocabulariesToCSV(vocabularies, to: csvURL)
    }
    
    // 从UserDefaults加载词汇（已弃用，现在主要使用CSV文件）
    private func loadVocabularies() {
        // 不再从UserDefaults加载，所有数据都从CSV文件读取
        // 保留此方法以避免破坏现有调用
    }
    
    // 保存组到UserDefaults
    private func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            userDefaults.set(encoded, forKey: groupsKey)
        }
    }
    
    // 从UserDefaults加载组
    private func loadGroups() {
        if let data = userDefaults.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([VocabularyGroup].self, from: data) {
            groups = decoded
        }
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
        saveVocabularies()
    }
}
