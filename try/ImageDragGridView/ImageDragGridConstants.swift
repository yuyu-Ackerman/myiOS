//
//  Constants.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit

/**
 * 应用配置常量
 *
 * 集中管理所有魔法数字、配置参数和常量值
 * 提高代码可维护性和可读性
 */
struct ImageDragGridConstants {
    
    // MARK: - 图片网格配置
    struct ImageGrid {
        /// 最大允许的图片数量
        static let maxImageCount = 9
        
        /// 每行显示的图片数量
        static let itemsPerRow = 3
        
        /// 图片之间的间距
        static let spacing: CGFloat = 3
        
        /// 容器视图边距
        static let containerMargin: CGFloat = 0
        
        /// 容器视图顶部偏移
        static let containerTopOffset: CGFloat = 50
        
        /// 图片圆角半径
        static let imageCornerRadius: CGFloat = 8
        
        /// 添加按钮边框宽度
        static let addButtonBorderWidth: CGFloat = 2
    }
    
    // MARK: - 拖拽手势配置
    struct DragGesture {
        /// 长按手势最小持续时间
        static let longPressMinimumDuration: TimeInterval = 0.5
        
        /// 拖拽时的缩放比例（1.2 表示放大到原来的 1.2 倍）
        static let dragScale: CGFloat = 1.2
        
        /// 拖拽时的透明度
        static let dragAlpha: CGFloat = 0.9
        
        /// 阴影偏移
        static let shadowOffset = CGSize(width: 0, height: 5)
        
        /// 阴影透明度
        static let shadowOpacity: Float = 0.3
        
        /// 阴影半径
        static let shadowRadius: CGFloat = 10
    }
    
    // MARK: - 动画配置
    struct Animation {
        /// 标准动画持续时间
        static let standardDuration: TimeInterval = 0.3
        
        /// 快速动画持续时间
        static let quickDuration: TimeInterval = 0.2
        
        /// 长动画持续时间
        static let longDuration: TimeInterval = 0.5
        
        /// 删除动画缩放比例
        static let deleteScale: CGFloat = 0.8
        
        /// 弹簧动画阻尼比
        static let springDamping: CGFloat = 0.7
        
        /// 弹簧动画初始速度
        static let springVelocity: CGFloat = 0
    }
    
    // MARK: - UI配置
    struct UI {
        /// 添加按钮图标尺寸
        static let addButtonIconSize: CGFloat = 22
        
        /// 图标粗细等级
        static let iconWeight: UIImage.SymbolWeight = .medium
        
        /// 默认项目尺寸（当计算失败时使用）
        static let defaultItemSize: CGFloat = 113
        
        /// 加载指示器尺寸
        static let loadingIndicatorSize: CGFloat = 40
    }
    
    // MARK: - 颜色配置
    struct Colors {
        /// 主要按钮颜色
        static let primaryButton = UIColor.systemBlue
        
        /// 容器背景颜色
        static let containerBackground = UIColor.systemGray6
        
        /// 阴影颜色
        static let shadowColor = UIColor.black.cgColor
        
        /// 错误提示颜色
        static let errorColor = UIColor.systemRed
        
        /// 成功提示颜色
        static let successColor = UIColor.systemGreen
    }
    
    // MARK: - 文本配置
    struct Text {
        /// 图片加载失败提示
        static let imageLoadFailedMessage = "图片加载失败，请重试"
        
        /// 删除确认标题
        static let deleteConfirmTitle = "删除图片"
        
        /// 删除确认消息
        static let deleteConfirmMessage = "确定要删除这张图片吗？"
        
        /// 确认按钮文本
        static let confirmButtonTitle = "删除"
        
        /// 取消按钮文本
        static let cancelButtonTitle = "取消"
        
        /// 加载中提示
        static let loadingMessage = "正在加载图片..."
        
        /// 相册权限描述
        static let photoLibraryUsageDescription = "需要访问您的相册来选择图片"
    }
    
    // MARK: - 性能配置
    struct Performance {
        /// 图片压缩质量 (0.0 - 1.0)
        static let imageCompressionQuality: CGFloat = 0.8
        
        /// 最大图片尺寸
        static let maxImageSize: CGFloat = 1024
        
        /// 布局缓存失效时间（秒）
        static let layoutCacheExpiration: TimeInterval = 30
    }
}
