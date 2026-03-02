//
//  DiaryEditViewModel.swift
//  try
//
//  Created by 小余 on 2026/2/18.
//

import UIKit

class DiaryEditViewModel {
    
    /// 持有的 Model
    private var model: DiaryModel
    
    /// 当前编辑的图片 (Model 中只存路径，这里存实际图片对象)
    private var currentImages: [UIImage] = []
    
// MARK: - Initialization
    
    init() {
        // 默认初始化为当天的空日记
        self.model = DiaryModel(date: Date(), score: 0, content: "", imagePaths: [])
    }
    
// MARK: Public Methods
    /// 根据日期加载日记数据
    func loadData(for date: Date) {
        if let existingDiary = DiaryStorageManager.shared.getDiary(for: date) {
            self.model = existingDiary
            // 加载图片
            self.currentImages = existingDiary.imagePaths.compactMap {
                DiaryStorageManager.shared.loadImage(named: $0)
            }
        } else {
            // 如果当天没有日记，创建一个新的空白 Model
            self.model = DiaryModel(date: date, score: 0, content: "", imagePaths: [])
            self.currentImages = []
        }
    }
    
    /// 保存日记到存储
    func save() {
        DiaryStorageManager.shared.saveDiary(
            date: model.date,
            score: model.score,
            content: model.content,
            images: currentImages
        )
    }
}

// MARK: Getters
extension DiaryEditViewModel {
   
    func getScore() -> Float {
        return model.score
    }
    
    func getContent() -> String {
        return model.content
    }
    
    func getImages() -> [UIImage] {
        print("图片的数量：\(currentImages.count)")
        return currentImages
    }
    
    func getDate() -> Date {
        return model.date
    }
}

// MARK: Setters
extension DiaryEditViewModel {
    func setScore(_ score: Float) {
        model.score = score
    }
    
    func setContent(_ content: String) {
        model.content = content
    }
    
    func setImages(_ images: [UIImage]) {
        self.currentImages = images
    }
}
