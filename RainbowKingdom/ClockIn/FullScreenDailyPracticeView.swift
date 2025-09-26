//
//  FullScreenDailyPracticeView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct FullScreenDailyPracticeView: View {
    @StateObject private var clockInManager = ClockInManager()
    @StateObject private var vocabularyManager = VocabularyManager()
    @State private var showingEnglishPractice = false
    @State private var showingMathPractice = false
    @State private var showingHistory = false
    
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
        .fullScreenCover(isPresented: $showingMathPractice) {
            MathDailyPracticeView()
                .environmentObject(clockInManager)
        }
        .sheet(isPresented: $showingHistory) {
            ClockInHistoryView()
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
        let hasEnglishCheckIn = isPast ? clockInManager.hasCheckedInOnDate(date, subject: "英语") : false
        let hasMathCheckIn = isPast ? clockInManager.hasCheckedInOnDate(date, subject: "数学") : false
        let hasAnyCheckIn = hasEnglishCheckIn || hasMathCheckIn
        
        return VStack(spacing: 2) {
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
    
    
    // 统计卡片
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            Text("学习统计")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let overallStats = clockInManager.getOverallStats()
            let englishStats = clockInManager.getSubjectStats(for: "英语")
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
                    
                    VStack {
                        Text(String(format: "%.1f", overallStats.averageScore))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("平均分数")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 第二行：科目统计
                HStack(spacing: 12) {
                    VStack {
                        Text("\(englishStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("英语")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(mathStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("数学")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                // 英语打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "英语") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语") ? .green : .gray)
                        .font(.caption)
                    
                    VStack(alignment: .leading) {
                        Text("英语")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语") ? .green : .gray)
                        
                        if let englishRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "英语") {
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
                
                // 数学打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "数学") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "数学") ? .green : .gray)
                        .font(.caption)
                    
                    VStack(alignment: .leading) {
                        Text("数学")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "数学") ? .green : .gray)
                        
                        if let mathRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "数学") {
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
                            Text("英语打卡练习")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("15个选择题，考察最近2周的单词和短语")
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
                
                // 数学练习按钮
                Button(action: {
                    showingMathPractice = true
                }) {
                    HStack {
                        Image(systemName: "plus.forwardslash.minus")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("数学打卡练习")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("20道加减法题目，25以内数字运算")
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

#Preview {
    FullScreenDailyPracticeView()
}
