//
//  AnimalBattleView.swift
//  RainbowKingdom
//
//  每日一练「动物大作战」：看本机 Apple Intelligence 生成的动物卡通图，拼写英文单词。
//  词表来自 Resources/animals.csv；图片不可用时用 CSV 中的表情兜底。
//

import SwiftUI

struct AnimalBattleView: View {
    static let subjectName = "动物大作战"

    let targetDate: Date?  // 补打卡的目标日期，nil 表示今天
    @EnvironmentObject var clockInManager: ClockInManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var configManager = PracticeConfigManager()
    @ObservedObject private var imageService = AnimalImageService.shared
    @ObservedObject private var modelStore = StableDiffusionModelStore.shared
    @ObservedObject private var speech = WordSpeechService.shared

    @State private var questions: [AnimalWord] = []
    @State private var currentIndex = 0
    @State private var inputs: [[String]] = []  // 每题的字母输入
    @State private var focusedIndex: Int? = 0
    @State private var submitted: Set<Int> = []
    @State private var answeredCorrectly: Set<Int> = []  // 首次即答对
    @State private var initiallyWrong: Set<Int> = []
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var needsCorrection = false
    @State private var showSummary = false
    @State private var startTime: Date?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentImage: UIImage?
    @State private var imageLoading = false
    @State private var celebrate = false
    @State private var showModelDownload = false
    @State private var skippedModelDownload = false
    @State private var readAloudStars: [Int: Int] = [:]  // 题号 → 跟读星数
    @State private var readAloudDone: Set<Int> = []
    @ObservedObject private var readAloud = ReadAloudService.shared

    /// 拼对后是否需要跟读（配置开启且模型可用）
    private var readAloudRequired: Bool {
        configManager.config.readAloud.isEnabled && readAloud.isAvailable
    }

    /// 当前题拼对了但还没完成跟读
    private var readAloudPending: Bool {
        readAloudRequired && showFeedback && isCorrect && !readAloudDone.contains(currentIndex)
    }

    init(targetDate: Date? = nil) {
        self.targetDate = targetDate
    }

