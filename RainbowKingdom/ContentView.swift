//
//  ContentView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct ContentView: View {
    @State private var isDailyPracticeActive = true
    @State private var tapCount = 0
    @State private var lastTapTime: Date?
    @State private var showDatabaseManagement = false
    
    // 连续点击的时间间隔阈值（秒），超过此时间会重置计数
    private let tapIntervalThreshold: TimeInterval = 1.0
    // 需要连续点击的次数
    private let requiredTapCount = 6
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("彩虹王国")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.top, 50)
                    .onTapGesture {
                        handleTitleTap()
                    }
                
                Text("选择学习科目")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
                
                VStack(spacing: 20) {
                    NavigationLink(destination: FullScreenDailyPracticeView(), isActive: $isDailyPracticeActive) {
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.title2)
                            Text("每日一练")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
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
                    
                    NavigationLink(destination: EnglishView()) {
                        HStack {
                            Image(systemName: "book")
                                .font(.title2)
                            Text("英语")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
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
                    
                    NavigationLink(destination: MathView()) {
                        HStack {
                            Image(systemName: "function")
                                .font(.title2)
                            Text("数学")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
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
                    
                    // 隐藏的导航链接，用于程序化导航
                    NavigationLink(destination: DatabaseManagementView(), isActive: $showDatabaseManagement) {
                        EmptyView()
                    }
                    .hidden()
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    /// 处理标题点击事件
    private func handleTitleTap() {
        let now = Date()
        
        // 检查是否在时间间隔内（连续点击）
        if let lastTap = lastTapTime {
            let timeInterval = now.timeIntervalSince(lastTap)
            if timeInterval > tapIntervalThreshold {
                // 超过时间间隔，重置计数
                tapCount = 1
            } else {
                // 在时间间隔内，增加计数
                tapCount += 1
            }
        } else {
            // 第一次点击
            tapCount = 1
        }
        
        lastTapTime = now
        
        // 检查是否达到要求的点击次数
        if tapCount >= requiredTapCount {
            // 直接打开数据库管理界面
            showDatabaseManagement = true
            
            // 重置计数，避免重复触发
            tapCount = 0
            lastTapTime = nil
            
            // 添加触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}


#Preview {
    ContentView()
}
