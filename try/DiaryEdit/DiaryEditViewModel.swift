//
//  DiaryEditViewModel.swift
//  try
//
//  Created by 小余 on 2026/2/18.
//

import UIKit

class DiaryEditViewModel {
    // MARK: - Properties
    
    /// 评分 (0-5)
    var starRate: Float = 0
    
    /// 日记内容
    var description: String = ""
    
    /// 图片列表 (用于暂存编辑时的图片)
    var pictures: [UIImage] = []
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Helper Methods
    
    func reset() {
        starRate = 0
        description = ""
        pictures = []
    }
}
