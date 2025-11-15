//
//  DailyPracticeView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct DailyPracticeView: View {
    @StateObject private var clockInManager = ClockInManager()
    @StateObject private var vocabularyManager = VocabularyManager()
    @State private var showingEnglishPractice = false
    @State private var showingMathPractice = false
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    Text("每日一练")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.top, 20)
                    
                    // 统计卡片
                    statsCard
                    
                    // 今日打卡状态
                    todayStatusCard
                    
                    // 练习选项
                    practiceOptionsCard
                    
                    // 历史记录按钮
                    historyButton
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("每日一练")
            .navigationBarTitleDisplayMode(.inline)
        }
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
    
    // 统计卡片
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习统计")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let overallStats = clockInManager.getOverallStats()
            let englishStats = clockInManager.getSubjectStats(for: "英语")
            let mathStats = clockInManager.getSubjectStats(for: "数学")
            
            VStack(spacing: 15) {
                // 总体统计
                HStack(spacing: 20) {
                    VStack {
                        Text("\(overallStats.completedDays)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("完成天数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(clockInManager.stats.currentStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("连续打卡")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(String(format: "%.1f", overallStats.averageScore))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("平均分数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 科目统计
                HStack(spacing: 30) {
                    VStack {
                        Text("\(englishStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("英语")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(mathStats.completedDays)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("数学")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
        VStack(alignment: .leading, spacing: 15) {
            Text("今日状态")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 10) {
                // 英语打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "英语") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语") ? .green : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("英语练习")
                            .font(.headline)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语") ? .green : .gray)
                        
                        if let englishRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "英语") {
                            Text("得分: \(englishRecord.score)/\(englishRecord.totalQuestions) (\(String(format: "%.1f", englishRecord.percentage))%)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未完成")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // 数学打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "数学") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "数学") ? .green : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("数学练习")
                            .font(.headline)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "数学") ? .green : .gray)
                        
                        if let mathRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "数学") {
                            Text("得分: \(mathRecord.score)/\(mathRecord.totalQuestions) (\(String(format: "%.1f", mathRecord.percentage))%)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未完成")
                                .font(.subheadline)
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
                            
                            Text("30个选择题，考察最近1个月的单词和短语")
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
                            
                            Text("20道加减法题目，40以内连续加减2个数")
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
                .disabled(clockInManager.hasCheckedInToday(subject: "数学"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 历史记录按钮
    private var historyButton: some View {
        Button(action: {
            showingHistory = true
        }) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("查看打卡历史")
                    .font(.headline)
                    .foregroundColor(.white)
                
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
    
    // 格式化时间
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
}

#Preview {
    DailyPracticeView()
}
