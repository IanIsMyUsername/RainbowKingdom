//
//  WordCompletionView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/11/15.
//

import SwiftUI

struct WordCompletionView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    @Environment(\.presentationMode) var presentationMode
    @State private var currentVocabularyIndex = 0
    @State private var userInputs: [String] = [] // 用户输入的字符
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var score = 0
    @State private var completedCount = 0
    @State private var showScore = false
    @State private var shuffledVocabularies: [Vocabulary] = []
    @State private var focusedIndex: Int? = nil
    @State private var showKeyboard = false
    @State private var isFirstAttempt = true
    @State private var needsCorrection = false
    @State private var currentInput = ""
    
    let maxQuestions: Int
    
    private var currentVocabulary: Vocabulary? {
        guard !shuffledVocabularies.isEmpty && currentVocabularyIndex < shuffledVocabularies.count else {
            return nil
        }
        return shuffledVocabularies[currentVocabularyIndex]
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if showScore {
                scoreView
            } else if let vocabulary = currentVocabulary {
                practiceView(vocabulary: vocabulary)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("词汇补全")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear {
            shuffleVocabularies()
        }
    }
    
    private func practiceView(vocabulary: Vocabulary) -> some View {
        VStack(spacing: 30) {
            // 进度指示器
            HStack {
                Text("\(currentVocabularyIndex + 1) / \(shuffledVocabularies.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("得分: \(score)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 第一行：需要补全的英语（带提示）
            Text(maskedWord(vocabulary.english))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 第二行：中文翻译
            Text(vocabulary.chinese)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 第三行：输入区域（下划线）
            HStack {
                Spacer()
                inputAreaView(word: vocabulary.english)
                Spacer()
            }
            .padding(.horizontal)
            
            // 反馈信息
            if showResult {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                            .font(.title2)
                        
                        Text(isCorrect ? "正确！" : "错误")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        if !isCorrect {
                            Text("正确答案: \(vocabulary.english)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                    Spacer()
                }
            }
            
            Spacer()
            
            // 按钮区域
            buttonArea
                .padding(.horizontal)
                .padding(.bottom, 30)
        }
    }
    
    private func maskedWord(_ word: String) -> String {
        let words = word.components(separatedBy: " ")
        if words.count > 1 {
            return maskSentenceWords(words)
        }
        return maskSingleWord(word)
    }
    
    private func maskSingleWord(_ word: String) -> String {
        let letters = word.filter { $0.isLetter }
        let letterCount = letters.count
        guard letterCount > 0 else { return word }
        
        let maskCount = max(1, (letterCount + 1) / 2)
        let visibleLetterCount = letterCount - maskCount
        let maskPrefix = Bool.random()
        
        var result = ""
        var letterIndex = 0
        
        for char in word {
            if char.isLetter {
                let shouldShow: Bool
                if maskPrefix {
                    shouldShow = letterIndex >= maskCount
                } else {
                    shouldShow = letterIndex < visibleLetterCount
                }
                result.append(shouldShow ? char : "_")
                letterIndex += 1
            } else {
                result.append(char)
            }
        }
        
        return result
    }

    // 句子按单词级别遮罩（遮住一半单词）
    private func maskSentenceWords(_ words: [String]) -> String {
        guard !words.isEmpty else { return "" }
        let maskWordCount = max(1, (words.count + 1) / 2)
        let startMaskIndex = max(0, words.count - maskWordCount)
        
        let maskedWords = words.enumerated().map { index, word in
            if index >= startMaskIndex {
                return maskWholeWord(word)
            }
            return word
        }
        
        return maskedWords.joined(separator: " ")
    }

    private func maskWholeWord(_ word: String) -> String {
        var result = ""
        for char in word {
            if char.isLetter {
                result.append("_")
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private func inputAreaView(word: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                    if char.isLetter {
                        let letterIndex = getLetterIndex(upTo: index, in: word)
                        Button(action: {
                            if !showResult || needsCorrection {
                                if !showKeyboard {
                                    focusedIndex = findFirstEmptyPosition(in: word)
                                } else {
                                    focusedIndex = letterIndex
                                }
                                showKeyboard = true
                            }
                        }) {
                            Text(getCurrentInput(at: letterIndex))
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(letterIndex == focusedIndex ? .blue : .primary)
                                .frame(width: 32, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(letterIndex == focusedIndex ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .disabled(showResult && !needsCorrection)
                    } else if char == " " {
                        Spacer()
                            .frame(width: 16, height: 40)
                    } else {
                        Text(String(char))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 40)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            if showKeyboard, let index = focusedIndex {
                KeyboardInputView(
                    onInput: { char in
                        handleInput(char, at: index)
                    },
                    onDelete: {
                        handleDelete(at: index)
                    },
                    onDone: {
                        showKeyboard = false
                        focusedIndex = nil
                        checkAnswer()
                    }
                )
            }
        }
    }
    
    private func getLetterIndex(upTo position: Int, in word: String) -> Int {
        var count = 0
        for (index, char) in word.enumerated() {
            if index >= position { break }
            if char.isLetter {
                count += 1
            }
        }
        return count
    }
    
    private func handleInput(_ char: String, at index: Int) {
        guard char.count == 1 else { return }
        
        // 确保数组足够大
        while userInputs.count <= index {
            userInputs.append("")
        }
        
        userInputs[index] = char.lowercased()
        
        // 自动移动到下一个空白字母位置
        if let vocabulary = currentVocabulary {
            let letterCount = vocabulary.english.filter { $0.isLetter }.count
            for i in (index + 1)..<letterCount {
                if i >= userInputs.count || userInputs[i].isEmpty {
                    focusedIndex = i
                    return
                }
            }
        }
        
        // 如果没有下一个位置，取消焦点
        focusedIndex = nil
    }
    
    private func handleDelete(at index: Int) {
        // Ensure array is large enough
        while userInputs.count <= index {
            userInputs.append("")
        }
        
        // Clear current position
        userInputs[index] = ""
        
        // If current position is now empty and we're not at the beginning,
        // move to previous position and clear it
        if userInputs[index].isEmpty && index > 0 {
            focusedIndex = index - 1
            if index - 1 < userInputs.count {
                userInputs[index - 1] = ""
            }
        }
    }
    
    private var buttonArea: some View {
        VStack(spacing: 15) {
            if needsCorrection {
                Button(action: {
                    showResult = false
                    needsCorrection = false
                    // 清空所有输入
                    userInputs = []
                }) {
                    Text("订正")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .cornerRadius(25)
                }
            } else if showResult && isCorrect {
                Button(action: nextQuestion) {
                    Text(currentVocabularyIndex < shuffledVocabularies.count - 1 ? "下一题" : "查看成绩")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }
        }
    }
    
    private func checkAnswer() {
        guard let vocabulary = currentVocabulary else { return }
        
        let correctAnswer = vocabulary.english.lowercased().filter { $0.isLetter }
        let userAnswer = userInputs.joined().lowercased()
        
        isCorrect = userAnswer == correctAnswer
        showResult = true
        
        if isCorrect {
            if isFirstAttempt {
                score += 1
            }
            completedCount += 1
            needsCorrection = false
        } else {
            needsCorrection = true
        }
        
        if isFirstAttempt && !isCorrect {
            isFirstAttempt = false
        }
    }
    
    private func nextQuestion() {
        if currentVocabularyIndex < shuffledVocabularies.count - 1 {
            currentVocabularyIndex += 1
            resetCurrentQuestion()
        } else {
            showScore = true
        }
    }
    
    private func resetCurrentQuestion() {
        userInputs = []
        showResult = false
        isCorrect = false
        focusedIndex = nil
        showKeyboard = false
        isFirstAttempt = true
        needsCorrection = false
    }
    
    private func shuffleVocabularies() {
        let allVocabularies = vocabularyManager.currentGroupVocabularies.shuffled()
        shuffledVocabularies = Array(allVocabularies.prefix(maxQuestions))
        resetCurrentQuestion()
    }
    
    private func findFirstEmptyPosition(in word: String) -> Int {
        let letterCount = word.filter { $0.isLetter }.count
        
        for i in 0..<letterCount {
            if i >= userInputs.count || userInputs[i].isEmpty {
                return i
            }
        }
        
        return 0
    }
    
    private func getCurrentInput(at index: Int) -> String {
        if index < userInputs.count && !userInputs[index].isEmpty {
            return userInputs[index]
        }
        return "_"
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("当前组为空")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
    
    private var scoreView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 10) {
                Text("练习完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("\(score) / \(completedCount)")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                let percentage = completedCount > 0 ? Double(score) / Double(completedCount) * 100 : 0
                Text("正确率: \(Int(percentage))%")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("返回")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
}

// 键盘输入视图
struct KeyboardInputView: View {
    let onInput: (String) -> Void
    let onDelete: () -> Void
    let onDone: () -> Void
    
    let letters = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    var body: some View {
        VStack(spacing: 14) {
            ForEach(letters, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { letter in
                        Button(action: {
                            onInput(letter)
                        }) {
                            Text(letter)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 56)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                        .frame(width: 100, height: 56)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                
                Button(action: onDone) {
                    Text("完成")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 56)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
    }
}

#Preview {
    NavigationView {
        WordCompletionView(vocabularyManager: VocabularyManager(), maxQuestions: 5)
    }
}
