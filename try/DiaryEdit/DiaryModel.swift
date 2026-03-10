//
//  DiaryEditModel.swift
//  try
//
//  Created by 小余 on 2026/2/18.
//

import UIKit
import Foundation

/**
 日记数据模型
 
 对应 JSON 存储结构
 */
struct DiaryModel: Codable {
    /// 唯一标识符
    var id: String
    /// 日记日期
    var date: Date
    /// 评分 (0.0 - 5.0)
    var score: Float // 评分是 Float
    /// 日记文本内容
    var content: String
    /// 图片文件名列表 (仅存储文件名，不存路径)
    var imagePaths: [String] // 图片文件名列表
    
    // MARK: - Initialization
    
    /**
     自定义初始化
     
     - Parameter id: 唯一ID (默认 UUID)
     - Parameter date: 日期
     - Parameter score: 评分
     - Parameter content: 内容
     - Parameter imagePaths: 图片路径列表
     */
    init(id: String = UUID().uuidString, date: Date, score: Float, content: String, imagePaths: [String]) {
        self.id = id
        self.date = date
        self.score = score
        self.content = content
        self.imagePaths = imagePaths
    }
}
