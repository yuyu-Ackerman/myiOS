//
//  ImageDragGridConfiguration.swift
//  TESTDRAG
//
//  SDK 配置类：提供图片拖拽网格组件的所有可配置参数
//

import UIKit

/**
 * 图片拖拽网格组件配置类
 *
 * 提供完整的配置选项，支持链式配置和默认值
 * 使用 Builder 模式简化配置过程
 */
public class ImageDragGridConfiguration {
    
    // MARK: - 布局配置
    
    /// 最大图片数量
    public var maxImageCount: Int
    
    /// 网格列数
    public var gridColumns: Int
    
    /// 网格间距
    public var gridSpacing: CGFloat
    
    /// 容器边距
    public var containerMargin: CGFloat
    
    /// 容器顶部偏移
    public var containerTopOffset: CGFloat
    
    /// 图片圆角半径
    public var imageCornerRadius: CGFloat
    
    // MARK: - UI 样式配置
    
    /// 容器背景色
    public var containerBackgroundColor: UIColor
    
    /// 添加按钮背景色
    public var addButtonBackgroundColor: UIColor
    
    /// 添加按钮边框宽度
    public var addButtonBorderWidth: CGFloat
    
    /// 添加按钮图标大小
    public var addButtonIconSize: CGFloat
    
    /// 添加按钮边框颜色
      public var addButtonBorderColor: UIColor
    
    /// 删除按钮大小
    public var deleteButtonSize: CGFloat
    
    // MARK: - 动画配置
    
    /// 拖拽缩放比例
    public var dragScaleFactor: CGFloat
    
    /// 拖拽透明度
    public var dragAlpha: CGFloat
    
    /// 动画时长
    public var animationDuration: TimeInterval
    
    /// 弹性动画阻尼
    public var springDamping: CGFloat
    
    /// 长按触发时长
    public var longPressDuration: TimeInterval
    
    // MARK: - 图片加载配置
    
    /// 图片压缩质量
    public var imageCompressionQuality: CGFloat
    
    /// 最大图片尺寸
    public var maxImageSize: CGFloat
    
    /// 缓存图片数量
    public var imageCacheCountLimit: Int
    
    /// 缓存大小限制（字节）
    public var imageCacheTotalCostLimit: Int
    
    // MARK: - 功能配置
    
    /// 是否启用拖拽功能
    public var isDragEnabled: Bool
    
    /// 是否显示删除按钮
    public var showDeleteButton: Bool
    
    /// 是否显示加载指示器
    public var showLoadingIndicator: Bool
    
    /// 是否启用触觉反馈
    public var enableHapticFeedback: Bool
    
    /// 是否显示删除确认
    public var showDeleteConfirmation: Bool
    
    // MARK: - 文本配置
    
    /// 加载提示文本
    public var loadingMessage: String
    
    /// 删除确认标题
    public var deleteConfirmationTitle: String
    
    /// 删除确认消息
    public var deleteConfirmationMessage: String
    
    /// 相册权限提示
    public var photoLibraryUsageDescription: String
    
    // MARK: - 初始化
    
    /**
     * 私有初始化方法，防止外部直接创建实例
     */
    private init() {
        // 所有属性需要在这里显式初始化，但实际值由工厂方法设置
        self.maxImageCount = 0
        self.gridColumns = 0
        self.gridSpacing = 0
        self.containerMargin = 0
        self.containerTopOffset = 0
        self.imageCornerRadius = 0
        self.containerBackgroundColor = .clear
        self.addButtonBackgroundColor = .clear
        self.addButtonBorderColor = .clear
        self.addButtonBorderWidth = 0
        self.addButtonIconSize = 0
        self.deleteButtonSize = 0
        self.dragScaleFactor = 0
        self.dragAlpha = 0
        self.animationDuration = 0
        self.springDamping = 0
        self.longPressDuration = 0
        self.imageCompressionQuality = 0
        self.maxImageSize = 0
        self.imageCacheCountLimit = 0
        self.imageCacheTotalCostLimit = 0
        self.isDragEnabled = false
        self.showDeleteButton = false
        self.showLoadingIndicator = false
        self.enableHapticFeedback = false
        self.showDeleteConfirmation = false
        self.loadingMessage = ""
        self.deleteConfirmationTitle = ""
        self.deleteConfirmationMessage = ""
        self.photoLibraryUsageDescription = ""
    }
    
    /**
     * 创建默认配置
     */
    public static var `default`: ImageDragGridConfiguration {
        let config = ImageDragGridConfiguration()
        config.setupDefaultValues()
        return config
    }
    