    private var currentQuestion: AnimalWord? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        NavigationView {
            Group {
                if showSummary {
                    summaryView
                } else {
                    quizContent
                }
            }
            .navigationTitle(Self.subjectName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear(perform: startQuiz)
        .task(id: currentIndex) {
            await loadCurrentImage()
        }
        .sheet(isPresented: $showModelDownload) {
            ModelDownloadView(
                allowSkip: true,
                onFinished: {
                    // 模型刚下好：把本轮的图排进后台生成，并刷新当前这题
                    imageService.prefetch(questions)
                    Task { await loadCurrentImage() }
                },
                onSkip: { skippedModelDownload = true }
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("无法开始"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    // MARK: - 答题界面

    private var quizContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressBar

                if let question = currentQuestion {
                    questionCard(question)
                }

                navigationButtons
            }
            .padding()
        }
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(currentIndex + 1) / \(questions.count) 只")
                    .font(.headline)
                Spacer()
                HStack(spacing: 16) {
                    Label("\(answeredCorrectly.count)", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Label("\(submitted.count - answeredCorrectly.count)", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .font(.subheadline.weight(.semibold))
            }

            ProgressView(value: Double(currentIndex), total: max(Double(questions.count), 1))
                .progressViewStyle(LinearProgressViewStyle(tint: .teal))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }

    private func questionCard(_ question: AnimalWord) -> some View {
        // 横屏（iPad 横向）图片在左、拼写在右；竖屏上下排列。ViewThatFits 选第一个放得下的布局。
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 28) {
                pictureColumn(question)
                    .frame(width: 340)
                spellingColumn(question)
                    .frame(minWidth: 620)
            }

            VStack(spacing: 18) {
                pictureColumn(question)
                spellingColumn(question)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }

    /// 图片 + 中文 + 发音
    private func pictureColumn(_ question: AnimalWord) -> some View {
        VStack(spacing: 14) {
            animalPicture(question)
                .scaleEffect(celebrate ? 1.08 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: celebrate)

            HStack(spacing: 12) {
                Text(question.chinese)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                speakerButton(for: question.english, size: .title2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 字母格 + 键盘 + 反馈
    private func spellingColumn(_ question: AnimalWord) -> some View {
        VStack(spacing: 18) {
            letterBoxes(for: question)

            if !showFeedback || needsCorrection {
                KeyboardView(
                    lowercase: true,  // 小朋友学的是小写拼写，键盘也显示小写
                    onInput: { handleInput($0, word: question.english) },
                    onDelete: { handleDelete(word: question.english) },
                    onDone: { submitAnswer() }
                )
            }

            if showFeedback {
                feedbackBanner(question)
            }

            if readAloudPending {
                ReadAloudCard(
                    target: question.english,
                    chinese: question.chinese,
                    passStars: configManager.config.readAloud.passStars,
                    maxAttempts: configManager.config.readAloud.maxAttempts,
                    accent: .teal
                ) { stars, _ in
                    readAloudStars[currentIndex] = stars
                    readAloudDone.insert(currentIndex)
                }
                .id("readAloud-\(currentIndex)")
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func animalPicture(_ question: AnimalWord) -> some View {
        // 生成一结束服务里就有图了，直接用它，不等 currentImage 状态回写，避免尾部闪一下 loading
        let displayedImage = currentImage ?? imageService.images[question.cacheKey]
        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.teal.opacity(0.12), Color.yellow.opacity(0.12)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(8)
                    .transition(.opacity)
            } else if imageLoading && imageService.engineState == .preparing {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("第一次使用，正在准备画画模型…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("大约需要一分钟，之后会快很多")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if imageLoading && imageService.generating.contains(question.cacheKey) {
                VStack(spacing: 12) {
                    Text(question.emoji.isEmpty ? "🎨" : question.emoji)
                        .font(.system(size: 72))
                    ProgressView(value: imageService.generationProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .teal))
                        .frame(width: 180)
                    if imageService.generationProgress >= 0.999 {
                        Text("正在上色，马上好…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("正在画 \(question.chinese)… \(Int(imageService.generationProgress * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else if imageLoading {
                VStack(spacing: 12) {
                    Text(question.emoji.isEmpty ? "🎨" : question.emoji)
                        .font(.system(size: 72))
                    ProgressView()
                    Text("排队等待画 \(question.chinese)…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Text(question.emoji.isEmpty ? "🐾" : question.emoji)
                        .font(.system(size: 120))
                    switch imageService.engineState {
                    case .modelMissing:
                        Button {
                            showModelDownload = true
                        } label: {
                            Label("下载画画模型后可以看到真图", systemImage: "arrow.down.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.teal)
                    case .unavailable(let reason):
                        Text(reason)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .frame(width: 300, height: 300)  // 固定正方形，横屏时背景不再拉伸
    }

    private func letterBoxes(for question: AnimalWord) -> some View {
        let word = question.english
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(word.enumerated()), id: \.offset) { position, char in
                    if char.isLetter {
                        let letterIndex = letterIndex(upTo: position, in: word)
                        let filled = currentInput(at: letterIndex)
                        let isFocused = focusedIndex == letterIndex && (!showFeedback || needsCorrection)
                        Button(action: {
                            guard !showFeedback || needsCorrection else { return }
                            if needsCorrection {
                                showFeedback = false
                                needsCorrection = false
                            }
                            focusedIndex = letterIndex
                        }) {
                            Text(filled.isEmpty ? " " : filled.lowercased())
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(boxTextColor(filled: filled, correct: String(char)))
                                .frame(width: 40, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    // strokeBorder 把描边画在框内，不会被 ScrollView 的边界裁掉
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(isFocused ? Color.teal : Color.gray.opacity(0.3), lineWidth: isFocused ? 3 : 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    } else if char == " " {
                        Spacer().frame(width: 18, height: 50)
                    } else {
                        Text(String(char))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 50)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    /// 提交后：对的字母绿色、错的红色；未提交时黑色
    private func boxTextColor(filled: String, correct: String) -> Color {
        guard showFeedback, !filled.isEmpty else { return .primary }
        return filled.lowercased() == correct.lowercased() ? .green : .red
    }

    private func feedbackBanner(_ question: AnimalWord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "star.fill" : "xmark.circle.fill")
                .foregroundColor(isCorrect ? .yellow : .red)
                .font(.title2)

            if isCorrect {
                Text("太棒了！\(question.english)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            } else {
                Text("再试一次，正确拼写: \(question.english)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                speakerButton(for: question.english, size: .body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }

    private var navigationButtons: some View {
        HStack(spacing: 20) {
            Spacer()

            if !showFeedback {
                Button("提交答案") {
                    submitAnswer()
                }
                .foregroundColor(.white)
                .padding()
                .background(allLettersFilled ? Color.green : Color.gray)
                .cornerRadius(10)
                .disabled(!allLettersFilled)
            } else if needsCorrection {
                Button("订正") {
                    showFeedback = false
                    needsCorrection = false
                    if let question = currentQuestion {
                        focusedIndex = firstWrongPosition(in: question.english)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(10)

                Button("跳过") {
                    advance()
                }
                .foregroundColor(.orange)
                .padding()
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
            } else if readAloudPending {
                Text("读一读上面的单词，再进入下一只")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                Button(currentIndex == questions.count - 1 ? "完成练习" : "下一只") {
                    advance()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.teal)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - 总结

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                let score = answeredCorrectly.count
                let percentage = questions.isEmpty ? 0 : Double(score) / Double(questions.count) * 100

                VStack(spacing: 12) {
                    Text("动物大作战结果")
                        .font(.system(size: 30, weight: .bold))
                    Text("\(score) / \(questions.count)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.teal)
                    Text(performanceText(percentage))
                        .font(.headline)
                        .foregroundColor(performanceColor(percentage))
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.teal.opacity(0.12), Color.yellow.opacity(0.12)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

                VStack(spacing: 12) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        summaryRow(question, index: index)
                    }
                }

                VStack(spacing: 15) {
                    Button("返回主界面") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(15)

                    Button("再玩一次") {
                        restartQuiz()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(15)
                }
            }
            .padding()
        }
    }

    private func summaryRow(_ question: AnimalWord, index: Int) -> some View {
        let correct = answeredCorrectly.contains(index)
        let answer = index < inputs.count ? inputs[index].joined() : ""
        return HStack(spacing: 14) {
            if let image = imageService.images[question.cacheKey] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text(question.emoji.isEmpty ? "🐾" : question.emoji)
                    .font(.system(size: 40))
                    .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(question.english)
                        .font(.headline)
                    speakerButton(for: question.english, size: .subheadline)
                }
                Text(question.chinese)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !correct {
                    Text("你的拼写: \(answer.isEmpty ? "未作答" : answer)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if let stars = readAloudStars[index] {
                    HStack(spacing: 4) {
                        Text("跟读")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(i < stars ? .yellow : .gray.opacity(0.4))
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(correct ? .green : .red)
                .font(.title2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(correct ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - 输入处理

    private var allLettersFilled: Bool {
        guard let question = currentQuestion else { return false }
        let count = question.english.filter { $0.isLetter }.count
        let current = currentInputs
        return count > 0 && (0..<count).allSatisfy { $0 < current.count && !current[$0].isEmpty }
    }

    private var currentInputs: [String] {
        currentIndex < inputs.count ? inputs[currentIndex] : []
    }

    private func currentInput(at index: Int) -> String {
        let current = currentInputs
        return index < current.count ? current[index] : ""
    }

    private func letterIndex(upTo position: Int, in word: String) -> Int {
        word.prefix(position).filter { $0.isLetter }.count
    }

    private func ensureCapacity(for word: String) {
        while inputs.count <= currentIndex { inputs.append([]) }
        let count = word.filter { $0.isLetter }.count
        while inputs[currentIndex].count < count { inputs[currentIndex].append("") }
    }

    private func handleInput(_ char: String, word: String) {
        guard char.count == 1 else { return }
        ensureCapacity(for: word)
        let count = inputs[currentIndex].count
        let index = focusedIndex ?? firstEmptyPosition(in: word)
        guard index < count else { return }

        inputs[currentIndex][index] = char.lowercased()

        // 光标跳到下一个空格；全部填满则停在末尾
        if let next = ((index + 1)..<count).first(where: { inputs[currentIndex][$0].isEmpty }) {
            focusedIndex = next
        } else if let anyEmpty = (0..<count).first(where: { inputs[currentIndex][$0].isEmpty }) {
            focusedIndex = anyEmpty
        } else {
            focusedIndex = min(index + 1, count - 1)
        }
    }

    private func handleDelete(word: String) {
        ensureCapacity(for: word)
        guard let index = focusedIndex else { return }
        if !inputs[currentIndex][index].isEmpty {
            inputs[currentIndex][index] = ""
        } else if index > 0 {
            inputs[currentIndex][index - 1] = ""
            focusedIndex = index - 1
        }
    }

    private func firstEmptyPosition(in word: String) -> Int {
        let count = word.filter { $0.isLetter }.count
        let current = currentInputs
        return (0..<count).first { $0 >= current.count || current[$0].isEmpty } ?? 0
    }

    private func firstWrongPosition(in word: String) -> Int {
        let letters = word.lowercased().filter { $0.isLetter }.map(String.init)
        let current = currentInputs
        return letters.indices.first { $0 >= current.count || current[$0].lowercased() != letters[$0] } ?? 0
    }

    // MARK: - 流程

    private func startQuiz() {
        let all = AnimalWordStore.loadFromBundle()
        guard !all.isEmpty else {
            errorMessage = "没有找到动物词表（Resources/animals.csv），请先添加动物单词。"
            showError = true
            return
        }

        let count = max(1, min(configManager.config.animalBattle.questionCount, all.count))
        questions = Array(all.shuffled().prefix(count))
        inputs = Array(repeating: [], count: questions.count)
        currentIndex = 0
        focusedIndex = 0
        startTime = Date()

        // 后台把本轮所有动物的图先画出来，后面的题零等待
        imageService.prefetch(questions)

        // 跟读要用的听力模型也提前加载，孩子拼第一个词时就准备好了
        if readAloudRequired {
            Task { await readAloud.prepare() }
        }

        // 有题目没有现成的图、模型又没下载：先问一下要不要下载（可跳过用表情）
        let needsGeneration = questions.contains { !imageService.hasLocalImage(for: $0) }
        if needsGeneration && !modelStore.isInstalled && !skippedModelDownload && !modelStore.state.isDownloading {
            showModelDownload = true
        }
    }

    private func loadCurrentImage() async {
        guard let question = currentQuestion else { return }
        currentImage = imageService.images[question.cacheKey]
        if currentImage != nil { return }

        imageLoading = true
        let image = await imageService.image(for: question)
        // 期间可能已切到下一题
        if currentQuestion?.id == question.id {
            withAnimation { currentImage = image }
            imageLoading = false
        }
    }

    private func submitAnswer() {
        guard let question = currentQuestion, allLettersFilled else { return }

        let isFirst = !submitted.contains(currentIndex)
        submitted.insert(currentIndex)

        let expected = question.english.lowercased().filter { $0.isLetter }
        isCorrect = currentInputs.joined().lowercased() == expected
        showFeedback = true
        SoundEffects.shared.play(isCorrect ? .correct : .wrong)

        if isCorrect {
            if isFirst && !initiallyWrong.contains(currentIndex) {
                answeredCorrectly.insert(currentIndex)
            }
            needsCorrection = false
            focusedIndex = nil
            // 需要跟读时由跟读卡负责示范朗读，这里不再读，否则会连读两遍
            if !readAloudRequired {
                speech.speak(question.english)
            }
            celebrate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { celebrate = false }
        } else {
            if isFirst { initiallyWrong.insert(currentIndex) }
            needsCorrection = true
        }
    }

    private func advance() {
        showFeedback = false
        isCorrect = false
        needsCorrection = false
        if currentIndex >= questions.count - 1 {
            completeQuiz()
        } else {
            currentIndex += 1
            focusedIndex = 0
        }
    }

    private func completeQuiz() {
        let score = answeredCorrectly.count
        let timeSpent = startTime?.timeIntervalSinceNow.magnitude ?? 0

        let quizQuestions = questions.enumerated().map { index, animal in
            QuizQuestion(
                vocabulary: Vocabulary(english: animal.english, chinese: animal.chinese, group: "动物", type: .word),
                questionType: .fillInBlank,
                question: "看图拼写动物: \(animal.chinese)",
                correctAnswer: animal.english,
                options: nil,
                hint: animal.emoji,
                readAloudStars: readAloudStars[index]
            )
        }

        let record = ClockInRecord(
            date: targetDate ?? Date(),
            subject: Self.subjectName,
            score: score,
            totalQuestions: questions.count,
            timeSpent: timeSpent,
            completedDate: Date(),
            questions: quizQuestions,
            userAnswers: inputs.map { $0.joined() }
        )
        clockInManager.addClockInRecord(record)
        SoundEffects.shared.play(.complete)
        showSummary = true
    }

    private func restartQuiz() {
        showSummary = false
        submitted = []
        answeredCorrectly = []
        initiallyWrong = []
        showFeedback = false
        isCorrect = false
        needsCorrection = false
        currentImage = nil
        readAloudStars = [:]
        readAloudDone = []
        startQuiz()
    }

    // MARK: - 辅助

    private func speakerButton(for word: String, size: Font) -> some View {
        Button(action: { speech.speak(word) }) {
            if speech.isPreparing {
                // 语音模型还在加载（首次启动约十几秒），转圈提示；点击会等它就绪后再朗读
                ProgressView()
                    .tint(.teal)
            } else {
                Image(systemName: speech.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(size)
                    .foregroundColor(.teal)
            }
        }
        .buttonStyle(.plain)
    }

    private func performanceText(_ percentage: Double) -> String {
        switch percentage {
        case 90...100: return "动物园园长！"
        case 80..<90: return "小小饲养员！"
        case 70..<80: return "继续加油"
        default: return "再去认识一下小动物吧"
        }
    }

    private func performanceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    AnimalBattleView()
        .environmentObject(ClockInManager())
}
