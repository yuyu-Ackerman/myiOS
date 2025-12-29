//
//  ImageGridManager.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit

/**
 * 图片网格管理器
 *
 * 专门负责处理图片网格布局的计算、位置管理和动画
 * 提供高性能的布局缓存和优化的位置计算
 */
class ImageGridManager {
    
    // MARK: - Properties
    
    // TODO: 意欲何为
    /// 容器视图引用
    private weak var containerView: UIView?
    
    /// 布局缓存
    private var layoutCache: LayoutCache?
    
    // TODO: ？？
    /// 布局缓存时间戳
    private var cacheTimestamp: Date = Date()
    
    /// 网格配置
    private var gridColumns: Int = ImageDragGridConstants.ImageGrid.itemsPerRow
    private var gridSpacing: CGFloat = ImageDragGridConstants.ImageGrid.spacing
    private var cornerRadius: CGFloat = ImageDragGridConstants.ImageGrid.imageCornerRadius
    
    // MARK: - Layout Cache Structure
    
    /// 布局缓存结构
    private struct LayoutCache {
        let containerSize: CGSize
        let itemSize: CGFloat
        let positions: [CGPoint]
        
        func isValid(for currentSize: CGSize) -> Bool {
            return containerSize == currentSize
        }
    }
    
    // MARK: - Initialization
    
    init(containerView: UIView) {
        self.containerView = containerView
    }
    
    // MARK: - Public Methods
    
    /**
     * 计算单个图片项的尺寸
     *
     * @return 计算得出的图片尺寸，如果计算失败返回默认尺寸
     */
    func calculateItemSize() -> CGFloat {
        guard let containerView = containerView else {
            return ImageDragGridConstants.UI.defaultItemSize
        }
        
        let totalSpacing = gridSpacing * CGFloat(gridColumns - 1)
      let availableWidth = containerView.bounds.width - totalSpacing - ImageDragGridConstants.ImageGrid.containerMargin * 2
        let itemSize = availableWidth / CGFloat(gridColumns)
        
        return itemSize > 0 ? itemSize : ImageDragGridConstants.UI.defaultItemSize
    }
    
    /**
     * 获取指定索引位置的坐标
     *
     * @param index 图片索引
     * @return 图片应该放置的坐标点
     */
    func getPosition(for index: Int) -> CGPoint {
        let itemSize = calculateItemSize()
        let row = index / gridColumns
        let column = index % gridColumns
        
        let x = CGFloat(column) * (itemSize + gridSpacing)
        let y = CGFloat(row) * (itemSize + gridSpacing)
        
        return CGPoint(x: x, y: y)
    }
    
    /**
     * 获取指定索引位置的frame
     *
     * @param index 图片索引
     * @return 图片的完整frame
     */
    func getFrame(for index: Int) -> CGRect {
        let position = getPosition(for: index)
        let itemSize = calculateItemSize()
        
        return CGRect(x: position.x, y: position.y, width: itemSize, height: itemSize)
    }
    
    /**
     * 根据拖拽位置计算目标索引
     *
     * @param point 拖拽点的坐标
     * @param maxCount 当前图片的最大数量
     * @return 目标位置的索引，如果无效则返回nil
     */
    func getTargetIndex(for point: CGPoint, maxCount: Int) -> Int? {
        let itemSize = calculateItemSize()
        let totalSize = itemSize + gridSpacing
        
        // 计算对应的列和行
        let column = Int(point.x / totalSize)
        let row = Int(point.y / totalSize)
        
        // 验证位置有效性
        guard column >= 0, 
              column < gridColumns, 
              row >= 0 else { 
            return nil 
        }
        
        // 转换为一维索引
        let index = row * gridColumns + column
        return index < maxCount ? index : nil
    }
    
