//
//  DatabaseManager.swift
//  RainbowKingdom
//
//  Created by Yizhou Chen on 2025/9/11.
//

import Foundation
import RealmSwift

/// 数据库管理器
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var realm: Realm?
    
    private init() {
        setupRealm()
    }
    
    // MARK: - 初始化配置
    
    /// 设置Realm数据库
    private func setupRealm() {
        do {
            // 配置Realm
            var config = Realm.Configuration()
            
            // 设置数据库文件路径（Documents目录）
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let realmPath = documentsPath.appendingPathComponent("RainbowKingdom.realm")
            config.fileURL = realmPath
            
            // 设置schema版本（用于未来迁移）
            config.schemaVersion = 4  // v3: 练习配置新增「动物大作战」；v4: 跟读配置 + 题目跟读星数

            // 设置迁移块（未来需要时可以添加）
            config.migrationBlock = { migration, oldSchemaVersion in
                // 如果需要迁移，在这里处理
                if oldSchemaVersion < 1 {
                    // 迁移逻辑
                }
                // v2: 各练习配置新增 isEnabled，默认 true，由 @Persisted 默认值自动应用
            }
            
            // 初始化Realm实例
            realm = try Realm(configuration: config)
            
            print("✅ Realm数据库初始化成功")
            print("📂 数据库路径: \(realmPath.path)")
            
        } catch {
            print("❌ Realm数据库初始化失败: \(error)")
            realm = nil
        }
    }
    
    // MARK: - 数据库访问
    
    /// 获取Realm实例（只读）
    func getRealm() throws -> Realm {
        guard let realm = realm else {
            throw DatabaseError.realmNotInitialized
        }
        return realm
    }
    
    /// 执行写入操作
    func write(_ block: @escaping (Realm) throws -> Void) throws {
        let realm = try getRealm()
        try realm.write {
            try block(realm)
        }
    }
    
    /// 执行写入操作（异步）
    func writeAsync(_ block: @escaping (Realm) throws -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let realm = realm else {
            completion(.failure(DatabaseError.realmNotInitialized))
            return
        }
        
        realm.writeAsync {
            do {
                try block(realm)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 通用CRUD操作
    
    /// 添加对象
    func add<T: Object>(_ object: T) throws {
        try write { realm in
            realm.add(object)
        }
    }
    
    /// 添加多个对象
    func add<T: Object>(_ objects: [T]) throws {
        try write { realm in
            realm.add(objects)
        }
    }
    
    /// 更新对象
    func update<T: Object>(_ object: T, update: @escaping (T) -> Void) throws {
        try write { realm in
            update(object)
            realm.add(object, update: .modified)
        }
    }
    
    /// 删除对象
    func delete<T: Object>(_ object: T) throws {
        try write { realm in
            realm.delete(object)
        }
    }
    
    /// 删除多个对象
    func delete<T: Object>(_ objects: [T]) throws {
        try write { realm in
            realm.delete(objects)
        }
    }
    
    /// 删除所有指定类型的对象
    func deleteAll<T: Object>(_ type: T.Type) throws {
        try write { realm in
            let objects = realm.objects(type)
            realm.delete(objects)
        }
    }
    
    /// 查询所有对象
    func objects<T: Object>(_ type: T.Type) throws -> Results<T> {
        let realm = try getRealm()
        return realm.objects(type)
    }
    
    /// 根据主键查询对象
    func object<T: Object, KeyType>(ofType type: T.Type, forPrimaryKey key: KeyType) throws -> T? {
        let realm = try getRealm()
        return realm.object(ofType: type, forPrimaryKey: key)
    }
    
    // MARK: - 数据库维护
    
    /// 删除所有数据（谨慎使用）
    func deleteAllData() throws {
        try write { realm in
            realm.deleteAll()
        }
    }
    
    /// 获取数据库文件大小
    func getDatabaseSize() -> Int64? {
        guard let realm = realm,
              let fileURL = realm.configuration.fileURL else {
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64
        } catch {
            print("获取数据库大小失败: \(error)")
            return nil
        }
    }
    
    /// 压缩数据库
    func compactDatabase() throws {
        guard let realm = realm,
              let fileURL = realm.configuration.fileURL else {
            throw DatabaseError.realmNotInitialized
        }
        
        let config = realm.configuration
        try Realm.performMigration(for: config)
        
        // 重新初始化
        setupRealm()
    }
}

// MARK: - 错误定义

enum DatabaseError: LocalizedError {
    case realmNotInitialized
    case objectNotFound
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .realmNotInitialized:
            return "Realm数据库未初始化"
        case .objectNotFound:
            return "未找到指定对象"
        case .writeFailed:
            return "写入操作失败"
        }
    }
}
