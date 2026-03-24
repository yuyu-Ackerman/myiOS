//
//  DiaryStorageManager.swift
//  try
//
//  Created by 小余 on 2026/02/18.
//

import Foundation
import UIKit

// MARK: - Notifications

extension Notification.Name {
    /// 日记更新通知
    static let diaryUpdated = Notification.Name("DiaryUpdated")
}

/**
 日记存储管理器
 
 功能：
 1. 管理日记数据的持久化存储 (CRUD)
 2. 处理图片文件的保存与读取
 3. 维护数据一致性
 
 架构：
 单例模式 (Singleton)
 */
class DiaryStorageManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = DiaryStorageManager() // TODO: 这是什么写法
    
    /// 私有初始化方法，防止外部创建实例
    private init() {
        // 初始化时加载数据到内存缓存
        self.cachedDiaries = loadDiariesFromDisk()
    } // TODO: 为什么要留一个空的 init
    
    // MARK: - Properties
    
    /// 内存缓存：存储所有日记数据
    private var cachedDiaries: [DiaryModel] = []
    
    /// 串行队列，用于确保线程安全的数据读写
    private let queue = DispatchQueue(label: "com.todayview.diarystorage", qos: .userInitiated)
    
    // MARK: - Paths
    
    /// 获取 Documents 目录路径
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // TODO: 可以深入了解一下相关知识
    }
    
    /// 获取日记数据文件的路径 (JSON)
    private var dataFilePath: URL {
        return documentsDirectory.appendingPathComponent("diaries.json")
    }
    
    // MARK: - Helper Methods
    
    /// 从磁盘加载数据到内存（仅在初始化时调用）
    private func loadDiariesFromDisk() -> [DiaryModel] {
        guard let data = try? Data(contentsOf: dataFilePath) else { return [] }
        guard let diaries = try? JSONDecoder().decode([DiaryModel].self, from: data) else { return [] }
        return diaries
    }
    
    /// 将内存中的数据异步写入磁盘
    private func saveDiariesToDisk() {
        // 捕获当前的缓存副本
        let diariesToSave = self.cachedDiaries
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(diariesToSave)
                try data.write(to: self.dataFilePath)
                print("数据已成功写入磁盘")
            } catch {
                print("数据写入失败: \(error)")
            }
        }
    }
    
    /**
     清理指定日期的旧图片文件
     
     - Parameter date: 要清理的日期
     
     用途：
     在保存新日记前，删除旧日记关联的图片文件，防止产生孤儿文件
     
     注意：这是一个内部私有方法，不使用队列锁，由调用者保证线程安全
     */
    private func clearBufferInternal(date: Date) {
        // 直接访问 cachedDiaries，不加锁，因为外部调用者已经加锁了
        if let oldDiary = self.cachedDiaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            for path in oldDiary.imagePaths {
                let fullPath = documentsDirectory.appendingPathComponent(path)
                try? FileManager.default.removeItem(at: fullPath)
            }
        }
    }
    
    // MARK: - Core Operations
    
    /**
     保存日记
     
     - Parameter date: 日期
     - Parameter score: 评分
     - Parameter content: 内容
     - Parameter images: 图片数组
     
     流程：
     1. 清理旧数据
     2. 保存新图片到磁盘
     3. 更新内存中的日记列表
     4. 异步写入 JSON 文件
     5. 发送更新通知
     */
    func saveDiary(date: Date, score: Float, content: String, images: [UIImage]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 0. 清理该日期旧数据的图片文件，防止产生未引用的孤儿文件
            // 使用内部无锁版本，避免死锁
            self.clearBufferInternal(date: date)
            
            // 1. 保存新图片到磁盘 (图片IO仍可能耗时，但这是必要的)
            var savedImagePaths: [String] = []
            for image in images {
                let imageName = UUID().uuidString + ".jpg"
                let imagePath = self.documentsDirectory.appendingPathComponent(imageName)
                
                if let data = image.jpegData(compressionQuality: 0.8) {
                    do {
                        try data.write(to: imagePath)
                        savedImagePaths.append(imageName)
                    } catch {
                        print("图片保存失败: \(error)")
                    }
                }
            }
            
            // 2. 创建新的 Entry
            let newEntry = DiaryModel(date: date, score: score, content: content, imagePaths: savedImagePaths)
            
            // 3. 更新内存缓存
            // 移除同一天的旧日记 (假设每天只能有一篇日记)
            self.cachedDiaries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
            
            // 添加新日记
            self.cachedDiaries.append(newEntry)
            
            // 4. 异步写入磁盘
            self.saveDiariesToDisk()
            
            // 5. 在主线程发送通知，告知数据更新
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .diaryUpdated, object: nil)
            }
        }
    }
    
    /**
     获取所有日记
     
     - Returns: 日记模型数组
     
     注意：
     直接返回内存缓存，性能高
     */
    func getAllDiaries() -> [DiaryModel] {
        // 使用同步队列访问，确保线程安全
        return queue.sync {
            return self.cachedDiaries
        }
    }
    
    /**
     获取特定日期的日记
     
     - Parameter date: 查询日期
     - Returns: 对应的日记模型（如果存在）
     */
    func getDiary(for date: Date) -> DiaryModel? {
        // 使用同步队列访问
        return queue.sync {
            return self.cachedDiaries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
    }
    
    /**
     加载图片文件
     
     - Parameter imageName: 图片文件名
     - Returns: UIImage 对象
     */
    // TODO: 这个方法没看懂
    func loadImage(named imageName: String) -> UIImage? {
        let imagePath = documentsDirectory.appendingPathComponent(imageName)
        return UIImage(contentsOfFile: imagePath.path)
    }
    
    /**
     删除日记
     
     - Parameter date: 要删除的日期
     
     操作：
     1. 查找并删除内存中的记录
     2. 删除关联的图片文件
     3. 异步写入 JSON 文件
     4. 发送通知
     */
    func deleteDiary(for date: Date) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 找到要删除的日记
            if let index = self.cachedDiaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                let diaryToDelete = self.cachedDiaries[index]
                
                // 删除关联的图片文件
                for imageName in diaryToDelete.imagePaths {
                    let imagePath = self.documentsDirectory.appendingPathComponent(imageName)
                    try? FileManager.default.removeItem(at: imagePath)
                }
                
                // 更新内存
                self.cachedDiaries.remove(at: index)
                
                // 异步写入磁盘
                self.saveDiariesToDisk()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .diaryUpdated, object: nil)
                }
            }
        }
    }
}
