//
//  ImageDragGridDelegate.swift
//  TESTDRAG
//
//  SDK 委托协议：定义图片拖拽网格组件的所有回调接口
//

import UIKit

/**
 * 图片拖拽网格组件委托协议
 *
 * 提供完整的事件回调，支持外部监听和响应组件事件
 */
@objc public protocol ImageDragGridViewDelegate: AnyObject {
  
  // MARK: - 图片管理回调
  
  /**
   * 图片已添加回调
   *
   * @param imageDragGridView 组件实例
   * @param images 添加的图片数组
   * @param indices 添加的索引位置数组
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didAddImages images: [UIImage],
                                        at indices: [Int])
  
  /**
   * 图片将要删除回调
   *
   * @param imageDragGridView 组件实例
   * @param index 将要删除的索引
   * @return 是否允许删除
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        shouldDeleteImageAt index: Int) -> Bool
  
  /**
   * 图片已删除回调
   *
   * @param imageDragGridView 组件实例
   * @param image 被删除的图片
   * @param index 被删除的索引
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didDeleteImage image: UIImage,
                                        at index: Int)
  
  // MARK: - 拖拽事件回调
  
  /**
   * 拖拽开始回调
   *
   * @param imageDragGridView 组件实例
   * @param index 开始拖拽的图片索引
   * @return 是否允许拖拽
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        shouldBeginDraggingAt index: Int) -> Bool
  
  /**
   * 拖拽开始回调
   *
   * @param imageDragGridView 组件实例
   * @param index 开始拖拽的图片索引
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didBeginDraggingAt index: Int)
  
  /**
   * 图片位置交换回调
   *
   * @param imageDragGridView 组件实例
   * @param sourceIndex 源索引
   * @param targetIndex 目标索引
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didMoveImageFrom sourceIndex: Int,
                                        to targetIndex: Int)
  
  /**
   * 拖拽结束回调
   *
   * @param imageDragGridView 组件实例
   * @param finalIndex 最终索引位置
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didEndDraggingAt finalIndex: Int)
  
  // MARK: - 图片选择回调
  
  /**
   * 将要显示图片选择器回调
   *
   * @param imageDragGridView 组件实例
   * @param remainingCount 剩余可选图片数量
   * @return 是否允许显示选择器
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        shouldPresentPickerWithRemainingCount remainingCount: Int) -> Bool
  
  /**
   * 图片选择器已显示回调
   *
   * @param imageDragGridView 组件实例
   */
  @objc optional func imageDragGridViewDidPresentPicker(_ imageDragGridView: ImageDragGridView)
  
  /**
   * 图片选择器已关闭回调
   *
   * @param imageDragGridView 组件实例
   * @param selectedCount 选择的图片数量
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didDismissPickerWithSelectedCount selectedCount: Int)
  
  // MARK: - 加载状态回调
  
  /**
   * 图片加载开始回调
   *
   * @param imageDragGridView 组件实例
   * @param count 准备加载的图片数量
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        willLoadImages count: Int)
  
  /**
   * 图片加载进度回调
   *
   * @param imageDragGridView 组件实例
   * @param progress 加载进度（0.0-1.0）
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        loadingProgress progress: Float)
  
  /**
   * 图片加载完成回调
   *
   * @param imageDragGridView 组件实例
   * @param successCount 成功加载的数量
   * @param failureCount 加载失败的数量
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didFinishLoadingWithSuccessCount successCount: Int,
                                        failureCount: Int)
  
  // MARK: - 错误处理回调
  
  /**
   * 错误发生回调
   *
   * @param imageDragGridView 组件实例
   * @param error 错误对象
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didEncounterError error: Error)
  
  // MARK: - 用户交互回调
  
  /**
   * 图片点击回调
   *
   * @param imageDragGridView 组件实例
   * @param index 被点击的图片索引
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didTapImageAt index: Int)
  
  /**
   * 添加按钮点击回调
   *
   * @param imageDragGridView 组件实例
   * @return 是否使用默认的图片选择器
   */
  @objc optional func imageDragGridViewDidTapAddButton(_ imageDragGridView: ImageDragGridView) -> Bool
  
  // MARK: - 数据变化回调
  
  /**
   * 图片数组变化回调
   *
   * @param imageDragGridView 组件实例
   * @param images 当前所有图片数组
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        imagesDidChange images: [UIImage])
  
  /**
   * 达到最大图片数量回调
   *
   * @param imageDragGridView 组件实例
   * @param maxCount 最大图片数量
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        didReachMaxImageCount maxCount: Int)
  
  // MARK: - 布局变化回调
  
  /**
   * 高度变化回调
   *
   * @param imageDragGridView 组件实例
   * @param newHeight 新的高度值
   * @param animated 是否需要动画
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        heightDidChange newHeight: CGFloat,
                                        animated: Bool)
}

/**
 * 图片拖拽网格组件数据源协议（可选）
 *
 * 提供初始数据和自定义加载逻辑
 */
@objc public protocol ImageDragGridViewDataSource: AnyObject {
  
  /**
   * 初始图片数量
   *
   * @param imageDragGridView 组件实例
   * @return 初始图片数量
   */
  @objc optional func numberOfInitialImages(in imageDragGridView: ImageDragGridView) -> Int
  
  /**
   * 初始图片
   *
   * @param imageDragGridView 组件实例
   * @param index 图片索引
   * @return 指定索引的图片
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        initialImageAt index: Int) -> UIImage?
  
  /**
   * 自定义图片加载逻辑
   *
   * @param imageDragGridView 组件实例
   * @param index 图片索引
   * @param completion 加载完成回调
   */
  @objc optional func imageDragGridView(_ imageDragGridView: ImageDragGridView,
                                        loadImageAt index: Int,
                                        completion: @escaping (UIImage?) -> Void)
}