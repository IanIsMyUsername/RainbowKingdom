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
    @State private var showingEnglishTranslation = false
    @State private var showingEnglishFillBlank = false
    @State private var showingMathPractice = false
    @State private var showingMultiplicationPractice = false
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
    }
    
    // 统计卡片
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习统计")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let overallStats = clockInManager.getOverallStats()
            let englishStats = clockInManager.getSubjectStats(for: "英语翻译")
            let englishFillBlankStats = clockInManager.getSubjectStats(for: "英语填空")
            let mathStats = clockInManager.getSubjectStats(for: "加减法")
            let multiplicationStats = clockInManager.getSubjectStats(for: "乘法")
            
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
                }
                
                // 科目统计
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(englishStats.completedDays)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("英语翻译")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(englishFillBlankStats.completedDays)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("英语填空")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(mathStats.completedDays)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("加减法")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(multiplicationStats.completedDays)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("乘法")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
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
                // 英语翻译打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "英语翻译") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语翻译") ? .green : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("英语翻译")
                            .font(.headline)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语翻译") ? .green : .gray)
                        
                        if let englishTranslationRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "英语翻译") {
                            Text("得分: \(englishTranslationRecord.score)/\(englishTranslationRecord.totalQuestions) (\(String(format: "%.1f", englishTranslationRecord.percentage))%)")
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
                
                // 英语填空打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "英语填空") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语填空") ? .green : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("英语填空")
                            .font(.headline)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "英语填空") ? .green : .gray)
                        
                        if let englishFillBlankRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "英语填空") {
                            // 统一显示10题，即使旧记录是5题
                            let expectedTotal = 10
                            let actualScore = englishFillBlankRecord.score
                            let percentage = expectedTotal > 0 ? Double(actualScore) / Double(expectedTotal) * 100 : 0
                            Text("得分: \(actualScore)/\(expectedTotal) (\(String(format: "%.1f", percentage))%)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未完成 (0/10)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // 加减法打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "加减法") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "加减法") ? .green : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("加减法练习")
                            .font(.headline)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "加减法") ? .green : .gray)
                        
                        if let mathRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "加减法") {
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
                
                // 乘法打卡状态
                HStack {
                    Image(systemName: clockInManager.hasCheckedInToday(subject: "乘法") ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(clockInManager.hasCheckedInToday(subject: "乘法") ? .green : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("乘法练习")
                            .font(.headline)
                            .foregroundColor(clockInManager.hasCheckedInToday(subject: "乘法") ? .green : .gray)
                        
                        if let multiplicationRecord = clockInManager.getClockInRecord(for: Calendar.current.startOfDay(for: Date()), subject: "乘法") {
                            Text("得分: \(multiplicationRecord.score)/\(multiplicationRecord.totalQuestions) (\(String(format: "%.1f", multiplicationRecord.percentage))%)")
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
                            Text("英语翻译练习")
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
                            
                            Text("10道加减法题目，70以内连续加减2个数")
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
                .disabled(clockInManager.hasCheckedInToday(subject: "加减法"))
                
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
