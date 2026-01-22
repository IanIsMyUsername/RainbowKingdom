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
}
