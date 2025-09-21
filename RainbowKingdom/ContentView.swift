//
//  ContentView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct ContentView: View {
    @State private var showingDailyPractice = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("彩虹王国")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.top, 50)
                
                Text("选择学习科目")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
                
                VStack(spacing: 20) {
                    Button(action: {
                        showingDailyPractice = true
                    }) {
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
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingDailyPractice) {
            FullScreenDailyPracticeView()
        }
    }
}


#Preview {
    ContentView()
}
