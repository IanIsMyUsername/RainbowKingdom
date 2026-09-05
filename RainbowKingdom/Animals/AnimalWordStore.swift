//
//  AnimalWordStore.swift
//  RainbowKingdom
//
//  「动物大作战」词表：从 bundle 内 Resources/animals.csv 读取。
//  CSV 列：英文,中文,表情,图片描述
//    - 表情：Apple Intelligence 不可用时的兜底图
//    - 图片描述：可选，留空则用默认模板生成提示词
//

import Foundation

struct AnimalWord: Identifiable, Hashable {
    var id: String { english.lowercased() }
    let english: String
    let chinese: String
    let emoji: String
    let imagePrompt: String

    /// 磁盘缓存 / 提示词共用的稳定 key（小写、空格转连字符）
    var cacheKey: String {
        english.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}

enum AnimalWordStore {
    static let fileName = "animals"

    /// 默认提示词模板：卡通、儿童绘本风格、白底，避免每次风格漂移
    static func defaultPrompt(for english: String) -> String {
        "a cute friendly cartoon \(english), children's picture book illustration, simple white background"
    }

    static func loadFromBundle() -> [AnimalWord] {
        let url = Bundle.main.url(forResource: fileName, withExtension: "csv", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: fileName, withExtension: "csv")
        guard let url, let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("⚠️ bundle 中未找到 \(fileName).csv")
            return []
        }
        return parse(content)
    }

    static func parse(_ content: String) -> [AnimalWord] {
        var result: [AnimalWord] = []
        var seen = Set<String>()

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("英文") || line.hasPrefix("#") { continue }

            let fields = CSVParsing.fields(from: line).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard fields.count >= 2, !fields[0].isEmpty, !fields[1].isEmpty else { continue }

            let english = fields[0]
            let key = english.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            let emoji = fields.count > 2 ? fields[2] : ""
            let customPrompt = fields.count > 3 ? fields[3] : ""
            let prompt = customPrompt.isEmpty
                ? defaultPrompt(for: english)
                : "\(customPrompt), cartoon children's picture book illustration, simple white background"

            result.append(AnimalWord(english: english, chinese: fields[1], emoji: emoji, imagePrompt: prompt))
        }
        return result
    }
}
