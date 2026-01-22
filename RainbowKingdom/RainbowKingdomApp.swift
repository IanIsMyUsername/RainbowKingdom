//
//  RainbowKingdomApp.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

@main
struct RainbowKingdomApp: App {
  init() {
    printSandBoxPath()
    initializeDatabase()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
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
