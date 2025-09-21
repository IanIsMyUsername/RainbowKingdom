#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量添加词汇脚本
"""

import os
import sys

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from add_vocabulary import VocabularyManager

def add_words():
    """批量添加词汇示例"""
    # 获取CSV文件路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_file_path = os.path.join(script_dir, '..', 'RainbowKingdom', 'Resources', 'vocabularies.csv')
    csv_file_path = os.path.normpath(csv_file_path)
    
    manager = VocabularyManager(csv_file_path)
    
    # 示例词汇数据 - 只需要英文和中文
    vocabularies = [
        # ("apple", "苹果"),
        # ("banana", "香蕉")
        ("ring", "戒指"),
        ("quilt", "被子"),
        ("rug", "地毯"),
        ("table", "桌子"),
        ("sofa", "沙发"),
        ("queen", "女王")
    ]
    
    print("=== 批量添加单词词汇 ===")
    added_count = 0
    
    for english, chinese in vocabularies:
        if manager.add_vocabulary(english, chinese, '基础词汇', '单词'):
            added_count += 1
            print(f"✅ {english} -> {chinese}")
        else:
            print(f"⚠️  {english} 已存在，跳过")
    
    # 保存到文件
    manager.save_vocabularies()
    print(f"\n完成！共添加 {added_count} 个词汇")

def add_phrases():
    """添加常用短语示例"""
    # 获取CSV文件路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_file_path = os.path.join(script_dir, '..', 'RainbowKingdom', 'Resources', 'vocabularies.csv')
    csv_file_path = os.path.normpath(csv_file_path)
    
    manager = VocabularyManager(csv_file_path)
    
    # 常用短语
    phrases = [
        # ("Good morning", "早上好"),
        # ("Good afternoon", "下午好")
        ("Good night", "晚安")
    ]
    
    print("=== 批量添加常用短语 ===")
    added_count = 0
    
    for english, chinese in phrases:
        if manager.add_vocabulary(english, chinese, '常用短语', '短语'):
            added_count += 1
            print(f"✅ {english} -> {chinese}")
        else:
            print(f"⚠️  {english} 已存在，跳过")
    
    # 保存到文件
    manager.save_vocabularies()
    print(f"\n完成！共添加 {added_count} 个短语")

def main():
    print("=== 彩虹王国词汇管理工具 ===")
    add_words()
    add_phrases()

if __name__ == "__main__":
    main()
