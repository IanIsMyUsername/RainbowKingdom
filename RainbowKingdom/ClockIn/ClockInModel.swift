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

// 日历状态模型
struct CalendarState: Codable {
    var startDate: Date
    var endDate: Date
    var lastUpdateDate: Date
    
    init() {
        let calendar = Calendar.current
        let today = Date()
        self.startDate = calendar.date(byAdding: .day, value: -14, to: today) ?? today
        self.endDate = calendar.date(byAdding: .day, value: 6, to: today) ?? today
        self.lastUpdateDate = today
    }
}

// 打卡管理器
class ClockInManager: ObservableObject {
    @Published var clockInRecords: [ClockInRecord] = []
    @Published var stats: DailyPracticeStats = DailyPracticeStats()
    @Published var todayRecord: ClockInRecord?
    @Published var calendarState: CalendarState = CalendarState()
    
    private let userDefaults = UserDefaults.standard
    private let clockInRecordsKey = "ClockInRecords"
    private let statsKey = "DailyPracticeStats"
    private let calendarStateKey = "CalendarState"
    
    init() {
        loadClockInRecords()
        loadStats()
        loadCalendarState()
        updateCalendarStateIfNeeded()
        updateTodayRecord()
        addSeptemberRecords()
    }
    
    // 添加打卡记录（只保留每天每科目的最高分记录）
    func addClockInRecord(_ record: ClockInRecord) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 查找今天同一科目的记录
        if let existingIndex = clockInRecords.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: today) && $0.subject == record.subject
        }) {
            let existingRecord = clockInRecords[existingIndex]
            
            // 比较分数，只保留更高的分数
            if record.score > existingRecord.score {
                clockInRecords[existingIndex] = record
                print("更新 \(record.subject) 打卡记录：\(existingRecord.score) -> \(record.score)")
            } else {
                print("保持 \(record.subject) 打卡记录：\(existingRecord.score) (新分数 \(record.score) 较低)")
                return // 不保存较低分数的记录
            }
        } else {
            // 添加新记录
            clockInRecords.append(record)
            print("添加新的 \(record.subject) 打卡记录：\(record.score)")
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
        var currentDate = calendar.startOfDay(for: Date())
        
        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.date)
            
            // 检查是否是连续的一天
            if calendar.isDate(recordDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                // 如果记录日期比当前检查日期早，说明有间隔，停止计算
                if recordDate < currentDate {
                    break
                }
                // 如果记录日期比当前检查日期晚，跳过这条记录
                continue
            }
        }
        
        return streak
    }
    
    // 计算所有科目的连续打卡天数
    private func calculateOverallCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 获取所有已完成打卡记录的日期（去重，每天只算一次）
        let allDates = Set(clockInRecords
            .filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) })
            .sorted { $0 > $1 }
        
        guard !allDates.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = today
        
        // 如果今天没有打卡记录，从昨天开始计算
        if !allDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        for date in allDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if date < currentDate {
                // 如果记录日期比当前检查日期早，说明有间隔，停止计算
                break
            }
            // 如果记录日期比当前检查日期晚，跳过这条记录（不应该发生，因为已排序）
        }
        
        return streak
    }
    
    // 更新统计信息
    private func updateStats() {
        let allRecords = clockInRecords
        let completedRecords = allRecords.filter { $0.isCompleted }
        
        stats.totalDays = Set(allRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        stats.completedDays = Set(completedRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        stats.currentStreak = calculateOverallCurrentStreak() // 计算所有科目的连续打卡
        stats.longestStreak = calculateLongestStreak()
        stats.averageScore = completedRecords.isEmpty ? 0 : completedRecords.map { $0.percentage }.reduce(0, +) / Double(completedRecords.count)
        stats.lastPracticeDate = completedRecords.max { $0.date < $1.date }?.date
        
        saveStats()
    }
    
    // 计算最长连续打卡天数
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        
        // 获取所有已完成记录的日期（去重，每天只算一次）
        let completedDates = Set(clockInRecords
            .filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) })
            .sorted { $0 < $1 }
        
        guard !completedDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<completedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: completedDates[i - 1], to: completedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        return max(maxStreak, currentStreak)
    }
    
    // 更新今天的记录
    private func updateTodayRecord() {
        let today = Calendar.current.startOfDay(for: Date())
        todayRecord = clockInRecords.first { record in
            Calendar.current.isDate(record.date, inSameDayAs: today) && record.subject == "英语翻译"
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
    
    // 添加2025年9月20号和21号的打卡记录
    func addSeptemberRecords() {
        let calendar = Calendar.current
        
        // 创建9月20号的记录
        if let date20 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 20)) {
            let englishRecord20 = ClockInRecord(
                date: date20,
                subject: "英语翻译",
                score: 10,
                totalQuestions: 10,
                timeSpent: 300, // 5分钟
                completedDate: date20,
                questions: nil,
                userAnswers: []
            )
            
            let mathRecord20 = ClockInRecord(
                date: date20,
                subject: "加减法",
                score: 10,
                totalQuestions: 10,
                timeSpent: 240, // 4分钟
                completedDate: date20,
                questions: nil,
                userAnswers: []
            )
            
            addClockInRecord(englishRecord20)
            addClockInRecord(mathRecord20)
            print("已添加2025年9月20号的打卡记录")
        }
        
        // 创建9月21号的记录
        if let date21 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 21)) {
            let englishRecord21 = ClockInRecord(
                date: date21,
                subject: "英语翻译",
                score: 10,
                totalQuestions: 10,
                timeSpent: 280, // 4分40秒
                completedDate: date21,
                questions: nil,
                userAnswers: []
            )
            
            let mathRecord21 = ClockInRecord(
                date: date21,
                subject: "加减法",
                score: 10,
                totalQuestions: 10,
                timeSpent: 320, // 5分20秒
                completedDate: date21,
                questions: nil,
                userAnswers: []
            )
            
            addClockInRecord(englishRecord21)
            addClockInRecord(mathRecord21)
            print("已添加2025年9月21号的打卡记录")
        }
        
        print("完成添加2025年9月20号和21号的打卡记录（都是100分）")
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
            // 迁移旧的记录
            var migratedRecords = decoded
            var englishMigratedCount = 0
            var mathMigratedCount = 0
            
            for i in 0..<migratedRecords.count {
                let oldRecord = migratedRecords[i]
                var newRecord: ClockInRecord? = nil
                
                // 迁移"英语"记录为"英语翻译"
                if oldRecord.subject == "英语" {
                    newRecord = ClockInRecord(
                        date: oldRecord.date,
                        subject: "英语翻译",
                        score: oldRecord.score,
                        totalQuestions: oldRecord.totalQuestions,
                        timeSpent: oldRecord.timeSpent,
                        completedDate: oldRecord.completedDate,
                        questions: oldRecord.questions,
                        userAnswers: oldRecord.userAnswers
                    )
                    englishMigratedCount += 1
                }
                // 迁移"数学"记录为"加减法"
                else if oldRecord.subject == "数学" {
                    newRecord = ClockInRecord(
                        date: oldRecord.date,
                        subject: "加减法",
                        score: oldRecord.score,
                        totalQuestions: oldRecord.totalQuestions,
                        timeSpent: oldRecord.timeSpent,
                        completedDate: oldRecord.completedDate,
                        questions: oldRecord.questions,
                        userAnswers: oldRecord.userAnswers
                    )
                    mathMigratedCount += 1
                }
                
                if let newRecord = newRecord {
                    migratedRecords[i] = newRecord
                }
            }
            
            clockInRecords = migratedRecords
            
            // 如果有迁移，保存更新后的记录
            if englishMigratedCount > 0 || mathMigratedCount > 0 {
                saveClockInRecords()
                if englishMigratedCount > 0 {
                    print("已迁移 \(englishMigratedCount) 条'英语'记录为'英语翻译'")
                }
                if mathMigratedCount > 0 {
                    print("已迁移 \(mathMigratedCount) 条'数学'记录为'加减法'")
                }
            }
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
    
    // 加载日历状态
    private func loadCalendarState() {
        if let data = userDefaults.data(forKey: calendarStateKey),
           let decoded = try? JSONDecoder().decode(CalendarState.self, from: data) {
            calendarState = decoded
        }
    }
    
    // 保存日历状态
    private func saveCalendarState() {
        if let encoded = try? JSONEncoder().encode(calendarState) {
            userDefaults.set(encoded, forKey: calendarStateKey)
        }
    }
    
    // 检查并更新日历状态（只有当今天超出当前显示范围时才更新）
    private func updateCalendarStateIfNeeded() {
        let calendar = Calendar.current
        let today = Calendar.current.startOfDay(for: Date())
        
        // 检查今天是否超出当前显示范围
        let isTodayBeforeRange = today < calendar.startOfDay(for: calendarState.startDate)
        let isTodayAfterRange = today > calendar.startOfDay(for: calendarState.endDate)
        
        // 只有当今天超出范围时才更新
        if isTodayBeforeRange || isTodayAfterRange {
            let newStartDate = calendar.date(byAdding: .day, value: -14, to: today) ?? today
            let newEndDate = calendar.date(byAdding: .day, value: 6, to: today) ?? today
            
            calendarState.startDate = newStartDate
            calendarState.endDate = newEndDate
            calendarState.lastUpdateDate = today
            
            saveCalendarState()
            print("日历范围已更新：\(newStartDate) 到 \(newEndDate)")
        }
    }
    
    // 获取日历日期（显示完整的一个月）
    func getCalendarDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        
        // 获取当前月份的第一天
        guard let firstDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) else {
            return []
        }
        
        // 获取第一天是星期几（0=周日, 1=周一, ..., 6=周六）
        let weekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 转换为0-6
        
        // 获取当前月份的天数
        guard let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        let daysInMonth = range.count
        
        // 获取上个月的最后几天（如果第一天不是周日）
        var dates: [Date] = []
        
        // 添加上个月的最后几天
        if weekday > 0 {
            let daysToAdd = weekday
            for i in (1...daysToAdd).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    dates.append(date)
                }
            }
        }
        
        // 添加当前月份的所有日期
        for day in 1...daysInMonth {
            if let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)) {
                dates.append(date)
            }
        }
        
        // 计算需要添加的下个月日期，使日历完整（6行，42个日期）
        let totalDays = dates.count
        let daysToAdd = 42 - totalDays // 6行 x 7列 = 42个日期
        
        if daysToAdd > 0 {
            if let lastDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: daysInMonth)) {
                for i in 1...daysToAdd {
                    if let date = calendar.date(byAdding: .day, value: i, to: lastDayOfMonth) {
                        dates.append(date)
                    }
                }
            }
        }
        
        return dates
    }
}
