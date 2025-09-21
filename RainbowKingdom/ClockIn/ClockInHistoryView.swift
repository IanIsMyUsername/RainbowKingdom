//
//  ClockInHistoryView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct ClockInHistoryView: View {
    @EnvironmentObject var clockInManager: ClockInManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingDetail = false
    @State private var selectedRecord: ClockInRecord?
    
    enum TimeRange: String, CaseIterable {
        case week = "最近一周"
        case month = "最近一月"
        case threeMonths = "最近三月"
        case all = "全部"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .all: return 365
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 时间范围选择器
                timeRangePicker
                
                // 统计概览
                statsOverview
                
                // 历史记录列表
                historyList
            }
            .navigationTitle("打卡历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let record = selectedRecord {
                ClockInDetailView(record: record)
            }
        }
    }
    
    // 时间范围选择器
    private var timeRangePicker: some View {
        Picker("时间范围", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    // 统计概览
    private var statsOverview: some View {
        VStack(spacing: 15) {
            Text("学习统计")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(filteredRecords.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("打卡次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(completedRecords.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("完成次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(String(format: "%.1f", averageScore))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("平均分数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // 历史记录列表
    private var historyList: some View {
        Group {
            if groupedRecords.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("暂无打卡记录")
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
            } else {
                List {
                    ForEach(groupedRecords.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date))) {
                            ForEach(groupedRecords[date] ?? []) { record in
                                ClockInRecordRow(record: record) {
                                    selectedRecord = record
                                    showingDetail = true
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // 按时间范围筛选的记录
    private var filteredRecords: [ClockInRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        let allRecords = clockInManager.clockInRecords
        let filtered = allRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date > $1.date }
        
        // 调试信息
        print("总记录数: \(allRecords.count)")
        print("筛选后记录数: \(filtered.count)")
        print("时间范围: \(startDate) 到 \(endDate)")
        
        return filtered
    }
    
    // 已完成的记录
    private var completedRecords: [ClockInRecord] {
        filteredRecords.filter { $0.isCompleted }
    }
    
    // 平均分数
    private var averageScore: Double {
        guard !completedRecords.isEmpty else { return 0 }
        return completedRecords.map { $0.percentage }.reduce(0, +) / Double(completedRecords.count)
    }
    
    // 按日期分组的记录
    private var groupedRecords: [Date: [ClockInRecord]] {
        Dictionary(grouping: filteredRecords) { record in
            Calendar.current.startOfDay(for: record.date)
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// 打卡记录行视图
struct ClockInRecordRow: View {
    let record: ClockInRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.subject)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(record.score)/\(record.totalQuestions) (\(String(format: "%.1f", record.percentage))%)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("用时: \(formatTime(record.timeSpent))")
                        .font(.caption)
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
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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

// 打卡详情视图
struct ClockInDetailView: View {
    let record: ClockInRecord
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    basicInfoCard
                    
                    // 成绩信息
                    scoreCard
                    
                    // 题目详情（如果有的话）
                    if let questions = record.questions, !questions.isEmpty {
                        questionsCard
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
    }
    
    // 基本信息卡片
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("基本信息")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(title: "科目", value: record.subject)
                InfoRow(title: "日期", value: formatDate(record.date))
                InfoRow(title: "完成时间", value: formatTime(record.completedDate))
                InfoRow(title: "用时", value: formatDuration(record.timeSpent))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 成绩卡片
    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("成绩信息")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 15) {
                HStack {
                    VStack {
                        Text("\(record.score)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("得分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(record.totalQuestions)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("总题数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(String(format: "%.1f", record.percentage))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("正确率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(record.performance)
                    .font(.headline)
                    .foregroundColor(getPerformanceColor(record.percentage))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPerformanceColor(record.percentage).opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    // 题目详情卡片
    private var questionsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("题目详情")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ForEach(Array((record.questions ?? []).enumerated()), id: \.offset) { index, question in
                QuestionDetailRow(
                    question: question,
                    userAnswer: index < record.userAnswers.count ? record.userAnswers[index] : "",
                    isCorrect: index < record.userAnswers.count && 
                              record.userAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == 
                              question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
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

// 信息行视图
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// 题目详情行视图
struct QuestionDetailRow: View {
    let question: QuizQuestion
    let userAnswer: String
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(.body)
                .foregroundColor(.primary)
            
            HStack {
                Text("正确答案:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(question.correctAnswer)
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("你的答案:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(userAnswer.isEmpty ? "未作答" : userAnswer)
                    .font(.caption)
                    .foregroundColor(isCorrect ? .green : .red)
                    .fontWeight(.medium)
            }
            
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.caption)
                
                Text(isCorrect ? "正确" : "错误")
                    .font(.caption)
                    .foregroundColor(isCorrect ? .green : .red)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

#Preview {
    ClockInHistoryView()
        .environmentObject(ClockInManager())
}
