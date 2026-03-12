# 彩虹王国 (Rainbow Kingdom)

一个专为儿童设计的 iOS 学习应用，提供英语和数学的互动练习功能。

## 功能特性

### 每日一练
- 每日打卡系统，培养学习习惯
- 打卡历史记录查看
- 英语填空练习
- 数学计算练习

### 英语学习
- **单词管理**：添加、编辑和管理单词库
- **单词测试**：通过测验巩固单词记忆
- **填空练习**：完形填空题型训练
- **单词展示**：浏览和学习单词

### 数学练习
- **数学测试**：各类数学题目练习
- **乘法表**：乘法运算专项训练
- **每日数学练习**：每日数学题目打卡

### 数据管理
- 使用 Realm 数据库进行本地数据存储
- 支持数据导入和导出功能
- 数据库管理界面（通过连续点击标题 6 次进入）

## 技术栈

- **开发语言**：Swift
- **UI 框架**：SwiftUI
- **数据库**：Realm
- **依赖管理**：CocoaPods
- **最低支持版本**：iOS 14.0+

## 项目结构

```
RainbowKingdom/
├── English/              # 英语学习模块
│   ├── WordManagementView.swift
│   ├── WordDisplayView.swift
│   ├── QuizView.swift
│   └── WordCompletionView.swift
├── Math/                 # 数学练习模块
│   ├── MathView.swift
│   ├── MathQuizView.swift
│   └── MultiplicationConfigView.swift
├── ClockIn/             # 打卡功能模块
│   ├── DailyPracticeView.swift
│   ├── ClockInHistoryView.swift
│   └── FullScreenDailyPracticeView.swift
├── Database/            # 数据库管理
│   ├── DatabaseManager.swift
│   ├── DataImportExport.swift
│   └── Models/         # 数据模型
└── RainbowKingdomApp.swift
```

## 安装与运行

### 环境要求

- Xcode 13.0+
- iOS 14.0+
- CocoaPods

### 安装步骤

1. 克隆项目
```bash
git clone git@github.com:IanIsMyUsername/RainbowKingdom.git
cd RainbowKingdom
```

2. 安装依赖
```bash
pod install
```

3. 打开工作空间
```bash
open RainbowKingdom.xcworkspace
```

4. 在 Xcode 中选择目标设备并运行

## 使用说明

1. 启动应用后，选择学习科目：
   - 每日一练：完成每日英语和数学练习
   - 英语：进行单词学习和测试
   - 数学：进行数学题目练习

2. 隐藏功能：
   - 连续快速点击主界面标题"彩虹王国" 6 次，可进入数据库管理界面

## 版本信息

- **当前版本**：1.0
- **Bundle ID**：com.chunxiao.RainbowKingdom

## 作者

Yizhou Chen

## 许可证

此项目为个人学习项目
