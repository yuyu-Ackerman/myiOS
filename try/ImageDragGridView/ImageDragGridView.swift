//
//  ImageDragGridView.swift
//  TESTDRAG
//
//  SDK 主组件：封装完整的图片拖拽网格功能
//

import UIKit
import PhotosUI
import SnapKit

/**
 * 图片拖拽网格视图组件
 *
 * 提供完整的图片管理功能，包括：
 * - 图片选择和添加
 * - 拖拽排序
 * - 删除管理
 * - 自动布局
 * - 事件回调
 *
 * 使用示例：
 * ```swift
 * let gridView = ImageDragGridView()
 * gridView.delegate = self
 * gridView.configuration = .default
 * view.addSubview(gridView)
 * ```
 */
public class ImageDragGridView: UIView {
  
  // MARK: - Public Properties
  
  /// 委托对象
  public weak var delegate: ImageDragGridViewDelegate?
  
  /// 数据源对象（可选）
  public weak var dataSource: ImageDragGridViewDataSource?
  
    // TODO: 关于父 ScrollView 引用
    // TODO: 什么情况下使用 didSet
  /// 父 ScrollView（用于处理手势冲突）
  public weak var parentScrollView: UIScrollView? {
    didSet {
      dragHandler?.parentScrollView = parentScrollView
    }
  }
  
  /// 配置对象
  public var configuration: ImageDragGridConfiguration {
    didSet {
      applyConfiguration()
    }
  }
  
  /// 当前图片数组（只读）
  public private(set) var images: [UIImage] = []
  
  /// 是否达到最大图片数量
  public var isMaxImageCountReached: Bool {
    return images.count >= configuration.maxImageCount
  }
  
  /// 当前图片数量
  public var imageCount: Int {
    return images.count
  }
  
  // MARK: - Private Properties
  
