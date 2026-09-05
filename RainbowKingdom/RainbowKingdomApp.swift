//
//  RainbowKingdomApp.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

@main
struct RainbowKingdomApp: App {
  /// 安装后首次启动：预热三套本地模型（有进度界面）
  @State private var showWarmUp = ModelWarmUpCoordinator.needsWarmUp

  init() {
    printSandBoxPath()
    initializeDatabase()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .task {
          // 预热本地 TTS：安装打包的 Kokoro 模型并加载（首次启动需编译，约十几秒）
          WordSpeechService.shared.warmUp()
        }
        .fullScreenCover(isPresented: $showWarmUp) {
          ModelWarmUpView()
        }
    }
  }
  
  func printSandBoxPath() {
    if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      print("📂 沙盒 Documents 路径:\n\(url.path)")
    }
  }
  
  /// 初始化数据库
  private func initializeDatabase() {
    // DatabaseManager.shared 会在首次访问时自动初始化
    // 这里只是确保数据库已经准备好
    _ = DatabaseManager.shared
    print("✅ 数据库管理器已初始化")
  }
}
