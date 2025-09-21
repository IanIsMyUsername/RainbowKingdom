#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
词汇添加工具
用于方便地添加词汇到vocabularies.csv文件中
"""

import csv
import os
import sys
from datetime import datetime
from typing import List, Optional

class VocabularyManager:
    def __init__(self, csv_file_path: str):
        self.csv_file_path = csv_file_path
        self.vocabularies = []
        self.load_vocabularies()
    
    def load_vocabularies(self):
        """加载现有的词汇数据"""
        if os.path.exists(self.csv_file_path):
            with open(self.csv_file_path, 'r', encoding='utf-8') as file:
                reader = csv.reader(file)
                self.vocabularies = list(reader)
        else:
            print(f"警告: 文件 {self.csv_file_path} 不存在，将创建新文件")
            self.vocabularies = []
    
    def save_vocabularies(self):
        """保存词汇数据到CSV文件"""
        # 确保目录存在
        os.makedirs(os.path.dirname(self.csv_file_path), exist_ok=True)
        
        with open(self.csv_file_path, 'w', encoding='utf-8', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(self.vocabularies)
        print(f"词汇已保存到: {self.csv_file_path}")
    
    def add_vocabulary(self, english: str, chinese: str, category: str, 
                      vocab_type: str, date: Optional[str] = None):
        """
        添加新词汇
        
        Args:
            english: 英文词汇
            chinese: 中文翻译
            category: 分类（如：基础词汇、常用短语）
            vocab_type: 类型（如：单词、短语）
            date: 添加日期，默认为今天
        """
        if date is None:
            date = datetime.now().strftime('%Y-%m-%d')
        
        # 检查是否已存在相同的词汇
        for vocab in self.vocabularies:
            if len(vocab) >= 2 and vocab[0].lower() == english.lower():
                print(f"警告: 词汇 '{english}' 已存在，跳过添加")
                return False
        
        new_vocab = [english, chinese, category, vocab_type, date]
        self.vocabularies.append(new_vocab)
        print(f"已添加词汇: {english} - {chinese}")
        return True
    
    def add_multiple_vocabularies(self, vocab_list: List[dict]):
        """批量添加词汇"""
        added_count = 0
        for vocab in vocab_list:
            if self.add_vocabulary(**vocab):
                added_count += 1
        print(f"批量添加完成，共添加 {added_count} 个词汇")
    
    def search_vocabulary(self, keyword: str):
        """搜索词汇"""
        results = []
        keyword_lower = keyword.lower()
        
        for vocab in self.vocabularies:
            if (len(vocab) >= 2 and 
                (keyword_lower in vocab[0].lower() or keyword_lower in vocab[1].lower())):
                results.append(vocab)
        
        return results
    
    def list_vocabularies(self, limit: int = 10):
        """列出词汇（限制数量）"""
        print(f"\n最近添加的 {min(limit, len(self.vocabularies))} 个词汇:")
        print("-" * 60)
        for i, vocab in enumerate(self.vocabularies[:limit]):
            if len(vocab) >= 5:
                print(f"{i+1:2d}. {vocab[0]:<20} {vocab[1]:<15} {vocab[2]:<10} {vocab[4]}")
    
    def simple_add(self):
        """简化添加词汇模式 - 只需要英文和中文"""
        print("\n=== 简化添加词汇模式 ===")
        print("只需要输入英文和中文，其他字段自动使用默认值")
        print("默认分类: 基础词汇, 默认类型: 单词")
        print("输入 'quit' 退出")
        
        while True:
            print("\n" + "="*50)
            english = input("英文: ").strip()
            if english.lower() == 'quit':
                break
            
            if not english:
                print("英文不能为空")
                continue
            
            chinese = input("中文: ").strip()
            if not chinese:
                print("中文不能为空")
                continue
            
            # 使用默认值
            category = '基础词汇'
            vocab_type = '单词'
            
            # 添加词汇
            self.add_vocabulary(english, chinese, category, vocab_type)
            
            # 询问是否继续
            continue_add = input("继续添加? (y/n): ").strip().lower()
            if continue_add not in ['y', 'yes', '是']:
                break
        
        # 保存到文件
        self.save_vocabularies()

    def interactive_add(self):
        """交互式添加词汇"""
        print("\n=== 交互式添加词汇 ===")
        print("输入 'quit' 退出")
        
        while True:
            print("\n" + "="*50)
            english = input("请输入英文词汇: ").strip()
            if english.lower() == 'quit':
                break
            
            if not english:
                print("英文词汇不能为空")
                continue
            
            chinese = input("请输入中文翻译: ").strip()
            if not chinese:
                print("中文翻译不能为空")
                continue
            
            print("\n分类选项:")
            print("1. 基础词汇")
            print("2. 常用短语")
            print("3. 高级词汇")
            print("4. 自定义")
            
            category_choice = input("请选择分类 (1-4): ").strip()
            categories = {
                '1': '基础词汇',
                '2': '常用短语', 
                '3': '高级词汇'
            }
            
            if category_choice in categories:
                category = categories[category_choice]
            elif category_choice == '4':
                category = input("请输入自定义分类: ").strip()
            else:
                category = '基础词汇'
            
            print("\n类型选项:")
            print("1. 单词")
            print("2. 短语")
            print("3. 自定义")
            
            type_choice = input("请选择类型 (1-3): ").strip()
            types = {
                '1': '单词',
                '2': '短语'
            }
            
            if type_choice in types:
                vocab_type = types[type_choice]
            elif type_choice == '3':
                vocab_type = input("请输入自定义类型: ").strip()
            else:
                vocab_type = '单词'
            
            # 添加词汇
            self.add_vocabulary(english, chinese, category, vocab_type)
            
            # 询问是否继续
            continue_add = input("\n是否继续添加? (y/n): ").strip().lower()
            if continue_add not in ['y', 'yes', '是']:
                break
        
        # 保存到文件
        self.save_vocabularies()

def main():
    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # 构建CSV文件路径
    csv_file_path = os.path.join(script_dir, '..', 'RainbowKingdom', 'Resources', 'vocabularies.csv')
    csv_file_path = os.path.normpath(csv_file_path)
    
    print("=== 彩虹王国词汇管理工具 ===")
    print(f"CSV文件路径: {csv_file_path}")
    
    manager = VocabularyManager(csv_file_path)
    
    if len(sys.argv) > 1:
        # 命令行模式
        if sys.argv[1] == 'add':
            if len(sys.argv) >= 5:
                english = sys.argv[2]
                chinese = sys.argv[3]
                category = sys.argv[4]
                vocab_type = sys.argv[5] if len(sys.argv) > 5 else '单词'
                manager.add_vocabulary(english, chinese, category, vocab_type)
                manager.save_vocabularies()
            else:
                print("用法: python add_vocabulary.py add <英文> <中文> <分类> [类型]")
        
        elif sys.argv[1] == 'quick':
            # 快速添加模式 - 只需要英文和中文
            if len(sys.argv) >= 4:
                english = sys.argv[2]
                chinese = sys.argv[3]
                manager.add_vocabulary(english, chinese, '基础词汇', '单词')
                manager.save_vocabularies()
            else:
                print("用法: python add_vocabulary.py quick <英文> <中文>")
        
        elif sys.argv[1] == 'search':
            if len(sys.argv) > 2:
                keyword = sys.argv[2]
                results = manager.search_vocabulary(keyword)
                if results:
                    print(f"\n找到 {len(results)} 个匹配的词汇:")
                    for vocab in results:
                        print(f"  {vocab[0]} - {vocab[1]} ({vocab[2]})")
                else:
                    print("未找到匹配的词汇")
            else:
                print("用法: python add_vocabulary.py search <关键词>")
        
        elif sys.argv[1] == 'list':
            limit = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            manager.list_vocabularies(limit)
        
        else:
            print("未知命令")
            print_help()
    else:
        # 交互模式
        print("\n选择操作:")
        print("1. 简化添加词汇 (只需英文+中文)")
        print("2. 完整添加词汇 (可选择分类和类型)")
        print("3. 搜索词汇")
        print("4. 查看词汇列表")
        print("5. 退出")
        
        choice = input("\n请选择 (1-5): ").strip()
        
        if choice == '1':
            manager.simple_add()
        elif choice == '2':
            manager.interactive_add()
        elif choice == '3':
            keyword = input("请输入搜索关键词: ").strip()
            results = manager.search_vocabulary(keyword)
            if results:
                print(f"\n找到 {len(results)} 个匹配的词汇:")
                for vocab in results:
                    print(f"  {vocab[0]} - {vocab[1]} ({vocab[2]})")
            else:
                print("未找到匹配的词汇")
        elif choice == '4':
            limit = input("显示多少个词汇? (默认10): ").strip()
            limit = int(limit) if limit.isdigit() else 10
            manager.list_vocabularies(limit)
        elif choice == '5':
            print("再见!")
        else:
            print("无效选择")

def print_help():
    print("\n用法:")
    print("  python add_vocabulary.py                    # 交互模式")
    print("  python add_vocabulary.py quick <英文> <中文>  # 快速添加 (默认基础词汇+单词)")
    print("  python add_vocabulary.py add <英文> <中文> <分类> [类型]  # 完整添加")
    print("  python add_vocabulary.py search <关键词>    # 搜索词汇")
    print("  python add_vocabulary.py list [数量]        # 查看词汇列表")
    print("\n示例:")
    print("  python add_vocabulary.py quick 'hello' '你好'")
    print("  python add_vocabulary.py add 'hello' '你好' '基础词汇' '单词'")
    print("  python add_vocabulary.py search 'hello'")
    print("  python add_vocabulary.py list 20")

if __name__ == "__main__":
    main()
