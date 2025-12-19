//
//  StarRateConfigration.swift
//  practice
//
//  Created by 小余 on 2025/12/18.
//
import UIKit
/// 不同的评分颗粒度：全星/半星/无限制
enum StarType {
    case complete
    case half
    case unlimited
}

/// StarRateView 星级评分组件配置类
class StarRateConfigration {
    
    let starType: StarType
    
    let starCount: Int
    
    let starSpace: CGFloat
    /// 最少/默认选择的星级数目
    let leastCount: Float
    /// 是否可以拖拽选择
    let isPanable: Bool
    /// 是否可以编辑（可以选择星级/仅展示）
    let isEditable: Bool
    
    init(starType: StarType = .half,
         starCount: Int = 5,
         leastCount: Float = 2,
         starSpace: CGFloat = 10,
         isPanable: Bool = true,
         isEditable: Bool = true) {
        self.starType = starType
        self.starCount = starCount
        self.leastCount = leastCount
        self.starSpace = starSpace
        self.isPanable = isPanable
        self.isEditable = isEditable
    }
}
