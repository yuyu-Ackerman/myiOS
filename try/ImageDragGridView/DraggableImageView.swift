//
//  DraggableImageView.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit
import SnapKit

/**
 * 可拖拽图片视图
 *
 * 增强版的图片视图，支持拖拽操作、状态管理和视觉反馈
 * 提供完整的拖拽生命周期管理和用户交互优化
 */
class DraggableImageView: UIImageView {
    
    // MARK: - Properties
    //TODO: 为什么要加 weak，
    /// 拖拽手势处理器引用
    weak var dragGestureHandler: DragGestureHandler?
    
    //TODO: 这一句什么意思
    // private(set)：对外只读、对内可写，保证状态只能由内部逻辑修改，避免外部篡改
    // 一旦开关状态变了，就自动触发 “外观更新”
    /// 拖拽状态
    private(set) var dragState: DragState = .idle {
        didSet {
            updateAppearanceForState()
        }
    }
    
    /// 原始图片索引（用于恢复位置）
    private(set) var originalIndex: Int = 0
    
    /// 是否启用拖拽功能
    var isDragEnabled: Bool = true {
        didSet {
            updateInteractionState()
        }
    }
    
    /// 是否启用删除功能
    var isDeleteEnabled: Bool = true
    
    /// 是否显示删除按钮（保留接口以兼容）
    var showsDeleteButton: Bool = true {
        didSet {
            updateDeleteButtonVisibility()
        }
    }
    
    /// 删除回调闭包
    var onDelete: ((DraggableImageView) -> Void)?
    
    /// 点击回调闭包
    var onTap: ((DraggableImageView) -> Void)?
    