  /// 容器视图
  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = configuration.containerBackgroundColor
    view.layer.cornerRadius = configuration.imageCornerRadius
    return view
  }()
  
    // TODO: button 的不同 type 有什么区别
  /// 添加按钮
  private lazy var addButton: UIButton = {
    let button = UIButton(type: .custom)
      // TODO: 这是什么新的属性
    let iconConfig = UIImage.SymbolConfiguration(
      pointSize: configuration.addButtonIconSize,
      weight: .medium
    )
    button.setImage(UIImage(named: "picture_add"), for: .normal)
    button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    
    return button
  }()
  
  /// 图片视图数组
  private var imageViews: [DraggableImageView] = []
  
  /// 网格管理器
  private var gridManager: ImageGridManager!
  
  /// 拖拽处理器
  private var dragHandler: DragGestureHandler!
  
  /// 图片加载管理器
  private let imageLoadingManager = ImageLoadingManager()
  
  /// 加载指示器
  private var loadingIndicator: LoadingIndicatorView?
  
  /// 性能监控
  private let performanceMonitor = PerformanceMonitor.shared
  
    // TODO: 了解一下 Constraint
  /// 当前高度约束
  private var heightConstraint: Constraint?
  
  /// 上一次的高度值
  private var previousHeight: CGFloat = 0
  
  // MARK: - Initialization
  
  /**
   * 代码初始化
   */
  public init(configuration: ImageDragGridConfiguration = .default) {
    self.configuration = configuration
    super.init(frame: .zero)
    setupUI()
    loadInitialData()
  }
  
  /**
   * Interface Builder 初始化
   */
    // TODO: 这个加了一样的内容
  public required init?(coder: NSCoder) {
    self.configuration = .default
    super.init(coder: coder)
    setupUI()
    loadInitialData()
  }
  
  /**
   * 便利初始化方法
   */
    // TODO: 便利初始化是做什么的、为什么要用、什么时候用
  public convenience init(frame: CGRect, configuration: ImageDragGridConfiguration) {
    self.init(configuration: configuration)
    self.frame = frame
  }
  
  // MARK: - Layout
  
    // TODO: 为什么这里要重写 layoutSubviews，一般在什么情况下需要重写
  public override func layoutSubviews() {
    super.layoutSubviews()
    updateLayout()
    updateHeightIfNeeded()
  }
  
  // MARK: - Public Methods
  
  /**
   * 添加图片
   *
   * @param images 要添加的图片数组
   * @param animated 是否显示动画
   */
  public func addImages(_ images: [UIImage], animated: Bool = true) {
    let availableSlots = configuration.maxImageCount - self.images.count
      // TODO: prefix 方法是做什么的
    let imagesToAdd = Array(images.prefix(availableSlots))
    
    guard !imagesToAdd.isEmpty else {
      delegate?.imageDragGridView?(self, didReachMaxImageCount: configuration.maxImageCount)
      return
    }
    
      // TODO: addedIndices 有什么作用
    var addedIndices: [Int] = []
    for image in imagesToAdd {
      let index = self.images.count
      addImage(image, animated: animated)
      addedIndices.append(index)
    }
    
    delegate?.imageDragGridView?(self, didAddImages: imagesToAdd, at: addedIndices)
    delegate?.imageDragGridView?(self, imagesDidChange: self.images)
    
    // 更新高度
    updateHeightIfNeeded()
    
    if isMaxImageCountReached {
      delegate?.imageDragGridView?(self, didReachMaxImageCount: configuration.maxImageCount)
    }
  }
  
  /**
   * 移除指定索引的图片
   *
   * @param index 要移除的索引
   * @param animated 是否显示动画
   */
  public func removeImage(at index: Int, animated: Bool = true) {
    guard index >= 0, index < images.count else { return }
    
    let shouldDelete = delegate?.imageDragGridView?(self, shouldDeleteImageAt: index) ?? true
    guard shouldDelete else { return }
    
    let removedImage = images[index]
    
    if animated {
      imageViews[index].performDeleteAnimation { [weak self] in
        guard let self = self else { return }
        self.removeImageView(at: index)
        self.delegate?.imageDragGridView?(self, didDeleteImage: removedImage, at: index)
        self.delegate?.imageDragGridView?(self, imagesDidChange: self.images)
        
        // 更新高度
        self.updateHeightIfNeeded()
      }
    } else {
      removeImageView(at: index)
      delegate?.imageDragGridView?(self, didDeleteImage: removedImage, at: index)
      delegate?.imageDragGridView?(self, imagesDidChange: images)
      
      // 更新高度
      updateHeightIfNeeded()
    }
  }
  
  /**
   * 清空所有图片
   *
   * @param animated 是否显示动画
   */
  public func removeAllImages(animated: Bool = true) {
    for (index, imageView) in imageViews.enumerated().reversed() {
      if animated {
        let delay = Double(imageViews.count - 1 - index) * 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
          imageView.performDeleteAnimation {
            guard let self = self else { return }
            self.removeImageView(at: index)
            if index == 0 {
              self.delegate?.imageDragGridView?(self, imagesDidChange: [])
            }
          }
        }
      } else {
        removeImageView(at: index)
      }
    }
    
    if !animated {
      delegate?.imageDragGridView?(self, imagesDidChange: [])
      
      // 更新高度
      updateHeightIfNeeded()
    }
  }
  
  /**
   * 获取指定索引的图片
   *
   * @param index 索引
   * @return 图片对象，如果索引无效返回nil
   */
  public func getImage(at index: Int) -> UIImage? {
    guard index >= 0, index < images.count else { return nil }
    return images[index]
  }
  
  /**
   * 获取所有图片
   *
   * @return 图片数组
   */
  public func getAllImages() -> [UIImage] {
    return images
  }
  
  /**
   * 先检查：已选图片是否到上限？→ 到了就通知代理，不唤起相册；
     再检查：能不能找到展示相册的控制器？→ 找不到就打印警告，不唤起；
     再询问代理：是否允许唤起相册？→ 代理拒绝就返回；
     配置相册：最多选「剩余可选数」张图片，只显示图片；
     唤起相册：带动画展示相册选择器，展示完成后通知代理。
   */
    /// 显示图片选择器
  public func presentImagePicker() {
    guard !isMaxImageCountReached else {
      delegate?.imageDragGridView?(self, didReachMaxImageCount: configuration.maxImageCount)
      return
    }
    
    guard let viewController = findViewController() else {
      print("Warning: Cannot find view controller to present picker")
      return
    }
    // 剩余可以添加的照片数量
    let remainingCount = configuration.maxImageCount - images.count
      // 询问代理
    let shouldPresent = delegate?.imageDragGridView?(
      self, 
      shouldPresentPickerWithRemainingCount: remainingCount
    ) ?? true
    guard shouldPresent else { return }
    
    var pickerConfig = PHPickerConfiguration()
    pickerConfig.selectionLimit = remainingCount
    pickerConfig.filter = .images
    
    let picker = PHPickerViewController(configuration: pickerConfig)
    picker.delegate = self
    
    viewController.present(picker, animated: true) { [weak self] in
      guard let self = self else { return }
        // 通知代理已经弹起了 picker
      self.delegate?.imageDragGridViewDidPresentPicker?(self)
    }
  }
  
  /**
   * 刷新布局
   */
  public func refreshLayout() {
    updateLayout()
    updateHeightIfNeeded()
  }
  
  /**
   * 重新加载配置
   */
  public func reloadWithConfiguration(_ configuration: ImageDragGridConfiguration) {
    self.configuration = configuration
    applyConfiguration()
    updateLayout()
  }
  
  // MARK: - Private Methods
  
  /**
   * 计算当前所需高度
   * 基于3列布局：1-3张图片为1行，4-6张为2行，7-9张为3行
   * 需要考虑添加按钮占用的空间
   */
  private func calculateRequiredHeight() -> CGFloat {
    let imageCount = images.count
    let itemSize = gridManager.calculateItemSize()
    
    // 如果没有图片，显示添加按钮的高度
    if imageCount == 0 {
//      return itemSize + configuration.gridSpacing * 2
      return 112
    }
    
    // 如果已达到最大数量，只计算图片的高度
    if imageCount >= configuration.maxImageCount {
      let rows = ceil(Double(imageCount) / 3.0)
      return CGFloat(rows) * itemSize + CGFloat(rows - 1) * configuration.gridSpacing + configuration.gridSpacing * 2
    }
    
    // 计算图片占用的位置数（包括添加按钮）
    let totalPositions = imageCount + 1 // +1 为添加按钮
    let rows = ceil(Double(totalPositions) / 3.0)
    
    // 计算高度：行数 * 图片尺寸 + (行数-1) * 间距 + 上下边距
    let totalHeight = CGFloat(rows) * itemSize + CGFloat(rows - 1) * configuration.gridSpacing + configuration.gridSpacing * 2
    
    return totalHeight
  }
  
  /**
   * 更新高度约束（如果需要）
   */
  private func updateHeightIfNeeded() {
    let newHeight = calculateRequiredHeight()
    
    // 只有高度真正变化时才更新
    if abs(newHeight - previousHeight) > 1.0 {
      previousHeight = newHeight
      
      // 更新高度约束
      self.snp.updateConstraints { make in
        make.height.equalTo(newHeight)
      }
      
      // 通知委托高度变化
      delegate?.imageDragGridView?(self, heightDidChange: newHeight, animated: true)
      
      // 执行动画
      UIView.animate(withDuration: configuration.animationDuration,
                     delay: 0,
                     usingSpringWithDamping: configuration.springDamping,
                     initialSpringVelocity: 0.5,
                     options: .curveEaseOut) {
          // TODO: 这一句存在的意义？什么情况下能用这个
        self.superview?.layoutIfNeeded()
      }
    }
  }
  
  private func setupUI() {
    // 添加容器视图
      // TODO: containerView存在的意义是什么，直接拿最外层 view 当容器不行吗
    addSubview(containerView)
    
    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    // 初始化管理器
    gridManager = ImageGridManager(containerView: containerView)
    dragHandler = DragGestureHandler(gridManager: gridManager, containerView: containerView)
    dragHandler.delegate = self
    dragHandler.parentScrollView = parentScrollView
    
    // 设置添加按钮
    setupAddButton()
    
    // 应用配置
    applyConfiguration()
  }
  
  private func setupAddButton() {
    containerView.addSubview(addButton)
  }
  
  private func applyConfiguration() {
    // 更新容器背景色
    containerView.backgroundColor = configuration.containerBackgroundColor
    // 更新网格管理器配置
    gridManager.updateConfiguration(
      columns: configuration.gridColumns,
      spacing: configuration.gridSpacing,
      cornerRadius: configuration.imageCornerRadius
    )
    
    // 更新拖拽处理器配置
    if configuration.isDragEnabled {
      dragHandler.isEnabled = true
    } else {
      dragHandler.isEnabled = false
    }
    
    // 更新现有图片视图
    for imageView in imageViews {
      imageView.layer.cornerRadius = configuration.imageCornerRadius
      imageView.showsDeleteButton = configuration.showDeleteButton
    }
  }
  
  private func updateLayout() {
    
    // 更新图片位置
    gridManager.updatePositions(
      for: imageViews,
      excluding: dragHandler.getCurrentDraggedView(),
      animated: true
    )
    
    // 更新添加按钮
    if let addButtonFrame = gridManager.getAddButtonFrame(for: images.count) {
      addButton.frame = addButtonFrame
      addButton.isHidden = false
    } else {
      addButton.isHidden = true
    }
  }
  
  private func addImage(_ image: UIImage, animated: Bool = true) {
    let imageView = DraggableImageView(image: image)
    imageView.setIndex(imageViews.count)
    imageView.layer.cornerRadius = configuration.imageCornerRadius
    imageView.showsDeleteButton = configuration.showDeleteButton
    
    // 设置删除回调
    imageView.onDelete = { [weak self] imageView in
      self?.handleImageDeletion(imageView)
    }
    
    // 设置点击回调
    imageView.onTap = { [weak self] imageView in
      guard let self = self, let index = self.imageViews.firstIndex(of: imageView) else { return }
      self.delegate?.imageDragGridView?(self, didTapImageAt: index)
    }
    
    // 添加拖拽手势
    if configuration.isDragEnabled {
      dragHandler.addDragGesture(to: imageView)
    }
    
    containerView.addSubview(imageView)
    imageViews.append(imageView)
    images.append(image)
    
    if animated {
      imageView.alpha = 0
      imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      UIView.animate(withDuration: configuration.animationDuration,
                     delay: 0,
                     usingSpringWithDamping: configuration.springDamping,
                     initialSpringVelocity: 0.5,
                     options: .curveEaseOut) {
        imageView.alpha = 1
        imageView.transform = .identity
      }
    }
    
    containerView.bringSubviewToFront(addButton)
    updateLayout()
  }
  
  private func removeImageView(at index: Int) {
    guard index >= 0, index < imageViews.count else { return }
    
    let imageView = imageViews[index]
    
    // 移除拖拽手势
    if configuration.isDragEnabled {
      dragHandler.removeDragGesture(from: imageView)
    }
    
    // 从视图中移除
    imageView.removeFromSuperview()
    
    // 从数组中移除
    imageViews.remove(at: index)
    images.remove(at: index)
    
    // 更新剩余图片的索引
    for i in index..<imageViews.count {
      imageViews[i].setIndex(i)
    }
    
    updateLayout()
  }
  
  private func handleImageDeletion(_ imageView: DraggableImageView) {
    guard !dragHandler.isDragging() else { return }
    guard let index = imageViews.firstIndex(of: imageView) else { return }
    
    if configuration.showDeleteConfirmation {
      showDeleteConfirmation(for: index)
    } else {
      removeImage(at: index)
    }
  }
  
  private func showDeleteConfirmation(for index: Int) {
    guard let viewController = findViewController() else { return }
    
    ErrorPresentationHelper.showDeleteConfirmation(
      in: viewController,
      title: configuration.deleteConfirmationTitle,
      message: configuration.deleteConfirmationMessage
    ) { [weak self] confirmed in
      guard confirmed, let self = self else { return }
      self.removeImage(at: index)
    }
  }
  
  private func moveImage(from sourceIndex: Int, to targetIndex: Int) {
    guard sourceIndex != targetIndex,
          sourceIndex >= 0, sourceIndex < imageViews.count,
          targetIndex >= 0, targetIndex < imageViews.count else { return }
    
    // 移动数据
    let movedImageView = imageViews[sourceIndex]
    let movedImage = images[sourceIndex]
    
    imageViews.remove(at: sourceIndex)
    images.remove(at: sourceIndex)
    
    imageViews.insert(movedImageView, at: targetIndex)
    images.insert(movedImage, at: targetIndex)
    
    // 更新索引
    for i in 0..<imageViews.count {
      imageViews[i].setIndex(i)
    }
    
    // 更新布局
    gridManager.updatePositions(
      for: imageViews,
      excluding: dragHandler.getCurrentDraggedView(),
      animated: true
    )
    
    // 通知委托
    delegate?.imageDragGridView?(self, didMoveImageFrom: sourceIndex, to: targetIndex)
    delegate?.imageDragGridView?(self, imagesDidChange: images)
  }
  
  private func loadInitialData() {
    guard let dataSource = dataSource else { return }
    
    let count = dataSource.numberOfInitialImages?(in: self) ?? 0
    guard count > 0 else { return }
    
    for i in 0..<min(count, configuration.maxImageCount) {
      if let image = dataSource.imageDragGridView?(self, initialImageAt: i) {
        addImage(image, animated: false)
      }
    }
  }
  
    // TODO: 了解一下 UIResponder
    /// 找到最近的 VC（供相册选择用）
  private func findViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let nextResponder = responder?.next {
      if let viewController = nextResponder as? UIViewController {
        return viewController
      }
      responder = nextResponder
    }
    return nil
  }
  
  // MARK: - Actions
  
  @objc private func addButtonTapped() {
    // 检查委托是否处理点击事件
    if let shouldUseDefaultPicker = delegate?.imageDragGridViewDidTapAddButton?(self),
       !shouldUseDefaultPicker {
      return
    }
    
    // 使用默认的图片选择器
    presentImagePicker()
  }
}