    /**
     * 设置默认配置值
     */
    private func setupDefaultValues() {
        // 布局配置
        self.maxImageCount = 9
        self.gridColumns = 3
        self.gridSpacing = 3
        self.containerMargin = 35
        self.containerTopOffset = 0
        self.imageCornerRadius = 10
        
        // UI 样式配置
        self.containerBackgroundColor = .clear
        self.addButtonBackgroundColor = .white
        self.addButtonBorderWidth = 0
        self.addButtonBorderColor = .systemGray
//        self.addButtonIconSize = 43
      self.addButtonIconSize = 113
        self.deleteButtonSize = 22
        
        // 动画配置
        self.dragScaleFactor = 1.1
        self.dragAlpha = 0.8
        self.animationDuration = 0.3
        self.springDamping = 0.7
        self.longPressDuration = 0.5
        
        // 图片加载配置
        self.imageCompressionQuality = 0.8
        self.maxImageSize = 1024
        self.imageCacheCountLimit = 50
        self.imageCacheTotalCostLimit = 50 * 1024 * 1024
        
        // 功能配置
        self.isDragEnabled = true
        self.showDeleteButton = true
        self.showLoadingIndicator = true
        self.enableHapticFeedback = true
        self.showDeleteConfirmation = false
        
        // 文本配置
        self.loadingMessage = "正在加载图片..."
        self.deleteConfirmationTitle = "确认删除"
        self.deleteConfirmationMessage = "确定要删除这张图片吗？"
        self.photoLibraryUsageDescription = "需要访问您的相册来选择图片"
    }
    
    // MARK: - 链式配置方法
    
    @discardableResult
    public func maxImages(_ count: Int) -> ImageDragGridConfiguration {
        self.maxImageCount = count
        return self
    }
    
    @discardableResult
    public func columns(_ count: Int) -> ImageDragGridConfiguration {
        self.gridColumns = count
        return self
    }
    
    @discardableResult
    public func spacing(_ spacing: CGFloat) -> ImageDragGridConfiguration {
        self.gridSpacing = spacing
        return self
    }
    
    @discardableResult
    public func margin(_ margin: CGFloat) -> ImageDragGridConfiguration {
        self.containerMargin = margin
        return self
    }
    
    @discardableResult
    public func cornerRadius(_ radius: CGFloat) -> ImageDragGridConfiguration {
        self.imageCornerRadius = radius
        return self
    }
    
    @discardableResult
    public func enableDrag(_ enabled: Bool) -> ImageDragGridConfiguration {
        self.isDragEnabled = enabled
        return self
    }
    
    @discardableResult
    public func enableHaptic(_ enabled: Bool) -> ImageDragGridConfiguration {
        self.enableHapticFeedback = enabled
        return self
    }
    
    @discardableResult
    public func containerColor(_ color: UIColor) -> ImageDragGridConfiguration {
        self.containerBackgroundColor = color
        return self
    }
    
    @discardableResult
    public func addButtonColor(_ color: UIColor) -> ImageDragGridConfiguration {
        self.addButtonBackgroundColor = color
        return self
    }
    
    @discardableResult
    public func addButtonBorderColor(_ color: UIColor) -> ImageDragGridConfiguration {
        self.addButtonBorderColor = color
        return self
    }
    
    // MARK: - 预设配置
    
    /**
     * 紧凑布局配置（4x4网格，较小间距）
     */
    public static var compact: ImageDragGridConfiguration {
        let config = ImageDragGridConfiguration()
        config.setupDefaultValues()
        config.setupCompactValues()
        return config
    }
    
    /**
     * 大图布局配置（2x2网格，较大间距）
     */
    public static var large: ImageDragGridConfiguration {
        let config = ImageDragGridConfiguration()
        config.setupDefaultValues()
        config.setupLargeValues()
        return config
    }
    
    /**
     * 单行布局配置（横向滚动）
     */
    public static var singleRow: ImageDragGridConfiguration {
        let config = ImageDragGridConfiguration()
        config.setupDefaultValues()
        config.setupSingleRowValues()
        return config
    }
    
    // MARK: - 私有预设配置方法
    
    /**
     * 设置紧凑布局配置值
     */
    private func setupCompactValues() {
        self.maxImageCount = 16
        self.gridColumns = 4
        self.gridSpacing = 5
        self.containerMargin = 10
        self.imageCornerRadius = 8
    }
    
    /**
     * 设置大图布局配置值
     */
    private func setupLargeValues() {
        self.maxImageCount = 4
        self.gridColumns = 2
        self.gridSpacing = 15
        self.containerMargin = 30
        self.imageCornerRadius = 16
    }
    
    /**
     * 设置单行布局配置值
     */
    private func setupSingleRowValues() {
        self.maxImageCount = 5
        self.gridColumns = 5
        self.gridSpacing = 8
        self.containerMargin = 15
        self.imageCornerRadius = 10
    }
}
