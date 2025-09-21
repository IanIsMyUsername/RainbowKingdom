//
//  ClockInModel.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation

// 打卡记录模型
struct ClockInRecord: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let subject: String
    let score: Int
    let totalQuestions: Int
    let timeSpent: TimeInterval
    let completedDate: Date
    let questions: [QuizQuestion]? // 改为可选，支持数学练习
    let userAnswers: [String]
    
    var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
    }
    
    var performance: String {
        switch percentage {
        case 90...100:
            return "优秀！"
        case 80..<90:
            return "良好！"
        case 70..<80:
            return "及格"
        default:
            return "需要努力"
        }
    }
    
    var isCompleted: Bool {
        return score > 0
    }
}

// 每日一练统计模型
struct DailyPracticeStats: Codable {
    var totalDays: Int = 0
    var completedDays: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageScore: Double = 0.0
    var lastPracticeDate: Date?
    
    var completionRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays) * 100
    }
}

// 打卡管理器
class ClockInManager: ObservableObject {
    @Published var clockInRecords: [ClockInRecord] = []
    @Published var stats: DailyPracticeStats = DailyPracticeStats()
    @Published var todayRecord: ClockInRecord?
    
    private let userDefaults = UserDefaults.standard
    private let clockInRecordsKey = "ClockInRecords"
    private let statsKey = "DailyPracticeStats"
    
    init() {
        loadClockInRecords()
        loadStats()
        updateTodayRecord()
    }
    
    // 添加打卡记录
    func addClockInRecord(_ record: ClockInRecord) {
        // 检查今天是否已经有记录
        let today = Calendar.current.startOfDay(for: Date())
        if let existingIndex = clockInRecords.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: today) && $0.subject == record.subject
        }) {
            // 更新今天的记录
            clockInRecords[existingIndex] = record
        } else {
            // 添加新记录
            clockInRecords.append(record)
        }
        
        saveClockInRecords()
        updateStats()
        updateTodayRecord()
    }
    
    // 获取指定日期的打卡记录
    func getClockInRecord(for date: Date, subject: String) -> ClockInRecord? {
        return clockInRecords.first { record in
            Calendar.current.isDate(record.date, inSameDayAs: date) && record.subject == subject
        }
    }
    
    // 获取最近一个月的打卡记录
    func getRecentRecords(days: Int = 30) -> [ClockInRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return clockInRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date > $1.date }
    }
    
    // 检查今天是否已打卡
    func hasCheckedInToday(subject: String) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return hasCheckedInOnDate(today, subject: subject)
    }
    
    // 检查指定日期是否已经打卡
    func hasCheckedInOnDate(_ date: Date, subject: String) -> Bool {
        let targetDate = Calendar.current.startOfDay(for: date)
        return clockInRecords.contains { record in
            Calendar.current.isDate(record.date, inSameDayAs: targetDate) && 
            record.subject == subject
        }
    }
    
    // 获取连续打卡天数
    func getCurrentStreak(subject: String) -> Int {
        let sortedRecords = clockInRecords
            .filter { $0.subject == subject }
            .sorted { $0.date > $1.date }
        
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for record in sortedRecords {
            if calendar.isDate(record.date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // 更新统计信息
    private func updateStats() {
        let allRecords = clockInRecords
        let completedRecords = allRecords.filter { $0.isCompleted }
        
        stats.totalDays = Set(allRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        stats.completedDays = Set(completedRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        stats.currentStreak = getCurrentStreak(subject: "英语") // 保持英语作为主要统计科目
        stats.longestStreak = calculateLongestStreak()
        stats.averageScore = completedRecords.isEmpty ? 0 : completedRecords.map { $0.percentage }.reduce(0, +) / Double(completedRecords.count)
        stats.lastPracticeDate = completedRecords.max { $0.date < $1.date }?.date
        
        saveStats()
    }
    
    // 计算最长连续打卡天数
    private func calculateLongestStreak() -> Int {
        let sortedRecords = clockInRecords
            .filter { $0.isCompleted }
            .sorted { $0.date < $1.date }
        
        var maxStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        var lastDate: Date?
        
        for record in sortedRecords {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: record.date).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastDate = record.date
        }
        
        return max(maxStreak, currentStreak)
    }
    
    // 更新今天的记录
    private func updateTodayRecord() {
        let today = Calendar.current.startOfDay(for: Date())
        todayRecord = clockInRecords.first { record in
            Calendar.current.isDate(record.date, inSameDayAs: today) && record.subject == "英语"
        }
    }
    
    // 获取特定科目的统计信息
    func getSubjectStats(for subject: String) -> (totalDays: Int, completedDays: Int, currentStreak: Int, averageScore: Double) {
        let subjectRecords = clockInRecords.filter { $0.subject == subject }
        let completedRecords = subjectRecords.filter { $0.isCompleted }
        
        let totalDays = Set(subjectRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        let completedDays = Set(completedRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        let currentStreak = getCurrentStreak(subject: subject)
        let averageScore = completedRecords.isEmpty ? 0 : completedRecords.map { $0.percentage }.reduce(0, +) / Double(completedRecords.count)
        
        return (totalDays, completedDays, currentStreak, averageScore)
    }
    
    // 获取所有科目的总体统计
    func getOverallStats() -> (totalDays: Int, completedDays: Int, averageScore: Double) {
        let allRecords = clockInRecords
        let completedRecords = allRecords.filter { $0.isCompleted }
        
        let totalDays = Set(allRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        let completedDays = Set(completedRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        let averageScore = completedRecords.isEmpty ? 0 : completedRecords.map { $0.percentage }.reduce(0, +) / Double(completedRecords.count)
        
        return (totalDays, completedDays, averageScore)
    }
    
    // 保存打卡记录
    private func saveClockInRecords() {
        if let encoded = try? JSONEncoder().encode(clockInRecords) {
            userDefaults.set(encoded, forKey: clockInRecordsKey)
        }
    }
    
    // 加载打卡记录
    private func loadClockInRecords() {
        if let data = userDefaults.data(forKey: clockInRecordsKey),
           let decoded = try? JSONDecoder().decode([ClockInRecord].self, from: data) {
            clockInRecords = decoded
        }
    }
    
    // 保存统计信息
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: statsKey)
        }
    }
    
    // 加载统计信息
    private func loadStats() {
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(DailyPracticeStats.self, from: data) {
            stats = decoded
        }
    }
}
