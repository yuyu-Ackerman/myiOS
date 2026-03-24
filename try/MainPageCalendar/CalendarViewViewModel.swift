//
//  CalendarViewViewModel.swift
//  try
//
//  Created by 小余 on 2026/3/11.
//

import UIKit

class CalendarViewViewModel {
    // MARK: - Properties
    
    /// 持有的 Model (Source of Truth)
    private var model: DiaryModel
    
    /// 当前编辑的图片 (Model 中只存路径，这里存实际图片对象)
    private var currentImages: [UIImage] = []
    
    // MARK: - Initialization
    
    init() {
        // 默认初始化为当天的空日记
        self.model = DiaryModel(date: Date(), score: 0, content: "", imagePaths: [])
    }
    
    // MARK: - Public Methods
    
    /**
     根据日期加载日记数据
     
     - Parameter date: 要加载的日期
     
     逻辑：
     1. 尝试从存储中获取现有日记
     2. 如果存在，加载数据和图片
     3. 如果不存在，创建新的空白 Model
     */
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
}

// MARK: - Getters

extension CalendarViewViewModel {
   
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
