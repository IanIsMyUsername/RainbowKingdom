//
//  MathQuizView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct MathQuizView: View {
    @StateObject private var quizManager = MathQuizManager()
    @StateObject private var clockInManager = ClockInManager()
    @State private var selectedOperationType: MathOperationType = .mixed
    @State private var showingResult = false
    @State private var userAnswer = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if !quizManager.isQuizActive {
                // 练习开始界面
                startView
            } else if showingResult {
                // 结果界面
                resultView
            } else {
                // 练习进行界面
                quizView
            }
        }
        .padding()
        .navigationTitle("数学练习")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    // MARK: - 开始界面
    private var startView: some View {
        VStack(spacing: 30) {
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("加减法练习")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.blue)
            
            Text("每日一练 10道题")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(spacing: 20) {
                Text("选择练习类型")
                    .font(.system(size: 20, weight: .semibold))
                
                Picker("运算类型", selection: $selectedOperationType) {
                    ForEach(MathOperationType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            
            VStack(spacing: 15) {
                Text("练习规则")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• 共10道题目")
                    Text("• 数字范围：70以内")
                    Text("• 包含加法和减法")
                    Text("• 完成后自动打卡")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Button(action: startQuiz) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始练习")
                }
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 练习界面
    private var quizView: some View {
        VStack(spacing: 20) {
            // 进度条
            ProgressView(value: Double(quizManager.currentQuestionIndex + 1), total: Double(quizManager.currentQuiz.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("第 \(quizManager.currentQuestionIndex + 1) 题")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("共 \(quizManager.currentQuiz.count) 题")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 题目显示
            if let question = quizManager.currentQuestion {
                VStack(spacing: 30) {
                    Text(question.question)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        )
                    
                    // 答案输入
                    VStack(spacing: 15) {
                        TextField("请输入答案", text: $userAnswer)
                            .font(.system(size: 24, weight: .medium))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 120)
                        
                        Button("提交答案") {
                            submitAnswer()
                        }
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 40)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .disabled(userAnswer.isEmpty)
                    }
                }
            }
            
            Spacer()
            
            // 导航按钮
            HStack(spacing: 20) {
                Button("上一题") {
                    previousQuestion()
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 100, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
                .disabled(quizManager.currentQuestionIndex == 0)
                
                Spacer()
                
                Button("下一题") {
                    nextQuestion()
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 100, height: 40)
                .background(Color.blue)
                .cornerRadius(20)
                .disabled(userAnswer.isEmpty)
            }
        }
    }
    
    // MARK: - 结果界面
    private var resultView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("练习完成！")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.green)
            
            if let lastResult = quizManager.quizResults.last {
                VStack(spacing: 20) {
                    // 成绩显示
                    VStack(spacing: 10) {
                        Text("正确率")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(lastResult.percentage))%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text(lastResult.performance)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(performanceColor(lastResult.percentage))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // 详细信息
                    VStack(spacing: 15) {
                        HStack {
                            Text("答对题目：")
                            Spacer()
                            Text("\(lastResult.correctAnswers) / \(lastResult.totalQuestions)")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        
                        HStack {
                            Text("用时：")
                            Spacer()
                            Text(formatTime(lastResult.timeSpent))
                                .font(.system(size: 17, weight: .semibold))
                        }
                        
                        HStack {
                            Text("练习类型：")
                            Spacer()
                            Text(lastResult.operationType.displayName)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            VStack(spacing: 15) {
                Button("再来一次") {
                    resetQuiz()
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.blue)
                .cornerRadius(25)
                
                Button("返回首页") {
                    // 这里可以添加返回首页的逻辑
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 200, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(25)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 辅助方法
    private func startQuiz() {
        quizManager.startQuiz(operationType: selectedOperationType, questionCount: 10)
        userAnswer = ""
    }
    
    private func submitAnswer() {
        guard !userAnswer.isEmpty else { return }
        
        quizManager.submitAnswer(userAnswer)
        
        if quizManager.currentQuestionIndex < quizManager.currentQuiz.count - 1 {
            nextQuestion()
        } else {
            // 最后一题，结束练习
            quizManager.endQuiz()
            
            // 添加到打卡记录
            if let lastResult = quizManager.quizResults.last {
                // 将数学题目转换为QuizQuestion格式
                let quizQuestions = convertMathQuestionsToQuizQuestions(lastResult.questions)
                
                let clockInRecord = ClockInRecord(
                    date: Calendar.current.startOfDay(for: Date()),
                    subject: "数学",
                    score: lastResult.correctAnswers,
                    totalQuestions: lastResult.totalQuestions,
                    timeSpent: lastResult.timeSpent,
                    completedDate: lastResult.completedDate,
                    questions: quizQuestions,
                    userAnswers: lastResult.userAnswers
                )
                clockInManager.addClockInRecord(clockInRecord)
            }
            
            showingResult = true
        }
    }
    
    private func nextQuestion() {
        quizManager.nextQuestion()
        userAnswer = ""
    }
    
    private func previousQuestion() {
        quizManager.previousQuestion()
        // 恢复之前的答案
        if quizManager.currentQuestionIndex < quizManager.userAnswers.count {
            userAnswer = quizManager.userAnswers[quizManager.currentQuestionIndex]
        }
    }
    
    private func resetQuiz() {
        quizManager.resetQuiz()
        showingResult = false
        userAnswer = ""
    }
    
    private func performanceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 90...100:
            return .green
        case 80..<90:
            return .blue
        case 70..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 将数学题目转换为QuizQuestion格式
    private func convertMathQuestionsToQuizQuestions(_ mathQuestions: [MathQuestion]) -> [QuizQuestion] {
        return mathQuestions.map { mathQuestion in
            // 创建一个虚拟的Vocabulary对象
            let vocabulary = Vocabulary(
                english: "Math Question",
                chinese: "数学题目",
                group: "数学练习",
                type: .word,
                createdDate: Date()
            )
            
            // 生成选择题选项
            let options = mathQuestion.options?.map { "\($0)" } ?? []
            
            let op1Name = mathQuestion.operation.displayName
            let op2Name = mathQuestion.operation2.displayName
            return QuizQuestion(
                vocabulary: vocabulary,
                questionType: .multipleChoice,
                question: mathQuestion.question,
                correctAnswer: "\(mathQuestion.correctAnswer)",
                options: options,
                hint: "类型：连续运算（\(op1Name) 和 \(op2Name)）"
            )
        }
    }
}

#Preview {
    NavigationView {
        MathQuizView()
    }
}
