//
//  WordDisplayView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct WordDisplayView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部筛选器
            VStack(spacing: 10) {
                // 组选择器
                HStack {
                    Text("选择组:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Picker("选择组", selection: $vocabularyManager.selectedGroup) {
                        Text("全部").tag("")
                        ForEach(vocabularyManager.groupNames, id: \.self) { groupName in
                            Text(groupName).tag(groupName)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.caption)
                }
                .padding(.horizontal)
                
                // 日期筛选器
                HStack {
                    Text("日期筛选:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Picker("日期筛选", selection: $vocabularyManager.dateFilterMode) {
                        ForEach(DateFilterMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.caption)
                    .onChange(of: vocabularyManager.dateFilterMode) { newMode in
                        vocabularyManager.setDateFilterMode(newMode)
                    }
                    
                    if vocabularyManager.dateFilterMode == .custom {
                        DatePicker("", selection: $vocabularyManager.selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .font(.caption)
                            .onChange(of: vocabularyManager.selectedDate) { newDate in
                                vocabularyManager.setCustomDate(newDate)
                            }
                    }
                }
                .padding(.horizontal)
                
                // 进度指示器
                HStack {
                    Text("\(currentIndex + 1) / \(vocabularyManager.currentGroupVocabularies.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if !vocabularyManager.currentGroupVocabularies.isEmpty {
                        Text(vocabularyManager.currentGroupVocabularies[currentIndex].type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(typeColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 10)
            
            if vocabularyManager.currentGroupVocabularies.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("当前组为空")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("请选择其他组或添加词汇")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 词汇卡片
                TabView(selection: $currentIndex) {
                    ForEach(Array(vocabularyManager.currentGroupVocabularies.enumerated()), id: \.element.id) { index, vocabulary in
                        VocabularyCardView(vocabulary: vocabulary)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentIndex)
                .onChange(of: vocabularyManager.selectedGroup) { _ in
                    currentIndex = 0
                }
            }
            
            // 底部导航按钮
            if !vocabularyManager.currentGroupVocabularies.isEmpty {
                HStack(spacing: 30) {
                    Button(action: previousVocabulary) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(currentIndex > 0 ? .blue : .gray)
                    }
                    .disabled(currentIndex <= 0)
                    
                    Button(action: nextVocabulary) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(currentIndex < vocabularyManager.currentGroupVocabularies.count - 1 ? .blue : .gray)
                    }
                    .disabled(currentIndex >= vocabularyManager.currentGroupVocabularies.count - 1)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("单词学习")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var typeColor: Color {
        guard !vocabularyManager.currentGroupVocabularies.isEmpty else { return .gray }
        let type = vocabularyManager.currentGroupVocabularies[currentIndex].type
        switch type {
        case .word:
            return .blue
        case .phrase:
            return .green
        }
    }
    
    private func previousVocabulary() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
            }
        }
    }
    
    private func nextVocabulary() {
        if currentIndex < vocabularyManager.currentGroupVocabularies.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        }
    }
}

struct VocabularyCardView: View {
    let vocabulary: Vocabulary
    @State private var showChinese = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 类型标签
            Text(vocabulary.type.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(typeColor)
                .cornerRadius(12)
            
            // 英文词汇
            Text(vocabulary.english)
                .font(.system(size: vocabulary.type == .phrase ? 36 : 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 中文翻译
            if showChinese {
                Text(vocabulary.chinese)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()
            
            // 显示/隐藏按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showChinese.toggle()
                }
            }) {
                Text(showChinese ? "隐藏中文" : "显示中文")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 150, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private var typeColor: Color {
        switch vocabulary.type {
        case .word:
            return .blue
        case .phrase:
            return .green
        }
    }
}

#Preview {
    NavigationView {
        WordDisplayView(vocabularyManager: VocabularyManager())
    }
}
