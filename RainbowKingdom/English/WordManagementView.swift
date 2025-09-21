//
//  WordManagementView.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import SwiftUI

struct WordManagementView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    @State private var showingAddVocabulary = false
    @State private var editingVocabulary: Vocabulary?
    @State private var showingAddGroup = false
    @State private var editingGroup: VocabularyGroup?
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部统计信息和组选择
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("词汇管理")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("共 \(vocabularyManager.vocabularies.count) 个词汇")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            showingAddGroup = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            showingAddVocabulary = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            vocabularyManager.reloadFromCSV()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // 筛选器
                VStack(spacing: 10) {
                    // 组选择器
                    HStack {
                        Text("选择组:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Picker("选择组", selection: $vocabularyManager.selectedGroup) {
                            Text("全部").tag("")
                            ForEach(vocabularyManager.groupNames, id: \.self) { groupName in
                                Text(groupName).tag(groupName)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .font(.caption)
                    }
                    
                    // 日期筛选器
                    HStack {
                        Text("日期筛选:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Picker("日期筛选", selection: $vocabularyManager.dateFilterMode) {
                            ForEach(DateFilterMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .font(.caption)
                        .onChange(of: vocabularyManager.dateFilterMode) { newMode in
                            vocabularyManager.setDateFilterMode(newMode)
                        }
                        
                        if vocabularyManager.dateFilterMode == .custom {
                            DatePicker("", selection: $vocabularyManager.selectedDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .font(.caption)
                                .onChange(of: vocabularyManager.selectedDate) { newDate in
                                    vocabularyManager.setCustomDate(newDate)
                                }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            if vocabularyManager.currentGroupVocabularies.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("当前组为空")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("请选择其他组或添加词汇")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingAddVocabulary = true
                    }) {
                        Text("添加第一个词汇")
                            .font(.title3)
                            .fontWeight(.semibold)
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 词汇列表
                List {
                    ForEach(vocabularyManager.currentGroupVocabularies) { vocabulary in
                        VocabularyRowView(vocabulary: vocabulary) {
                            editingVocabulary = vocabulary
                        }
                    }
                    .onDelete(perform: deleteVocabularies)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("词汇管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddVocabulary) {
            AddEditVocabularyView(vocabularyManager: vocabularyManager)
        }
        .sheet(item: $editingVocabulary) { vocabulary in
            AddEditVocabularyView(vocabularyManager: vocabularyManager, editingVocabulary: vocabulary)
        }
        .sheet(isPresented: $showingAddGroup) {
            AddEditGroupView(vocabularyManager: vocabularyManager)
        }
        .sheet(item: $editingGroup) { group in
            AddEditGroupView(vocabularyManager: vocabularyManager, editingGroup: group)
        }
    }
    
    private func deleteVocabularies(at offsets: IndexSet) {
        vocabularyManager.deleteVocabulary(at: offsets)
    }
}

struct VocabularyRowView: View {
    let vocabulary: Vocabulary
    let onEdit: () -> Void
    
    private var typeColor: Color {
        switch vocabulary.type {
        case .word:
            return .blue
        case .phrase:
            return .green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(vocabulary.english)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(vocabulary.chinese)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(vocabulary.group)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(formatDate(vocabulary.createdDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text(vocabulary.type.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor)
                    .cornerRadius(8)
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddEditVocabularyView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    let editingVocabulary: Vocabulary?
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var english = ""
    @State private var chinese = ""
    @State private var selectedGroup = ""
    @State private var selectedType = Vocabulary.VocabularyType.word
    
    init(vocabularyManager: VocabularyManager, editingVocabulary: Vocabulary? = nil) {
        self.vocabularyManager = vocabularyManager
        self.editingVocabulary = editingVocabulary
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 15) {
                    // 英文输入
                    VStack(alignment: .leading, spacing: 5) {
                        Text("英文单词")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入英文单词", text: $english)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // 中文输入
                    VStack(alignment: .leading, spacing: 5) {
                        Text("中文翻译")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入中文翻译", text: $chinese)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                    }
                    
                    // 组选择
                    VStack(alignment: .leading, spacing: 5) {
                        Text("选择组")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("选择组", selection: $selectedGroup) {
                            ForEach(vocabularyManager.groupNames, id: \.self) { groupName in
                                Text(groupName).tag(groupName)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // 类型选择
                    VStack(alignment: .leading, spacing: 5) {
                        Text("词汇类型")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("类型", selection: $selectedType) {
                            ForEach(Vocabulary.VocabularyType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
                
                Spacer()
                
                // 保存按钮
                Button(action: saveVocabulary) {
                    Text(editingVocabulary == nil ? "添加词汇" : "更新词汇")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
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
                .disabled(english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                         chinese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle(editingVocabulary == nil ? "添加词汇" : "编辑词汇")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            if let vocabulary = editingVocabulary {
                english = vocabulary.english
                chinese = vocabulary.chinese
                selectedGroup = vocabulary.group
                selectedType = vocabulary.type
            } else {
                selectedGroup = vocabularyManager.groupNames.first ?? ""
            }
        }
    }
    
    private func saveVocabulary() {
        let trimmedEnglish = english.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedChinese = chinese.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEnglish.isEmpty && !trimmedChinese.isEmpty && !selectedGroup.isEmpty else { return }
        
        let vocabulary = Vocabulary(
            english: trimmedEnglish,
            chinese: trimmedChinese,
            group: selectedGroup,
            type: selectedType
        )
        
        if let editingVocabulary = editingVocabulary {
            // 更新现有词汇
            vocabularyManager.updateVocabulary(vocabulary)
        } else {
            // 添加新词汇
            vocabularyManager.addVocabulary(vocabulary)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddEditGroupView: View {
    @ObservedObject var vocabularyManager: VocabularyManager
    let editingGroup: VocabularyGroup?
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "blue"
    
    private let colors = ["blue", "green", "purple", "orange", "red", "pink"]
    
    init(vocabularyManager: VocabularyManager, editingGroup: VocabularyGroup? = nil) {
        self.vocabularyManager = vocabularyManager
        self.editingGroup = editingGroup
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 15) {
                    // 组名输入
                    VStack(alignment: .leading, spacing: 5) {
                        Text("组名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入组名", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                    }
                    
                    // 描述输入
                    VStack(alignment: .leading, spacing: 5) {
                        Text("描述")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入描述", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                    }
                    
                    // 颜色选择
                    VStack(alignment: .leading, spacing: 5) {
                        Text("颜色")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // 保存按钮
                Button(action: saveGroup) {
                    Text(editingGroup == nil ? "添加组" : "更新组")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
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
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle(editingGroup == nil ? "添加组" : "编辑组")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            if let group = editingGroup {
                name = group.name
                description = group.description
                selectedColor = group.color
            }
        }
    }
    
    private func saveGroup() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        let group = VocabularyGroup(
            name: trimmedName,
            description: trimmedDescription,
            color: selectedColor
        )
        
        if let editingGroup = editingGroup {
            // 更新现有组
            var updatedGroup = group
            updatedGroup = VocabularyGroup(name: trimmedName, description: trimmedDescription, color: selectedColor)
            vocabularyManager.updateGroup(updatedGroup)
        } else {
            // 添加新组
            vocabularyManager.addGroup(group)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    NavigationView {
        WordManagementView(vocabularyManager: VocabularyManager())
    }
}