    /// 删除按钮
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "picture_delete"), for: .normal)
        
        // 添加点击事件
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // 初始状态隐藏，由 showsDeleteButton 属性控制显示
        button.isHidden = true
        
        return button
    }()
    
    /// 拖拽状态枚举
    enum DragState {
        /// 空闲状态
        case idle
        /// 拖拽中状态
        case dragging
        /// 选中状态
        case highlighted
        
        var isInteractive: Bool {
            switch self {
            case .idle, .highlighted:
                return true
            case .dragging:
                return false
            }
        }
    }
    
    //TODO: 前2个 image 分别是什么作用
    // 在创建视图和添加图片时都调用 setupImageView（）？
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        setupImageView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupImageView()
    }
    
    // MARK: - Setup
    
    private func setupImageView() {
        // 设置外观、基本属性
        setupBasicProperties()
        // 添加删除按钮到视图、约束
        setupDeleteButton()
        // 设置点击手势
        setupGestures()
        // 无障碍辅助功能
        setupAccessibility()
    }
    
    private func setupBasicProperties() {
        contentMode = .scaleAspectFill // TODO: 不同的模式有什么区别
        clipsToBounds = true
        layer.cornerRadius = ImageDragGridConstants.ImageGrid.imageCornerRadius
        isUserInteractionEnabled = true
        
        // 设置默认的边框样式
        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
    }
    
    /// 添加删除按钮到视图、约束
    private func setupDeleteButton() {
        // 添加到视图
        addSubview(deleteButton)
        
        // 设置约束
        deleteButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }
        
        // 确保删除按钮在最上层
        bringSubviewToFront(deleteButton)
        
        // 设置初始可见性：有一个从小变大的动画效果
        updateDeleteButtonVisibility()
    }
    
    private func setupGestures() {
        // 点击手势用于删除
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // TODO: 这个函数是干什么的
    /// 无障碍辅助功能
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = [.image, .button]
        updateAccessibilityHint()
    }
    
    private func updateAccessibilityHint() {
        if isDragEnabled && isDeleteEnabled && showsDeleteButton { // 如果：可以拖拽、可以删、有删除按钮
            accessibilityHint = "双击删除图片，长按拖拽排序"
        } else if isDeleteEnabled && showsDeleteButton {// 如果：可以删、有删除按钮
            accessibilityHint = "双击删除图片"
        } else if isDragEnabled { // 如果：可以拖拽
            accessibilityHint = "长按拖拽排序"
        } else { // 什么都没有
            accessibilityHint = "图片"
        }
    }
    
    // MARK: - Public Methods
    
    /**
     * 设置图片索引
     *
     * @param index 图片在网格中的索引
     */
    func setIndex(_ index: Int) {
        tag = index
        originalIndex = index
        accessibilityLabel = "图片 \(index + 1)"
    }
    
    /**
     * 设置拖拽状态
     *
     * @param state 新的拖拽状态
     */
    func setDragState(_ state: DragState) {
        guard dragState != state else { return }
        dragState = state
    }
    
    /**
     * 开始拖拽动画
     */
    func beginDragAnimation() {
        setDragState(.dragging)
        
        UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration) {
            self.transform = CGAffineTransform(
                scaleX: ImageDragGridConstants.DragGesture.dragScale,
                y: ImageDragGridConstants.DragGesture.dragScale
            )
            self.alpha = ImageDragGridConstants.DragGesture.dragAlpha
            // 拖拽时隐藏删除按钮
            self.deleteButton.alpha = 0
        }
        
        applyDragShadow()
    }
    
    /**
     * 结束拖拽动画
     */
    func endDragAnimation(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: ImageDragGridConstants.Animation.standardDuration,
            delay: 0,
            usingSpringWithDamping: ImageDragGridConstants.Animation.springDamping,
            initialSpringVelocity: ImageDragGridConstants.Animation.springVelocity,
            animations: {
                self.transform = .identity
                self.alpha = 1.0
                // 恢复删除按钮显示
                if self.showsDeleteButton && self.isDeleteEnabled {
                    self.deleteButton.alpha = 1
                }
            },
            completion: { _ in
                self.setDragState(.idle)
                self.removeDragShadow()
                completion?() // 执行外部传入的回调闭包
            }
        )
    }
    
    /**
     * 执行删除动画
     */
    func performDeleteAnimation(completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: ImageDragGridConstants.Animation.quickDuration,
            animations: {
                self.transform = CGAffineTransform(
                    scaleX: ImageDragGridConstants.Animation.deleteScale,
                    y: ImageDragGridConstants.Animation.deleteScale
                )
                self.alpha = 0
            },
            completion: { _ in
                completion()
            }
        )
    }
    
    /**
     * 显示高亮状态（用于视觉反馈）
     */
    func showHighlight() {
        setDragState(.highlighted)
        
        UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration) {
            self.layer.borderWidth = 2
            self.layer.borderColor = ImageDragGridConstants.Colors.primaryButton.cgColor
        }
    }
    
    /**
     * 隐藏高亮状态
     */
    func hideHighlight() {
        setDragState(.idle)
        
        UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration) {
            self.layer.borderWidth = 0
            self.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    // MARK: - Button Actions
    /// 删除按钮点击事件
    @objc private func deleteButtonTapped() {
        guard dragState.isInteractive,
              dragGestureHandler?.isDragging() != true,
              isDeleteEnabled else {
            return
        }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 执行删除回调
        onDelete?(self)
    }
    
    // MARK: - Gesture Handling
    /// 视图的点击事件：有点击回调执行点击回调，没有的话就删除这个 imageView
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // 前提是要把交互权限打开
        guard dragState.isInteractive,
              dragGestureHandler?.isDragging() != true else {
            return
        }
        
        // 优先执行点击回调
        if let onTap = onTap {
            // TODO: 知识盲区：触觉反馈
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap(self)
        } else if isDeleteEnabled && showsDeleteButton {
            // 如果没有点击回调且启用删除，执行删除回调
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onDelete?(self)
        }
    }
    
    // MARK: - Visual Effects
    /// 不同手势状态的视觉效果
    private func updateAppearanceForState() {
        switch dragState {
        case .idle:
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
            
        case .dragging:
            // 拖拽状态的视觉效果在手势处理中单独处理
            break
            
        case .highlighted:
            layer.borderWidth = 2
            layer.borderColor = ImageDragGridConstants.Colors.primaryButton.cgColor
        }
    }
    
    private func updateInteractionState() {
        isUserInteractionEnabled = isDragEnabled || (isDeleteEnabled && showsDeleteButton) // 可以拖 或者 可以删
        alpha = isDragEnabled ? 1.0 : 0.6
        
        // 更新辅助功能提示
        updateAccessibilityHint()
    }
    
    /// 设置删除按钮初始可见性
    private func updateDeleteButtonVisibility() {
        let shouldShow = showsDeleteButton && isDeleteEnabled // 可以显示 + 可以点击删除
        
        // TODO: 为什么要绕一次从 isHidden 等于否到 true
        // 从小到大的效果
        if deleteButton.isHidden && shouldShow { // 如果 shouldShow，则显示
            // 显示删除按钮的动画
            deleteButton.isHidden = false
            deleteButton.alpha = 0
            deleteButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) // 仿射：将删除按钮在 X 轴（水平）和 Y 轴（垂直）方向上缩放到原来的 50% 大小
            
            UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration,
                           delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.5) { [self] in
                deleteButton.alpha = 1
                deleteButton.transform = .identity //.identity 表示「无变换」，即原始状态
            }
        } else if !deleteButton.isHidden && !shouldShow {
            // 隐藏删除按钮的动画
            UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration) { [self] in
                deleteButton.alpha = 0
                deleteButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            } completion: { [self] _ in
                deleteButton.isHidden = true
                deleteButton.transform = .identity
            }
        }
    }
    
    /// 设置阴影效果
    private func applyDragShadow() {
        layer.shadowColor = ImageDragGridConstants.Colors.shadowColor
        layer.shadowOffset = ImageDragGridConstants.DragGesture.shadowOffset
        layer.shadowOpacity = ImageDragGridConstants.DragGesture.shadowOpacity
        layer.shadowRadius = ImageDragGridConstants.DragGesture.shadowRadius
        layer.masksToBounds = false
    }
    
    /// 移除阴影效果
    private func removeDragShadow() {
        layer.shadowOpacity = 0
        layer.masksToBounds = true
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard dragState.isInteractive else { return }
        
        // 轻微的按下反馈
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.8
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // 恢复透明度
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        // 恢复透明度
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
    
    // MARK: - Memory Management
    
    deinit {
        dragGestureHandler = nil
        onDelete = nil
        onTap = nil
        // lazy 属性会自动管理，无需手动移除
    }
}
