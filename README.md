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

- **开发语言**：Swift / SwiftUI
- **数据库**：Realm（RealmSwift 20.x，Swift Package）
- **依赖管理**：Swift Package Manager（RealmSwift、FluidAudio、ml-stable-diffusion）
- **本地 AI 模型**（全部离线运行，模型文件不进 git）
  - Kokoro-82M：英文单词朗读（FluidAudio），约 90 MB，位于 `BundledModels/`
  - Stable Diffusion 1.5（Apple Core ML 6-bit）：「动物大作战」看图拼词的配图生成，约 860 MB，位于 `BundledStableDiffusion/`
- **最低支持版本**：iOS 18.0

## 项目结构

```
RainbowKingdom/
├── English/              # 英语学习模块（单词管理、测验、填空）
├── Math/                 # 数学练习模块（加减法、乘法、练习配置页）
├── ClockIn/              # 每日一练（打卡日历、英语翻译/填空、动物大作战）
├── Animals/              # 动物大作战：词表、配图服务、Stable Diffusion 引擎与模型管理
├── Speech/               # Kokoro 本地朗读
├── Database/             # Realm 数据库与数据模型
└── Resources/            # vocabularies.csv 词表、animals.csv 动物词表
BundledModels/            # Kokoro 模型（git 忽略，由 scripts/setup.sh 下载）
BundledStableDiffusion/   # Stable Diffusion 模型（git 忽略，由 scripts/setup.sh 下载）
scripts/setup.sh          # 新机器一键准备脚本
```

## 安装与运行

### 环境要求

- macOS，Xcode 26 或更高
- 能访问 Hugging Face 的网络（模型文件从 huggingface.co 下载；国内网络需要代理）
- 真机需要 iOS 18.0+；「动物大作战」的配图生成推荐 M 系列 iPad 或 iPhone 15 Pro 及以后

### 新机器上手（三步）

```bash
git clone git@github.com:IanIsMyUsername/RainbowKingdom.git
cd RainbowKingdom
./scripts/setup.sh          # 下载两套模型（约 950 MB）并解析 Swift Package 依赖
```

然后用 Xcode 打开 `RainbowKingdom.xcodeproj`，选真机运行即可。脚本可以重复执行：已完整的文件会跳过，中断后再跑会从断点继续。

常用参数：

```bash
./scripts/setup.sh --kokoro-only   # 只下载朗读模型
./scripts/setup.sh --sd-only       # 只下载画图模型
./scripts/setup.sh --open          # 完成后自动打开 Xcode 工程
HF_ENDPOINT=https://your-proxy ./scripts/setup.sh   # 换 Hugging Face 入口
```

两套模型都固定在具体的 commit，保证每台机器下到的文件一致；要升级模型版本时修改脚本顶部的 `*_REV`。

### 词表维护

- 普通单词：`RainbowKingdom/Resources/vocabularies.csv`
- 动物大作战：`RainbowKingdom/Resources/animals.csv`，列为「英文,中文,表情,图片描述」，`#` 开头为注释；图片描述可留空，含逗号时用英文双引号包起来

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