// MARK: - DragGestureHandlerDelegate

extension ImageDragGridView: DragGestureHandlerDelegate {
  
  func dragDidBegin(imageView: DraggableImageView, at index: Int) {
    // 触觉反馈
    if configuration.enableHapticFeedback {
      let feedback = UIImpactFeedbackGenerator(style: .medium)
      feedback.prepare()
      feedback.impactOccurred()
    }
    
    delegate?.imageDragGridView?(self, didBeginDraggingAt: index)
  }
  
  func dragDidMove(from sourceIndex: Int, to targetIndex: Int) {
    moveImage(from: sourceIndex, to: targetIndex)
  }
  
  func dragDidEnd(imageView: DraggableImageView) {
    updateLayout()
    
    if let index = imageViews.firstIndex(of: imageView) {
      delegate?.imageDragGridView?(self, didEndDraggingAt: index)
    }
  }
  
  func shouldAllowDrag(for imageView: DraggableImageView) -> Bool {
    guard configuration.isDragEnabled else { return false }
    guard imageViews.count > 1 else { return false }
    
    if let index = imageViews.firstIndex(of: imageView) {
      return delegate?.imageDragGridView?(self, shouldBeginDraggingAt: index) ?? true
    }
    
    return true
  }
}

// MARK: - PHPickerViewControllerDelegate

