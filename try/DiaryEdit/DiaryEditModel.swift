//
//  DiaryEditModel.swift
//  try
//
//  Created by 小余 on 2026/2/18.
//

import UIKit
import Foundation

struct DiaryEntry: Codable {
    var id: String
    var date: Date
    var score: Float // 评分是 Float
    var content: String
    var imagePaths: [String] // 图片文件名列表
    
    // 自定义初始化
    init(id: String = UUID().uuidString, date: Date, score: Float, content: String, imagePaths: [String]) {
        self.id = id
        self.date = date
        self.score = score
        self.content = content
        self.imagePaths = imagePaths
    }
}
