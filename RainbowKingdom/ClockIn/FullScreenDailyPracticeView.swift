//
//  FullScreenDailyPracticeView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

// 让 Date 符合 Identifiable 协议，以便在 sheet 中使用
extension Date: Identifiable {
    public var id: TimeInterval {
        return self.timeIntervalSince1970
    }
}

struct FullScreenDailyPracticeView: View {
    @StateObject private var clockInManager = ClockInManager()
    @StateObject private var vocabularyManager = VocabularyManager()
    @State private var showingEnglishPractice = false
    @State private var showingEnglishFillBlank = false
    @State private var showingMathPractice = false
    @State private var showingMultiplicationPractice = false
    @State private var showingHistory = false
    @State private var selectedDate: Date? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 日历、统计和今日状态（一行显示）
                HStack(alignment: .center, spacing: 15) {
                    calendarView
                    VStack(spacing: 15) {
                        statsCard
                        todayStatusCard
                    }
                    .frame(width: 200)
                }
                
                // 练习选项
                practiceOptionsCard
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("每日一练")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingEnglishPractice) {
            EnglishClockInView()
                .environmentObject(clockInManager)
                .environmentObject(vocabularyManager)
        }
        .fullScreenCover(isPresented: $showingEnglishFillBlank) {
            EnglishFillBlankView()
                .environmentObject(clockInManager)
                .environmentObject(vocabularyManager)
        }
        .fullScreenCover(isPresented: $showingMathPractice) {
            MathDailyPracticeView()
                .environmentObject(clockInManager)
        }
        .fullScreenCover(isPresented: $showingMultiplicationPractice) {
            MultiplicationDailyPracticeView()
                .environmentObject(clockInManager)
        }
        .sheet(isPresented: $showingHistory) {
            ClockInHistoryView()
                .environmentObject(clockInManager)
        }
        .sheet(item: $selectedDate) { date in
            DayDetailView(selectedDate: date)
                .environmentObject(clockInManager)
        }
    }
    
    // 打卡日历视图
    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("打卡日历")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingHistory = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("历史")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, Color(red: 0.0, green: 0.8, blue: 0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // 星期标题
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }
                
                // 日历日期
                ForEach(clockInManager.getCalendarDates(), id: \.self) { date in
                    calendarDayView(date: date)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 单个日历日期视图
    private func calendarDayView(date: Date) -> some View {
        let day = Calendar.current.component(.day, from: date)
        let isToday = Calendar.current.isDateInToday(date)
        let isPast = date < Calendar.current.startOfDay(for: Date())
        let isFuture = date > Calendar.current.startOfDay(for: Date())
        
        // 只有过去的日期才检查打卡情况
        let hasEnglishCheckIn = isPast ? clockInManager.hasCheckedInOnDate(date, subject: "英语翻译") : false
        let hasEnglishFillBlankCheckIn = isPast ? clockInManager.hasCheckedInOnDate(date, subject: "英语填空") : false
        let hasMathCheckIn = isPast ? clockInManager.hasCheckedInOnDate(date, subject: "加减法") : false
        let hasAnyCheckIn = hasEnglishCheckIn || hasEnglishFillBlankCheckIn || hasMathCheckIn
        
        return Button(action: {
            selectedDate = date
        }) {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : (isFuture ? .secondary : .primary))
                
                // 打卡状态指示器（只对过去的日期显示）
                if isPast {
                    HStack(spacing: 2) {
                        if hasEnglishCheckIn {
                            Circle()
                                .fill(.blue)
                                .frame(width: 4, height: 4)
                        }
                        if hasEnglishFillBlankCheckIn {
                            Circle()
                                .fill(.purple)
                                .frame(width: 4, height: 4)
                        }
                        if hasMathCheckIn {
                            Circle()
                                .fill(.green)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else if isFuture {
                    // 未来日期显示灰色圆点
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(
                        isToday ? .purple : 
                        (isPast && hasAnyCheckIn ? .green.opacity(0.2) : 
                         isFuture ? .gray.opacity(0.1) : .clear)
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        isToday ? .purple : 
                        (isPast && hasAnyCheckIn ? .green : .clear), 
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
    // 统计卡片
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            Text("学习统计")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let overallStats = clockInManager.getOverallStats()
            let englishStats = clockInManager.getSubjectStats(for: "英语翻译")
            let englishFillBlankStats = clockInManager.getSubjectStats(for: "英语填空")
            let mathStats = clockInManager.getSubjectStats(for: "数学")
            
            // 内容区域 - 两行
            VStack(spacing: 8) {
                // 第一行：总体统计
                HStack(spacing: 12) {
                    VStack {
                        Text("\(overallStats.completedDays)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("完成天数")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(clockInManager.stats.currentStreak)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("连续打卡")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 第二行：科目统计（三列）
                HStack(spacing: 8) {
                    VStack {
                        Text("\(englishStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("英语翻译")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(englishFillBlankStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text("英语填空")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(mathStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("数学")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 今日打卡状态卡片
    private var todayStatusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日状态")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 6) {
                // 英语翻译打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "英语翻译") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语翻译") ? .green : .gray)
                        .font(.caption)
                    
                    VStack(alignment: .leading) {
                        Text("英语翻译")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语翻译") ? .green : .gray)
                        
                        if let englishRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "英语翻译") {
                            Text("\(englishRecord.score)/\(englishRecord.totalQuestions)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未完成")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // 英语填空打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "英语填空") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语填空") ? .green : .gray)
                        .font(.caption)
                    
                    VStack(alignment: .leading) {
                        Text("英语填空")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语填空") ? .green : .gray)
                        
                        Text(clockInManager.hasCheckedInToday(subject: "英语填空") ? "已完成" : "未完成")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // 加减法打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "加减法") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "加减法") ? .green : .gray)
                        .font(.caption)
                    
                    VStack(alignment: .leading) {
                        Text("加减法练习")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "加减法") ? .green : .gray)
                        
                        if let mathRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "加减法") {
                            Text("\(mathRecord.score)/\(mathRecord.totalQuestions)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未完成")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // 乘法打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "乘法") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "乘法") ? .green : .gray)
                        .font(.caption)
                    
                    VStack(alignment: .leading) {
                        Text("乘法练习")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "乘法") ? .green : .gray)
                        
                        if let multiplicationRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "乘法") {
                            Text("\(multiplicationRecord.score)/\(multiplicationRecord.totalQuestions)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未完成")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 练习选项卡片
    private var practiceOptionsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("练习内容")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // 英语练习按钮
                Button(action: {
                    showingEnglishPractice = true
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("英语翻译练习")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("30个选择题，考察最近2周的单词和短语")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 英语填空练习按钮
                Button(action: {
                    showingEnglishFillBlank = true
                }) {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("英语填空练习")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("10个填空题，根据中文和提示填写完整单词")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 加减法练习按钮
                Button(action: {
                    showingMathPractice = true
                }) {
                    HStack {
                        Image(systemName: "plus.forwardslash.minus")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("加减法练习")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("10道加减法题目，40以内连续加减2个数")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, Color(red: 0.0, green: 0.8, blue: 0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 乘法练习按钮
                Button(action: {
                    showingMultiplicationPractice = true
                }) {
                    HStack {
                        Image(systemName: "multiply.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("乘法练习")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("10道乘法题目，数字范围：1到2")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
}

// 日期详情视图
struct DayDetailView: View {
    let selectedDate: Date
    @EnvironmentObject var clockInManager: ClockInManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedRecord: ClockInRecord?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期标题
                    dateHeader
                    
                    // 打卡记录列表
                    if dayRecords.isEmpty {
                        emptyStateView
                    } else {
                        recordsList
                    }
                }
                .padding()
            }
            .navigationTitle("打卡详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedRecord) { record in
            ClockInDetailView(record: record)
                .environmentObject(clockInManager)
        }
    }
    
    // 日期标题
    private var dateHeader: some View {
        VStack(spacing: 10) {
            Text(formatDate(selectedDate))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(formatWeekday(selectedDate))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("该日期无打卡记录")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("完成练习后，打卡记录将显示在这里")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 记录列表
    private var recordsList: some View {
        VStack(spacing: 15) {
            ForEach(dayRecords) { record in
                RecordDetailCard(record: record) {
                    selectedRecord = record
                }
            }
        }
    }
    
    // 获取选中日期的打卡记录
    private var dayRecords: [ClockInRecord] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: selectedDate)
        
        return clockInManager.clockInRecords.filter { record in
            calendar.isDate(record.date, inSameDayAs: targetDate)
        }.sorted { $0.completedDate < $1.completedDate }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // 格式化星期
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// 记录详情卡片
struct RecordDetailCard: View {
    let record: ClockInRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 15) {
                // 科目和成绩
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.subject)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(record.score)/\(record.totalQuestions) (\(String(format: "%.1f", record.percentage))%)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(record.performance)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(getPerformanceColor(record.percentage))
                        
                        Text(formatTime(record.completedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 添加点击提示
                        HStack(spacing: 4) {
                            Text("点击查看详情")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // 详细信息
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "完成时间", value: formatTime(record.completedDate))
                    InfoRow(title: "用时", value: formatDuration(record.timeSpent))
                    InfoRow(title: "正确率", value: "\(String(format: "%.1f", record.percentage))%")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
    
    private func getPerformanceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 90...100:
            return .green
        case 80..<90:
            return .blue
        case 70..<80:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    FullScreenDailyPracticeView()
}
