//
//  EnglishView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct EnglishView: View {
    @StateObject private var vocabularyManager = VocabularyManager()
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "book")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.top, 30)
            
            Text("英语学习")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("Welcome to English World!")
                .font(.title2)
                .foregroundColor(.gray)
            
            // 功能按钮
            VStack(spacing: 20) {
                NavigationLink(destination: WordDisplayView(vocabularyManager: vocabularyManager)) {
                    HStack {
                        Image(systemName: "book.pages")
                            .font(.title2)
                        Text("单词学习")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                NavigationLink(destination: WordCompletionView(vocabularyManager: vocabularyManager)) {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .font(.title2)
                        Text("单词补全")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                NavigationLink(destination: QuizView(vocabularyManager: vocabularyManager)) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                        Text("英语测验")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                NavigationLink(destination: WordManagementView(vocabularyManager: vocabularyManager)) {
                    HStack {
                        Image(systemName: "gearshape")
                            .font(.title2)
                        Text("词库管理")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, Color(red: 0.0, green: 0.8, blue: 0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
            .padding(.top, 20)
            
            // 词汇统计信息
            HStack(spacing: 20) {
                VStack {
                    Text("\(vocabularyManager.vocabularies.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("总词汇数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(vocabularyManager.vocabularies.filter { $0.type == .word }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("单词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(vocabularyManager.vocabularies.filter { $0.type == .phrase }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("短语")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(vocabularyManager.groups.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("分组")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemGray6))
            )
            
            Spacer()
        }
        .padding()
        .navigationTitle("英语")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        EnglishView()
    }
}
