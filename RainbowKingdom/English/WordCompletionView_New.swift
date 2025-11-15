//
//  WordCompletionView_New.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/11/15.
//

import SwiftUI

struct WordCompletionViewNew: View {
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
            inputAreaView(word: vocabulary.english)
                .padding(.horizontal)
            
            Spacer()
            
            // 按钮区域
            buttonArea
                .padding(.horizontal)
                .padding(.bottom, 30)
        }
    }
    
    private func inputAreaView(word: String) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                if char.isLetter {
                    // 字母位置：可输入的下划线或已输入的字符
                    let letterIndex = getLetterIndex(upTo: index, in: word)
                    Button(action: {
                        focusedIndex = letterIndex
                        showKeyboard = true
                    }) {
                        Text(letterIndex < userInputs.count && !userInputs[letterIndex].isEmpty ? userInputs[letterIndex] : "_")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(letterIndex == focusedIndex ? .blue : .primary)
                            .frame(width: 32, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(letterIndex == focusedIndex ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .disabled(showResult && isCorrect)
                } else if char == " " {
                    // 空格
                    Spacer()
                        .frame(width: 16)
                } else {
                    // 其他符号（连字符、撇号等）直接显示
                    Text(String(char))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 40)
                }
            }
        }
        .overlay(
            Group {
                if showKeyboard, let index = focusedIndex {
                    KeyboardInputView(
                        currentInput: $currentInput,
                        onInput: { char in
                            handleInput(char, at: index)
                        },
                        onDelete: {
                            handleDelete(at: index)
                        },
                        onDone: {
                            showKeyboard = false
                            focusedIndex = nil
                        }
                    )
                    .offset(y: 200)
                }
            }
        )
    }
    
    private func maskedWord(_ word: String) -> String {
        let words = word.components(separatedBy: " ")
        return words.map { maskSingleWord($0) }.joined(separator: " ")
    }
    
    private func maskSingleWord(_ word: String) -> String {
        let letters = word.filter { $0.isLetter }
        let letterCount = letters.count
        guard letterCount > 0 else { return word }
        
        let maskCount = max(1, letterCount / 3)
        let visibleLetterCount = letterCount - maskCount
        
        var result = ""
        var letterIndex = 0
        
        for char in word {
            if char.isLetter {
                if letterIndex < visibleLetterCount {
                    result.append(char)
                } else {
                    result.append("_")
                }
                letterIndex += 1
            } else {
                result.append(char)
            }
        }
        
        return result
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
        guard index < userInputs.count else { return }
        userInputs[index] = ""
    }
    
    private var buttonArea: some View {
        VStack(spacing: 15) {
            if showKeyboard {
                Button(action: {
                    showKeyboard = false
                    focusedIndex = nil
                }) {
                    Text("确认")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            } else if !showResult {
                Button(action: submitAnswer) {
                    Text("提交答案")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                }
            } else if needsCorrection {
                Button(action: {
                    showResult = false
                    needsCorrection = false
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
            } else {
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
    
    private func submitAnswer() {
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
        
        // 无论对错，第一次提交后就不再是首次尝试
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
        currentInput = ""
    }
    
    private func shuffleVocabularies() {
        let allVocabularies = vocabularyManager.currentGroupVocabularies.shuffled()
        shuffledVocabularies = Array(allVocabularies.prefix(maxQuestions))
        resetCurrentQuestion()
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
    @Binding var currentInput: String
    let onInput: (String) -> Void
    let onDelete: () -> Void
    let onDone: () -> Void
    
    let letters = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(letters, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { letter in
                        Button(action: {
                            onInput(letter)
                        }) {
                            Text(letter)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 42)
                                .background(Color(.systemGray5))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 42)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Button(action: onDone) {
                    Text("完成")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 42)
                        .background(Color.blue)
                        .cornerRadius(6)
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
        WordCompletionViewNew(vocabularyManager: VocabularyManager(), maxQuestions: 5)
    }
}
