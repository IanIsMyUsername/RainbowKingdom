//
//  CSVParsing.swift
//  RainbowKingdom
//
//  CSV 行解析工具：支持 RFC 4180 双引号转义，
//  使英文字段可以包含半角逗号（如 "No, it isn't"）。
//  与 DataImportExport.escapeCSV 的导出格式对称。
//

import Foundation

enum CSVParsing {
    /// 解析一行 CSV 为字段数组。
    /// 支持 "..." 包裹的字段（内部逗号不分列，"" 解析为一个双引号）。
    static func fields(from line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var chars = line.makeIterator()
        var pending: Character? = nil

        func next() -> Character? {
            if let p = pending {
                pending = nil
                return p
            }
            return chars.next()
        }

        while let ch = next() {
            if inQuotes {
                if ch == "\"" {
                    if let lookahead = chars.next() {
                        if lookahead == "\"" {
                            current.append("\"")  // "" 转义
                        } else {
                            inQuotes = false
                            pending = lookahead
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            } else if ch == "\"" && current.isEmpty {
                inQuotes = true
            } else if ch == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        fields.append(current)
        return fields
    }
}
