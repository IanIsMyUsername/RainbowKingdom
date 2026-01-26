//
//  DatabaseManagementView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI
import RealmSwift

struct DatabaseManagementView: View {
    @StateObject private var vocabularyManager = VocabularyManager()
    @StateObject private var clockInManager = ClockInManager()
    @StateObject private var mathQuizManager = MathQuizManager()
    @StateObject private var quizManager = QuizManager()
    @StateObject private var multiplicationQuizManager = MultiplicationQuizManager()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedSubject: String = "全部"
    @State private var dateFilter: DateFilter = .all
    @State private var showingStats = false
    @State private var showingCSVImporter = false
    @State private var showingJSONImporter = false
    @State private var showingImportAlert = false
    @State private var importMessage = ""
    
    enum DateFilter: String, CaseIterable {
        case all = "全部"
        case today = "今天"
        case thisWeek = "本周"
        case thisMonth = "本月"
        case custom = "自定义"
    }
    
    let subjects = ["全部", "英语翻译", "英语填空", "加减法", "乘法"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签页选择
            Picker("数据类型", selection: $selectedTab) {
                Text("词汇").tag(0)
                Text("打卡记录").tag(1)
                Text("练习结果").tag(2)
                Text("统计").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // 内容区域
            TabView(selection: $selectedTab) {
                vocabularyView
                    .tag(0)
                
                clockInRecordsView
                    .tag(1)
                
                quizResultsView
                    .tag(2)
                
                statsView
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("数据库管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("导出CSV") {
                        exportToCSV()
                    }
                    Button("导出JSON") {
                        exportToJSON()
                    }
                    Button("导入CSV") {
                        showingCSVImporter = true
                    }
                    Button("导入JSON") {
                        showingJSONImporter = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .alert("导出结果", isPresented: $showingExportAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(exportMessage)
        }
        .alert("导入结果", isPresented: $showingImportAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
        .fileImporter(
            isPresented: $showingCSVImporter,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result: result)
        }
        .fileImporter(
            isPresented: $showingJSONImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleJSONImport(result: result)
        }
    }
    
    // MARK: - 词汇视图
    
    var vocabularyView: some View {
        VStack {
            // 搜索栏
            SearchBar(text: $searchText)
                .padding()
            
            // 词汇列表
            List {
                ForEach(filteredVocabularies) { vocabulary in
                    DatabaseVocabularyRowView(vocabulary: vocabulary)
                }
                .onDelete(perform: deleteVocabulary)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    var filteredVocabularies: [Vocabulary] {
        if searchText.isEmpty {
            return vocabularyManager.vocabularies
        }
        return vocabularyManager.vocabularies.filter {
            $0.english.localizedCaseInsensitiveContains(searchText) ||
            $0.chinese.localizedCaseInsensitiveContains(searchText) ||
            $0.group.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func deleteVocabulary(at offsets: IndexSet) {
        vocabularyManager.deleteVocabulary(at: offsets)
    }
    
    // MARK: - 打卡记录视图
    
    var clockInRecordsView: some View {
        VStack {
            // 筛选栏
            HStack {
                Picker("科目", selection: $selectedSubject) {
                    ForEach(subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("日期", selection: $dateFilter) {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()
            
            // 打卡记录列表
            List {
                ForEach(filteredClockInRecords) { record in
                    ClockInRecordRowView(record: record)
                }
                .onDelete(perform: deleteClockInRecord)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    var filteredClockInRecords: [ClockInRecord] {
        var records = clockInManager.clockInRecords
        
        // 按科目筛选
        if selectedSubject != "全部" {
            records = records.filter { $0.subject == selectedSubject }
        }
        
        // 按日期筛选
        switch dateFilter {
        case .all:
            break
        case .today:
            records = records.filter { Calendar.current.isDateInToday($0.date) }
        case .thisWeek:
            records = records.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            records = records.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .custom:
            break // TODO: 实现自定义日期筛选
        }
        
        return records.sorted { $0.date > $1.date }
    }
    
    func deleteClockInRecord(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { filteredClockInRecords[$0] }
        let dbManager = DatabaseManager.shared
        
        do {
            for record in recordsToDelete {
                if let realmRecord = try dbManager.object(ofType: RealmClockInRecord.self, forPrimaryKey: record.id.uuidString) {
                    try dbManager.delete(realmRecord)
                }
            }
            // 重新加载数据
            clockInManager.loadFromRealm()
        } catch {
            print("删除打卡记录失败: \(error)")
        }
    }
    
    // MARK: - 练习结果视图
    
    var quizResultsView: some View {
        VStack {
            Text("练习结果")
                .font(.headline)
                .padding()
            
            List {
                Section("数学练习") {
                    ForEach(mathQuizResults) { result in
                        MathQuizResultRowView(result: result)
                    }
                }
                
                Section("英语测验") {
                    ForEach(englishQuizResults) { result in
                        QuizResultRowView(result: result)
                    }
                }
                
                Section("乘法练习") {
                    ForEach(multiplicationQuizResults) { result in
                        MultiplicationQuizResultRowView(result: result)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    var mathQuizResults: [MathQuizResult] {
        return mathQuizManager.quizResults.sorted { $0.completedDate > $1.completedDate }
    }
    
    var englishQuizResults: [QuizResult] {
        return quizManager.quizResults.sorted { $0.completedDate > $1.completedDate }
    }
    
    var multiplicationQuizResults: [MultiplicationQuizResult] {
        return multiplicationQuizManager.quizResults.sorted { $0.completedDate > $1.completedDate }
    }
    
    // MARK: - 统计视图
    
    var statsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 总体统计
                StatsCardView(title: "总体统计", stats: overallStats)
                
                // 按科目统计
                ForEach(subjects.filter { $0 != "全部" }, id: \.self) { subject in
                    SubjectStatsCardView(subject: subject, stats: getSubjectStats(subject))
                }
            }
            .padding()
        }
    }
    
    var overallStats: (total: Int, average: Double, completion: Double) {
        let records = clockInManager.clockInRecords
        let total = records.count
        let average = records.isEmpty ? 0 : records.map { $0.percentage }.reduce(0, +) / Double(records.count)
        let completion = clockInManager.stats.completionRate
        return (total, average, completion)
    }
    
    func getSubjectStats(_ subject: String) -> (total: Int, average: Double, streak: Int) {
        let stats = clockInManager.getSubjectStats(for: subject)
        return (stats.totalDays, stats.averageScore, stats.currentStreak)
    }
    
    // MARK: - 导出功能
    
    @State private var showingExportAlert = false
    @State private var exportMessage = ""
    
    func exportToCSV() {
        let importExport = DataImportExport.shared
        
        // 开始新的导出会话（确保所有文件保存到同一个文件夹）
        importExport.startNewExportSession()
        
        // 导出所有数据
        var exportedFiles: [String] = []
        var folderName: String?
        
        if let vocabURL = importExport.exportVocabulariesToCSV() {
            exportedFiles.append("词汇: \(vocabURL.lastPathComponent)")
            if folderName == nil {
                folderName = vocabURL.deletingLastPathComponent().lastPathComponent
            }
        }
        
        if let recordsURL = importExport.exportClockInRecordsToCSV() {
            exportedFiles.append("打卡记录: \(recordsURL.lastPathComponent)")
            if folderName == nil {
                folderName = recordsURL.deletingLastPathComponent().lastPathComponent
            }
        }
        
        if let mathURL = importExport.exportMathQuizResultsToCSV() {
            exportedFiles.append("数学练习: \(mathURL.lastPathComponent)")
            if folderName == nil {
                folderName = mathURL.deletingLastPathComponent().lastPathComponent
            }
        }
        
        if let englishURL = importExport.exportEnglishQuizResultsToCSV() {
            exportedFiles.append("英语测验: \(englishURL.lastPathComponent)")
            if folderName == nil {
                folderName = englishURL.deletingLastPathComponent().lastPathComponent
            }
        }
        
        if let multiplicationURL = importExport.exportMultiplicationQuizResultsToCSV() {
            exportedFiles.append("乘法练习: \(multiplicationURL.lastPathComponent)")
            if folderName == nil {
                folderName = multiplicationURL.deletingLastPathComponent().lastPathComponent
            }
        }
        
        if exportedFiles.isEmpty {
            exportMessage = "导出失败，请重试"
        } else {
            exportMessage = "已导出以下文件到文件夹：\n\(folderName ?? "未知")\n\n" + exportedFiles.joined(separator: "\n")
        }
        
        showingExportAlert = true
    }
    
    func exportToJSON() {
        let importExport = DataImportExport.shared
        
        // 开始新的导出会话
        importExport.startNewExportSession()
        
        if let jsonURL = importExport.exportAllDataToJSON() {
            let folderName = jsonURL.deletingLastPathComponent().lastPathComponent
            exportMessage = "已导出所有数据到JSON文件：\n\(jsonURL.lastPathComponent)\n\n文件位置：\(folderName) 文件夹"
        } else {
            exportMessage = "导出失败，请重试"
        }
        
        showingExportAlert = true
    }
    
    // MARK: - 导入功能
    
    func handleCSVImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importMessage = "未选择文件"
                showingImportAlert = true
                return
            }
            
            // 获取文件访问权限
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            let importExport = DataImportExport.shared
            let (success, failed) = importExport.importVocabulariesFromCSV(url: url)
            
            // 重新加载词汇数据
            vocabularyManager.loadFromRealm()
            
            importMessage = "导入完成！\n成功: \(success) 条\n失败: \(failed) 条"
            showingImportAlert = true
            
        case .failure(let error):
            importMessage = "导入失败: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }
    
    func handleJSONImport(result: Result<[URL], Error>) {
        // TODO: 实现JSON导入功能
        switch result {
        case .success(let urls):
            importMessage = "JSON导入功能待实现"
            showingImportAlert = true
        case .failure(let error):
            importMessage = "导入失败: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }
}

// MARK: - 辅助视图组件

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onDisappear {
            // 当视图消失时，清除TextField的焦点，避免警告
            isFocused = false
        }
    }
}

struct DatabaseVocabularyRowView: View {
    let vocabulary: Vocabulary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vocabulary.english)
                    .font(.headline)
                Text(vocabulary.chinese)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(vocabulary.group)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Text(vocabulary.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClockInRecordRowView: View {
    let record: ClockInRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.subject)
                    .font(.headline)
                
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.score)/\(record.totalQuestions)")
                    .font(.headline)
                    .foregroundColor(record.percentage >= 90 ? .green : record.percentage >= 70 ? .orange : .red)
                
                Text(String(format: "%.0f%%", record.percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MathQuizResultRowView: View {
    let result: MathQuizResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("数学练习 - \(result.operationType.rawValue)")
                    .font(.headline)
                Text(result.completedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(result.score)/\(result.totalQuestions)")
                .font(.headline)
        }
    }
}

struct QuizResultRowView: View {
    let result: QuizResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("英语测验")
                    .font(.headline)
                Text(result.completedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(result.score)/\(result.totalQuestions)")
                .font(.headline)
        }
    }
}

struct MultiplicationQuizResultRowView: View {
    let result: MultiplicationQuizResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("乘法练习")
                    .font(.headline)
                Text(result.completedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(result.score)/\(result.totalQuestions)")
                .font(.headline)
        }
    }
}

struct StatsCardView: View {
    let title: String
    let stats: (total: Int, average: Double, completion: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            HStack {
                StatItemView(label: "总记录", value: "\(stats.total)")
                StatItemView(label: "平均分", value: String(format: "%.1f", stats.average))
                StatItemView(label: "完成率", value: String(format: "%.1f%%", stats.completion))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SubjectStatsCardView: View {
    let subject: String
    let stats: (total: Int, average: Double, streak: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subject)
                .font(.headline)
            
            HStack {
                StatItemView(label: "总天数", value: "\(stats.total)")
                StatItemView(label: "平均分", value: String(format: "%.1f", stats.average))
                StatItemView(label: "连续", value: "\(stats.streak)天")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
