//
//  ReadAloudScorer.swift
//  RainbowKingdom
//
//  跟读打分：把 Whisper 识别出的文字和目标单词/短语比对，给 1 到 3 颗星。
//  纯函数，不依赖模型，方便调阈值。
//
//  规则：
//    - 没检测到说话 → 0 星（"没听到"）
//    - 字母相似度或发音键相似度 ≥ 0.85 → 3 星
//    - ≥ 0.6 → 2 星（音近，算过）
//    - 其余 → 1 星（要再读）
//

import Foundation

struct ReadAloudResult: Equatable {
    let target: String
    let transcript: String
    /// 0 没听到，1 不像，2 音近，3 准确
    let stars: Int
    /// 0...1，整体相似度
    let similarity: Double
    /// 0...1，识别置信度（词概率平均），低于 0.45 提示"再清楚一点"
    let confidence: Double
    /// 目标短语中每个词是否对上
    let wordMatches: [Bool]

    var heard: Bool { stars > 0 }
    var isAccurate: Bool { stars == 3 }
    var needsClearer: Bool { stars == 3 && confidence < 0.45 }

    var message: String {
        switch stars {
        case 0: return "没听到声音，靠近一点、大声一点再读一次"
        case 1: return "听起来不太像，听一遍示范再试试"
        case 2: return "很接近了！再读清楚一点会更好"
        default: return needsClearer ? "读对了，声音再大一点更好" : "太棒了，读得很准！"
        }
    }
}

enum ReadAloudScorer {
    static func score(target: String, transcript: String, confidence: Double, heard: Bool) -> ReadAloudResult {
        let targetWords = words(target)
        let spokenWords = words(transcript)

        guard heard, !spokenWords.isEmpty else {
            return ReadAloudResult(
                target: target, transcript: transcript, stars: 0, similarity: 0,
                confidence: confidence, wordMatches: Array(repeating: false, count: targetWords.count))
        }

        // 逐词：每个目标词在识别结果里找最像的词
        let matches = targetWords.map { tw -> Bool in
            spokenWords.contains { sw in wordSimilarity(tw, sw) >= 0.6 }
        }

        // 整体：去空格后的字母串相似度，和发音键相似度取高者
        let joinedTarget = targetWords.joined()
        let joinedSpoken = spokenWords.joined()
        let overall = max(
            similarity(joinedTarget, joinedSpoken),
            similarity(phoneticKey(joinedTarget), phoneticKey(joinedSpoken))
        )

        let stars: Int
        if overall >= 0.85 || (matches.allSatisfy { $0 } && overall >= 0.75) {
            stars = 3
        } else if overall >= 0.6 || (!matches.isEmpty && Double(matches.filter { $0 }.count) / Double(matches.count) >= 0.6) {
            stars = 2
        } else {
            stars = 1
        }

        return ReadAloudResult(
            target: target, transcript: transcript, stars: stars, similarity: overall,
            confidence: confidence, wordMatches: matches)
    }

    // MARK: - 文本工具

    /// 小写、只保留字母和数字、按空格分词。"Let's go!" → ["lets", "go"]
    static func words(_ text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func wordSimilarity(_ a: String, _ b: String) -> Double {
        max(similarity(a, b), similarity(phoneticKey(a), phoneticKey(b)))
    }

    /// 1 - 编辑距离 / 较长串长度
    static func similarity(_ a: String, _ b: String) -> Double {
        if a.isEmpty && b.isEmpty { return 1 }
        let maxLen = max(a.count, b.count)
        guard maxLen > 0 else { return 1 }
        return 1 - Double(levenshtein(Array(a), Array(b))) / Double(maxLen)
    }

    static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var cur = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            cur[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &cur)
        }
        return prev[b.count]
    }

    /// 简化版发音键（类似 Metaphone）：把发音相近的拼写归一，
    /// 例如 cat/kat、phone/fone、night/nite 得到相同的键。
    static func phoneticKey(_ word: String) -> String {
        var s = word.lowercased().filter { $0.isLetter }
        guard !s.isEmpty else { return "" }

        // 常见字母组合
        let pairs: [(String, String)] = [
            ("ph", "f"), ("gh", ""), ("ck", "k"), ("sch", "sk"), ("sh", "x"), ("ch", "x"), ("th", "0"),
            ("wh", "w"), ("qu", "kw"), ("wr", "r"), ("kn", "n"), ("gn", "n"), ("mb", "m"),
            ("tion", "xn"), ("dge", "j"), ("ce", "se"), ("ci", "si"), ("cy", "sy"),
        ]
        for (from, to) in pairs { s = s.replacingOccurrences(of: from, with: to) }

        var out = ""
        var prev: Character? = nil
        for (i, ch) in s.enumerated() {
            var c = ch
            switch c {
            case "c", "q": c = "k"
            case "z": c = "s"
            case "y": c = i == 0 ? "y" : "i"
            case "x": out.append("k"); c = "s"
            default: break
            }
            // 首字母保留元音，其后元音全部去掉
            if i > 0, "aeiou".contains(c) { continue }
            // 合并重复
            if c == prev { continue }
            out.append(c)
            prev = c
        }
        return out
    }
}
