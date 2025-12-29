//
//  MathView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct MathView: View {
    @StateObject private var clockInManager = ClockInManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "function")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 50)
            
            Text("数学学习")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("欢迎来到数学世界！")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                Text("• 数字运算")
                Text("• 几何图形")
                Text("• 逻辑推理")
                Text("• 问题解决")
            }
            .font(.title3)
            .foregroundColor(.primary)
            .padding(.top, 30)
            
            // 练习按钮
            VStack(spacing: 15) {
                NavigationLink(destination: MathQuizView()) {
                    HStack {
                        Image(systemName: "plus.forwardslash.minus")
                            .font(.title2)
                        Text("加减法练习")
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
                
                // 今日打卡状态
                if clockInManager.hasCheckedInToday(subject: "加减法") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("今日已完成加减法练习")
                            .font(.body)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("今日还未完成加减法练习")
                            .font(.body)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.top, 30)
            
            Spacer()
        }
        .padding()
        .navigationTitle("数学")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        MathView()
    }
}
