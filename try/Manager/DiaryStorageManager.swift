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
    private init() {} // TODO: 为什么要留一个空的 init
    
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
    
    /**
     清理指定日期的旧图片文件
     
     - Parameter date: 要清理的日期
     
     用途：
     在保存新日记前，删除旧日记关联的图片文件，防止产生孤儿文件
     */
    func clearBuffer(date: Date) {
        if let oldDiary = getDiary(for: date) {
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
     4. 写入 JSON 文件
     5. 发送更新通知
     */
    func saveDiary(date: Date, score: Float, content: String, images: [UIImage]) {
        // 0. 清理该日期旧数据的图片文件，防止产生未引用的孤儿文件
        clearBuffer(date: date)
        
        // 1. 保存新图片到磁盘
        var savedImagePaths: [String] = []
        for image in images {
            let imageName = UUID().uuidString + ".jpg"
            let imagePath = documentsDirectory.appendingPathComponent(imageName)
            
            if let data = image.jpegData(compressionQuality: 1 {
                try? data.write(to: imagePath)
                // TODO: 为什么 try 后面要加问号
                savedImagePaths.append(imageName)
            }
        }
        
        // 2. 创建新的 Entry
        let newEntry = DiaryModel(date: date, score: score, content: content, imagePaths: savedImagePaths)
        
        // 3. 读取现有日记并更新
        var diaries = getAllDiaries()
        
        // 移除同一天的旧日记 (假设每天只能有一篇日记)
        diaries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        
        // 添加新日记
        diaries.append(newEntry)
        
        // 4. 写入文件
        if let data = try? JSONEncoder().encode(diaries) {
            try? data.write(to: dataFilePath)
            print("日记保存成功: \(newEntry)")
        } else {
            print("日记保存失败")
        }
        
        // 发送通知，告知数据更新
        NotificationCenter.default.post(name: .diaryUpdated, object: nil)
    }
    
    /**
     获取所有日记
     
     - Returns: 日记模型数组
     
     注意：
     每次调用都会从磁盘读取 JSON 文件
     */
    func getAllDiaries() -> [DiaryModel] {
        guard let data = try? Data(contentsOf: dataFilePath) else { return [] }
        guard let diaries = try? JSONDecoder().decode([DiaryModel].self, from: data) else { return [] }
        return diaries
    }
    
    /**
     获取特定日期的日记
     
     - Parameter date: 查询日期
     - Returns: 对应的日记模型（如果存在）
     */
    func getDiary(for date: Date) -> DiaryModel? {
        let diaries = getAllDiaries()
        return diaries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
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
     3. 更新 JSON 文件
     4. 发送通知
     */
    func deleteDiary(for date: Date) {
        var diaries = getAllDiaries()
        // 找到要删除的日记
        if let index = diaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            let diaryToDelete = diaries[index]
            
            // 删除关联的图片文件
            for imageName in diaryToDelete.imagePaths {
                let imagePath = documentsDirectory.appendingPathComponent(imageName)
                try? FileManager.default.removeItem(at: imagePath)
            }
            
            diaries.remove(at: index)
            
            // 保存更改
            if let data = try? JSONEncoder().encode(diaries) {
                try? data.write(to: dataFilePath)
            }
            
            NotificationCenter.default.post(name: .diaryUpdated, object: nil)
        }
    }
}
