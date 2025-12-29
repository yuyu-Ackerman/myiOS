//
//  DragGestureHandler.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit

/**
 * 拖拽手势处理器协议
 *
 * 定义拖拽操作的回调接口
 */
protocol DragGestureHandlerDelegate: AnyObject {
    func dragDidBegin(imageView: DraggableImageView, at index: Int)
    func dragDidMove(from sourceIndex: Int, to targetIndex: Int)
    func dragDidEnd(imageView: DraggableImageView)
    func shouldAllowDrag(for imageView: DraggableImageView) -> Bool
}

/**
 * 拖拽手势处理器
 *
 * 专门负责处理图片拖拽的所有逻辑，包括手势识别、视觉反馈和位置计算
 * 提供清晰的回调接口和状态管理
 */
// TODO: NSObject
class DragGestureHandler: NSObject {
    
    // MARK: - Properties
    
    /// 代理对象
    weak var delegate: DragGestureHandlerDelegate?
    
    /// 网格管理器引用
    private let gridManager: ImageGridManager
    
    // TODO: weak 引用
    /// 容器视图引用
    private weak var containerView: UIView?
    
    /// 父 ScrollView 引用（用于处理手势冲突）
    weak var parentScrollView: UIScrollView?
    
    /// 当前拖拽状态
    private var dragState: DragState = .idle
    
    /// 是否启用拖拽功能
    var isEnabled: Bool = true
    
    /// 拖拽状态枚举
    private enum DragState {
        case idle
        case dragging(imageView: DraggableImageView, originalIndex: Int, originalPosition: CGPoint)
        
        var isDragging: Bool {
            switch self {
            case .idle:
                return false
            case .dragging:
                return true
            }
        }
        
        var draggedView: DraggableImageView? {
            switch self {
            case .idle:
                return nil
            case .dragging(let imageView, _, _):
                return imageView
            }
        }
    }
    
    // MARK: - Initialization
    
    init(gridManager: ImageGridManager, containerView: UIView) {
        self.gridManager = gridManager
        self.containerView = containerView
    }
    
    // MARK: - Public Methods
    