extension ImageDragGridView: PHPickerViewControllerDelegate {
  
  public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    dismissPickerAndNotifyDelegate(picker, resultCount: results.count)
    
    guard !results.isEmpty else { return }
    
    showLoadingIndicatorIfNeeded()
    notifyDelegateWillLoadImages(count: results.count)
    startLoadingImages(from: results)
  }
  
  // MARK: - Private Helper Methods for Picker
  
  private func dismissPickerAndNotifyDelegate(_ picker: PHPickerViewController, resultCount: Int) {
    picker.dismiss(animated: true) { [weak self] in
      guard let self = self else { return }
      self.delegate?.imageDragGridView?(self, didDismissPickerWithSelectedCount: resultCount)
    }
  }
  
  private func showLoadingIndicatorIfNeeded() {
    guard configuration.showLoadingIndicator,
          let viewController = findViewController() else { return }
    
    loadingIndicator = LoadingIndicatorView.showFullScreen(
      in: viewController,
      message: configuration.loadingMessage,
      showsProgress: true
    )
  }
  
  private func notifyDelegateWillLoadImages(count: Int) {
    delegate?.imageDragGridView?(self, willLoadImages: count)
  }
  
  private func startLoadingImages(from results: [PHPickerResult]) {
    imageLoadingManager.loadImages(
      from: results,
      progress: { [weak self] progress in
        self?.handleLoadingProgress(progress)
      },
      completion: { [weak self] loadedImages in
        self?.handleLoadingCompletion(loadedImages, totalCount: results.count)
      }
    )
  }
  
  private func handleLoadingProgress(_ progress: Double) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.loadingIndicator?.updateProgress(Float(progress))
      self.delegate?.imageDragGridView?(self, loadingProgress: Float(progress))
    }
  }
  
  private func handleLoadingCompletion(_ loadedImages: [UIImage], totalCount: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.hideLoadingIndicator()
      
      let failureCount = totalCount - loadedImages.count
      
      if !loadedImages.isEmpty {
        self.addImages(loadedImages)
      }
      
      self.notifyLoadingComplete(successCount: loadedImages.count, failureCount: failureCount)
      self.handleLoadingErrors(failureCount: failureCount, successCount: loadedImages.count)
    }
  }
  
  private func hideLoadingIndicator() {
    loadingIndicator?.hide(animated: true) { [weak self] in
      self?.loadingIndicator = nil
    }
  }
  
  private func notifyLoadingComplete(successCount: Int, failureCount: Int) {
    delegate?.imageDragGridView?(self, 
                                 didFinishLoadingWithSuccessCount: successCount,
                                 failureCount: failureCount)
  }
  
  private func handleLoadingErrors(failureCount: Int, successCount: Int) {
    guard failureCount > 0 else { return }
    
    let error = NSError(
      domain: "ImageLoading",
      code: 0,
      userInfo: [
        NSLocalizedDescriptionKey: "成功加载 \(successCount) 张图片，\(failureCount) 张加载失败"
      ]
    )
    delegate?.imageDragGridView?(self, didEncounterError: error)
  }
}
