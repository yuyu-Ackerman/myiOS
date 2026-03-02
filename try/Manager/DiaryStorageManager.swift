import Foundation
import UIKit

extension Notification.Name {
    static let diaryUpdated = Notification.Name("DiaryUpdated")
}

// 日记模型


class DiaryStorageManager {
    static let shared = DiaryStorageManager() // TODO: 这是什么写法
    
    private init() {} // TODO: 为什么要留一个空的 init
    
    /// 获取 Documents 目录路径
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // TODO: 可以深入了解一下相关知识
    }
    
    /// 获取日记数据文件的路径
    private var dataFilePath: URL {
        return documentsDirectory.appendingPathComponent("diaries.json")
    }
    
    func clearBuffer(date: Date) {
        if let oldDiary = getDiary(for: date) {
            for path in oldDiary.imagePaths {
                let fullPath = documentsDirectory.appendingPathComponent(path)
                try? FileManager.default.removeItem(at: fullPath)
            }
        }
    }
    
    /// 保存日记
    // images: 包含 UIImage 对象的数组
    func saveDiary(date: Date, score: Float, content: String, images: [UIImage]) {
        // 0. 清理该日期旧数据的图片文件，防止产生未引用的孤儿文件
        clearBuffer(date: date)
        
        // 1. 保存新图片到磁盘
        var savedImagePaths: [String] = []
        for image in images {
            let imageName = UUID().uuidString + ".jpg"
            let imagePath = documentsDirectory.appendingPathComponent(imageName)
            
            if let data = image.pngData() {
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
    
    // 获取所有日记
    func getAllDiaries() -> [DiaryModel] {
        guard let data = try? Data(contentsOf: dataFilePath) else { return [] }
        guard let diaries = try? JSONDecoder().decode([DiaryModel].self, from: data) else { return [] }
        return diaries
    }
    
    // 获取特定日期的日记
    func getDiary(for date: Date) -> DiaryModel? {
        let diaries = getAllDiaries()
        return diaries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // 加载图片
    // TODO: 这个方法没看懂
    func loadImage(named imageName: String) -> UIImage? {
        let imagePath = documentsDirectory.appendingPathComponent(imageName)
        return UIImage(contentsOfFile: imagePath.path)
    }
    
    // 删除日记
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