    /**
     * 为图片视图添加拖拽手势
     *
     * @param imageView 要添加手势的图片视图
     */
    func addDragGesture(to imageView: DraggableImageView) {
        let longPressGesture = UILongPressGestureRecognizer(
            target: self, 
            action: #selector(handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = ImageDragGridConstants.DragGesture.longPressMinimumDuration
        longPressGesture.delegate = self
        
        imageView.addGestureRecognizer(longPressGesture)
        imageView.dragGestureHandler = self
    }
    
    /**
     * 移除图片视图的拖拽手势
     *
     * @param imageView 要移除手势的图片视图
     */
    func removeDragGesture(from imageView: DraggableImageView) {
        imageView.gestureRecognizers?.forEach { gesture in
            if gesture is UILongPressGestureRecognizer {
                imageView.removeGestureRecognizer(gesture)
            }
        }
        imageView.dragGestureHandler = nil
    }
    
    /**
     * 检查当前是否有视图正在拖拽
     *
     * @return 是否正在拖拽
     */
    func isDragging() -> Bool {
        return dragState.isDragging
    }
    
    /**
     * 获取当前正在拖拽的视图
     *
     * @return 正在拖拽的视图，如果没有则返回nil
     */
    func getCurrentDraggedView() -> DraggableImageView? {
        return dragState.draggedView
    }
    
    /**
     * 强制结束当前拖拽操作
     */
    func cancelCurrentDrag() {
        guard case .dragging(let imageView, _, let originalPosition) = dragState else { return }
        
        // 恢复到原始位置和状态
        UIView.animate(withDuration: ImageDragGridConstants.Animation.standardDuration) {
            imageView.center = originalPosition
            self.resetDragVisualEffects(for: imageView)
        } completion: { _ in
            // 恢复父 ScrollView 的滚动
            self.parentScrollView?.isScrollEnabled = true
            
            self.dragState = .idle
            self.delegate?.dragDidEnd(imageView: imageView)
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard isEnabled,
              let imageView = gesture.view as? DraggableImageView,
              let containerView = containerView else { return }
        
        let location = gesture.location(in: containerView)
        
        switch gesture.state {
        case .began:
            handleDragBegan(imageView: imageView, at: location)
            
        case .changed:
            handleDragChanged(imageView: imageView, at: location)
            
        case .ended, .cancelled, .failed:
            handleDragEnded(imageView: imageView)
            
        default:
            break
        }
    }
    
    // MARK: - Drag State Handling
    
    private func handleDragBegan(imageView: DraggableImageView, at location: CGPoint) {
        // 检查是否允许拖拽
        guard delegate?.shouldAllowDrag(for: imageView) != false else { return }
        
        let originalPosition = imageView.center
        let originalIndex = imageView.tag
        
        // 更新拖拽状态
        dragState = .dragging(
            imageView: imageView, 
            originalIndex: originalIndex, 
            originalPosition: originalPosition
        )
        
        // 禁用父 ScrollView 的滚动，防止手势冲突
        parentScrollView?.isScrollEnabled = false
        
        // 应用拖拽视觉效果
        applyDragVisualEffects(to: imageView)
        
        // 确保拖拽的视图在最前面
        containerView?.bringSubviewToFront(imageView)
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 通知代理
        delegate?.dragDidBegin(imageView: imageView, at: originalIndex)
    }
    
    private func handleDragChanged(imageView: DraggableImageView, at location: CGPoint) {
        guard case .dragging(_, let originalIndex, _) = dragState else { return }
        
        // 更新图片位置
        imageView.center = location
        
        // 检查目标位置
        if let targetIndex = gridManager.getTargetIndex(for: location, maxCount: Int.max) {
            if targetIndex != originalIndex && targetIndex != imageView.tag {
                // 通知代理进行位置交换
                delegate?.dragDidMove(from: imageView.tag, to: targetIndex)
                
                // TODO: 为什么要更新
                // 更新拖拽状态中的当前索引
                if case .dragging(let draggedView, let origIndex, let origPosition) = dragState {
                    dragState = .dragging(
                        imageView: draggedView, 
                        originalIndex: origIndex, 
                        originalPosition: origPosition
                    )
                }
                
                // 轻微的触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func handleDragEnded(imageView: DraggableImageView) {
        guard case .dragging(_, _, _) = dragState else { return }
        
        // 计算最终位置
        let finalFrame = gridManager.getFrame(for: imageView.tag)
        
        // 执行归位动画
        UIView.animate(
            withDuration: ImageDragGridConstants.Animation.standardDuration,
            delay: 0,
            usingSpringWithDamping: ImageDragGridConstants.Animation.springDamping,
            initialSpringVelocity: ImageDragGridConstants.Animation.springVelocity,
            animations: {
                imageView.frame = finalFrame
                self.resetDragVisualEffects(for: imageView)
            },
            completion: { _ in
                // 恢复父 ScrollView 的滚动
                self.parentScrollView?.isScrollEnabled = true
                
                // 重置拖拽状态
                self.dragState = .idle
                
                // 通知代理
                self.delegate?.dragDidEnd(imageView: imageView)
            }
        )
    }
    
    // MARK: - Visual Effects
    
    /**
     * 应用拖拽视觉效果
     *
     * @param imageView 要应用效果的图片视图
     */
    private func applyDragVisualEffects(to imageView: UIImageView) {
        // 保持裁剪以防止图片内容溢出
        // 重要：始终保持 clipsToBounds = true
        
        // TODO: masksToBounds 和 clipsToBounds
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        
        UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration) {
            // 应用缩放变换（1.2 倍）
            // transform 会放大整个视图，包括其边框
            imageView.transform = CGAffineTransform(
                scaleX: ImageDragGridConstants.DragGesture.dragScale, 
                y: ImageDragGridConstants.DragGesture.dragScale
            )
            imageView.alpha = ImageDragGridConstants.DragGesture.dragAlpha
            
            // 注意：由于 masksToBounds = true，阴影效果不会显示
            // 如果需要阴影，建议使用父容器视图或其他方案
        }
    }
    
    /**
     * 重置拖拽视觉效果
     *
     * @param imageView 要重置效果的图片视图
     */
    private func resetDragVisualEffects(for imageView: UIImageView) {
        // 恢复原始大小和外观
        imageView.transform = .identity
        imageView.alpha = 1.0
        
        // 确保裁剪设置正确
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
    }
}

// MARK: - UIGestureRecognizerDelegate

extension DragGestureHandler: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer, 
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // 避免与点击手势冲突
        return !(otherGestureRecognizer is UITapGestureRecognizer)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只有在非拖拽状态下才允许开始新的拖拽
        return !dragState.isDragging
    }
}