    /**
     * 使用缓存获取所有图片位置
     *
     * @param count 图片数量
     * @return 所有图片的位置数组
     */
    // TODO: 了解下这个，这里为什么要这么做
    func getCachedPositions(for count: Int) -> [CGPoint] {
        guard let containerView = containerView else { return [] }
        
        // 检查缓存有效性
        if let cache = layoutCache,
           cache.isValid(for: containerView.bounds.size),
           !isCacheExpired() {
            return Array(cache.positions.prefix(count))
        }
        
        // 重新计算并缓存
        let positions = (0..<count).map { getPosition(for: $0) }
        
        layoutCache = LayoutCache(
            containerSize: containerView.bounds.size,
            itemSize: calculateItemSize(),
            positions: positions
        )
        cacheTimestamp = Date()
        
        return positions
    }
    
    /**
     * 批量更新图片位置（带动画）
     *
     * @param imageViews 要更新位置的图片视图数组
     * @param excludedView 需要排除的视图（通常是正在拖拽的视图）
     * @param animated 是否使用动画
     * @param completion 动画完成回调
     */
    func updatePositions(
        for imageViews: [UIImageView],
        excluding excludedView: UIImageView? = nil, // 正在拖拽的 imageView
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let itemSize = calculateItemSize()
        
        let animations = {
            for (index, imageView) in imageViews.enumerated() {
                guard imageView != excludedView else { continue }
                
                let position = self.getPosition(for: index)
                imageView.frame = CGRect(x: position.x, y: position.y, width: itemSize, height: itemSize)
            }
        }
        
        if animated {
            UIView.animate(
                withDuration: ImageDragGridConstants.Animation.standardDuration,
                delay: 0,
                usingSpringWithDamping: ImageDragGridConstants.Animation.springDamping,
                initialSpringVelocity: ImageDragGridConstants.Animation.springVelocity,
                options: .curveEaseInOut,
                animations: animations,
                completion: { _ in completion?() }
            )
        } else {
            animations()
            completion?()
        }
    }
    
    /**
     * 获取添加按钮的位置和尺寸
     *
     * @param currentImageCount 当前图片数量
     * @return 添加按钮的frame，如果已达到最大数量返回nil
     */
    func getAddButtonFrame(for currentImageCount: Int) -> CGRect? {
        guard currentImageCount < ImageDragGridConstants.ImageGrid.maxImageCount else {
            return nil
        }
        
        return getFrame(for: currentImageCount)
    }
    
    /**
     * 更新配置参数
     *
     * @param columns 网格列数
     * @param spacing 网格间距
     * @param cornerRadius 圆角半径
     */
    func updateConfiguration(columns: Int, spacing: CGFloat, cornerRadius: CGFloat) {
        self.gridColumns = columns
        self.gridSpacing = spacing
        self.cornerRadius = cornerRadius
        // 清除缓存
        clearCache()
    }
    
    /**
     * 检查指定点是否在有效的网格区域内
     *
     * @param point 要检查的点
     * @return 是否在有效区域内
     */
    func isPointInValidGridArea(_ point: CGPoint) -> Bool {
        guard let containerView = containerView else { return false }
        
        let containerBounds = containerView.bounds
        return containerBounds.contains(point)
    }
    
    /**
     * 计算网格的总高度
     *
     * @param itemCount 项目数量
     * @return 网格总高度
     */
    func calculateGridHeight(for itemCount: Int) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        
        let itemSize = calculateItemSize()
        let rows = (itemCount - 1) / gridColumns + 1
        
        return CGFloat(rows) * itemSize + CGFloat(rows - 1) * gridSpacing
    }
    
    // MARK: - Private Methods
    
    /**
     * 检查缓存是否过期
     *
     * @return 缓存是否过期
     */
    private func isCacheExpired() -> Bool {
        return Date().timeIntervalSince(cacheTimestamp) > ImageDragGridConstants.Performance.layoutCacheExpiration
    }
    
    /**
     * 清除布局缓存
     */
    func clearCache() {
        layoutCache = nil
        cacheTimestamp = Date()
    }
}
