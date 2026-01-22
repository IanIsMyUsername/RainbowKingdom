//
//  DataImportExport.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import SwiftUI

/// 数据导入导出管理器
class DataImportExport {
    static let shared = DataImportExport()
    private let dbManager = DatabaseManager.shared
    
    // 当前导出会话的文件夹URL（确保同一次导出的所有文件保存到同一个文件夹）
    private var currentExportFolderURL: URL?
    
    private init() {}
    
    // MARK: - CSV导出
    
    /// 导出词汇到CSV
    func exportVocabulariesToCSV() -> URL? {
        do {
            let realmVocabularies = try dbManager.objects(RealmVocabulary.self)
            let vocabularies = realmVocabularies.map { Vocabulary(from: $0) }
            
            var csvContent = "英文,中文,分类,类型,创建日期\n"
            
            for vocabulary in vocabularies {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: vocabulary.createdDate)
                
                let line = "\(escapeCSV(vocabulary.english)),\(escapeCSV(vocabulary.chinese)),\(escapeCSV(vocabulary.group)),\(escapeCSV(vocabulary.type.rawValue)),\(dateString)\n"
                csvContent += line
            }
            
            return saveToFile(content: csvContent, filename: "vocabularies_\(dateString()).csv")
        } catch {
            print("导出词汇到CSV失败: \(error)")
            return nil
        }
    }
    
    /// 导出打卡记录到CSV
    func exportClockInRecordsToCSV() -> URL? {
        do {
            let realmRecords = try dbManager.objects(RealmClockInRecord.self)
            let records = realmRecords.map { ClockInRecord(from: $0) }
            
            var csvContent = "日期,科目,分数,总题数,用时(秒),完成时间\n"
            
            for record in records {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormatter.string(from: record.date)
                let completedString = dateFormatter.string(from: record.completedDate)
                
                let line = "\(dateString),\(escapeCSV(record.subject)),\(record.score),\(record.totalQuestions),\(Int(record.timeSpent)),\(completedString)\n"
                csvContent += line
            }
            
            return saveToFile(content: csvContent, filename: "clock_in_records_\(dateString()).csv")
        } catch {
            print("导出打卡记录到CSV失败: \(error)")
            return nil
        }
    }
    
    /// 导出数学练习结果到CSV
    func exportMathQuizResultsToCSV() -> URL? {
        do {
            let realmResults = try dbManager.objects(RealmMathQuizResult.self)
            let results = realmResults.map { MathQuizResult(from: $0) }
            
            var csvContent = "完成时间,类型,总题数,正确数,分数,用时(秒),正确率\n"
            
            for result in results {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormatter.string(from: result.completedDate)
                
                let line = "\(dateString),\(escapeCSV(result.operationType.rawValue)),\(result.totalQuestions),\(result.correctAnswers),\(result.score),\(Int(result.timeSpent)),\(String(format: "%.2f", result.percentage))%\n"
                csvContent += line
            }
            
            return saveToFile(content: csvContent, filename: "math_quiz_results_\(dateString()).csv")
        } catch {
            print("导出数学练习结果到CSV失败: \(error)")
            return nil
        }
    }
    
    /// 导出英语测验结果到CSV
    func exportEnglishQuizResultsToCSV() -> URL? {
        do {
            let realmResults = try dbManager.objects(RealmQuizResult.self)
            let results = realmResults.map { QuizResult(from: $0) }
            
            var csvContent = "完成时间,题型,类型,范围,总题数,正确数,分数,用时(秒),正确率\n"
            
            for result in results {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormatter.string(from: result.completedDate)
                
                let questionType = result.questionType?.rawValue ?? ""
                let quizType = result.quizType?.rawValue ?? ""
                
                let line = "\(dateString),\(escapeCSV(questionType)),\(escapeCSV(quizType)),\(escapeCSV(result.scope.rawValue)),\(result.totalQuestions),\(result.correctAnswers),\(result.score),\(Int(result.timeSpent)),\(String(format: "%.2f", result.percentage))%\n"
                csvContent += line
            }
            
            return saveToFile(content: csvContent, filename: "english_quiz_results_\(dateString()).csv")
        } catch {
            print("导出英语测验结果到CSV失败: \(error)")
            return nil
        }
    }
    
    /// 导出乘法练习结果到CSV
    func exportMultiplicationQuizResultsToCSV() -> URL? {
        do {
            let realmResults = try dbManager.objects(RealmMultiplicationQuizResult.self)
            let results = realmResults.map { MultiplicationQuizResult(from: $0) }
            
            var csvContent = "完成时间,数字范围,总题数,正确数,分数,用时(秒),正确率\n"
            
            for result in results {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormatter.string(from: result.completedDate)
                
                let line = "\(dateString),1-\(result.maxNumber-1),\(result.totalQuestions),\(result.correctAnswers),\(result.score),\(Int(result.timeSpent)),\(String(format: "%.2f", result.percentage))%\n"
                csvContent += line
            }
            
            return saveToFile(content: csvContent, filename: "multiplication_quiz_results_\(dateString()).csv")
        } catch {
            print("导出乘法练习结果到CSV失败: \(error)")
            return nil
        }
    }
    
    // MARK: - JSON导出
    
    /// 导出所有数据到JSON
    func exportAllDataToJSON() -> URL? {
        do {
            var allData: [String: Any] = [:]
            
            // 词汇数据
            let realmVocabularies = try dbManager.objects(RealmVocabulary.self)
            allData["vocabularies"] = realmVocabularies.map { vocab -> [String: Any] in
                var dict: [String: Any] = [
                    "id": vocab.id,
                    "english": vocab.english,
                    "chinese": vocab.chinese,
                    "group": vocab.group,
                    "type": vocab.type,
                    "createdDate": ISO8601DateFormatter().string(from: vocab.createdDate)
                ]
                if let lastReviewed = vocab.lastReviewedDate {
                    dict["lastReviewedDate"] = ISO8601DateFormatter().string(from: lastReviewed)
                } else {
                    dict["lastReviewedDate"] = NSNull()
                }
                return dict
            }
            
            // 打卡记录
            let realmRecords = try dbManager.objects(RealmClockInRecord.self)
            allData["clockInRecords"] = realmRecords.map { record in
                [
                    "id": record.id,
                    "date": ISO8601DateFormatter().string(from: record.date),
                    "subject": record.subject,
                    "score": record.score,
                    "totalQuestions": record.totalQuestions,
                    "timeSpent": record.timeSpent,
                    "completedDate": ISO8601DateFormatter().string(from: record.completedDate)
                ]
            }
            
            // 数学练习结果
            let realmMathResults = try dbManager.objects(RealmMathQuizResult.self)
            allData["mathQuizResults"] = realmMathResults.map { result in
                [
                    "id": result.id,
                    "operationType": result.operationType.rawValue,
                    "totalQuestions": result.totalQuestions,
                    "correctAnswers": result.correctAnswers,
                    "score": result.score,
                    "timeSpent": result.timeSpent,
                    "completedDate": ISO8601DateFormatter().string(from: result.completedDate)
                ]
            }
            
            // 英语测验结果
            let realmQuizResults = try dbManager.objects(RealmQuizResult.self)
            allData["englishQuizResults"] = realmQuizResults.map { result in
                [
                    "id": result.id,
                    "questionType": result.questionType?.rawValue ?? "",
                    "quizType": result.quizType?.rawValue ?? "",
                    "scope": result.scope.rawValue,
                    "totalQuestions": result.totalQuestions,
                    "correctAnswers": result.correctAnswers,
                    "score": result.score,
                    "timeSpent": result.timeSpent,
                    "completedDate": ISO8601DateFormatter().string(from: result.completedDate)
                ]
            }
            
            // 乘法练习结果
            let realmMultiplicationResults = try dbManager.objects(RealmMultiplicationQuizResult.self)
            allData["multiplicationQuizResults"] = realmMultiplicationResults.map { result in
                [
                    "id": result.id,
                    "maxNumber": result.maxNumber,
                    "totalQuestions": result.totalQuestions,
                    "correctAnswers": result.correctAnswers,
                    "score": result.score,
                    "timeSpent": result.timeSpent,
                    "completedDate": ISO8601DateFormatter().string(from: result.completedDate)
                ]
            }
            
            // 转换为JSON
            let jsonData = try JSONSerialization.data(withJSONObject: allData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            return saveToFile(content: jsonString, filename: "rainbow_kingdom_backup_\(dateString()).json")
        } catch {
            print("导出所有数据到JSON失败: \(error)")
            return nil
        }
    }
    
    // MARK: - CSV导入
    
    /// 从CSV导入词汇
    func importVocabulariesFromCSV(url: URL) -> (success: Int, failed: Int) {
        var successCount = 0
        var failedCount = 0
        
        do {
            let csvContent = try String(contentsOf: url, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines)
            
            var vocabulariesToAdd: [RealmVocabulary] = []
            
            for (index, line) in lines.enumerated() {
                if index == 0 { continue } // 跳过标题行
                
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty { continue }
                
                let components = trimmedLine.components(separatedBy: ",")
                if components.count >= 3 {
                    let english = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let chinese = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let group = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let type = components.count > 3 ? Vocabulary.VocabularyType(rawValue: components[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? .word : .word
                    
                    var createdDate = Date()
                    if components.count > 4 {
                        let dateString = components[4].trimmingCharacters(in: .whitespacesAndNewlines)
                        if let parsedDate = parseDate(from: dateString) {
                            createdDate = parsedDate
                        }
                    }
                    
                    if !english.isEmpty && !chinese.isEmpty && !group.isEmpty {
                        let vocabulary = Vocabulary(
                            english: english,
                            chinese: chinese,
                            group: group,
                            type: type,
                            createdDate: createdDate
                        )
                        vocabulariesToAdd.append(vocabulary.toRealm())
                        successCount += 1
                    } else {
                        failedCount += 1
                    }
                } else {
                    failedCount += 1
                }
            }
            
            // 批量添加到数据库
            if !vocabulariesToAdd.isEmpty {
                try dbManager.add(vocabulariesToAdd)
            }
            
            return (successCount, failedCount)
        } catch {
            print("从CSV导入词汇失败: \(error)")
            return (successCount, failedCount)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 转义CSV字段（处理包含逗号或引号的情况）
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
    
    /// 获取或创建当前导出会话的文件夹
    private func getCurrentExportFolder() -> URL? {
        // 如果已经有当前导出文件夹，直接返回
        if let folderURL = currentExportFolderURL, FileManager.default.fileExists(atPath: folderURL.path) {
            return folderURL
        }
        
        // 创建新的导出文件夹（基于日期和时间戳）
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateFolderName = "导出_\(dateFormatter.string(from: Date()))"
        let dateFolderURL = documentsPath.appendingPathComponent(dateFolderName)
        
        // 创建文件夹
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dateFolderURL.path) {
            do {
                try fileManager.createDirectory(at: dateFolderURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ 创建导出文件夹: \(dateFolderURL.path)")
            } catch {
                print("❌ 创建文件夹失败: \(error)")
                return nil
            }
        }
        
        // 保存当前导出文件夹URL
        currentExportFolderURL = dateFolderURL
        return dateFolderURL
    }
    
    /// 开始新的导出会话（重置文件夹，用于新的导出操作）
    func startNewExportSession() {
        currentExportFolderURL = nil
    }
    
    /// 保存内容到文件
    private func saveToFile(content: String, filename: String) -> URL? {
        guard let folderURL = getCurrentExportFolder() else {
            return nil
        }
        
        // 保存文件到当前导出文件夹
        let fileURL = folderURL.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ 文件已保存: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ 保存文件失败: \(error)")
            return nil
        }
    }
    
    /// 生成日期字符串（用于文件名）
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    
    /// 解析日期字符串
    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}
