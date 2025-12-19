//
//  ImageLoadingManager.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit
import PhotosUI

/**
 * 图片加载管理器
 *
 * 专门负责处理图片加载、错误处理、用户反馈和性能优化
 * 提供完整的加载生命周期管理和错误恢复机制
 */
class ImageLoadingManager {
    
    // MARK: - Types
    
    /// 图片加载结果
    enum LoadResult {
        case success(UIImage)
        case failure(Error)
    }
    
    /// 图片加载错误类型
    enum LoadError: LocalizedError {
        case invalidImageData
        case loadingCancelled
        case compressionFailed
        case networkError
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .invalidImageData:
                return "图片数据无效"
            case .loadingCancelled:
                return "图片加载已取消"
            case .compressionFailed:
                return "图片压缩失败"
            case .networkError:
                return "网络连接错误"
            case .permissionDenied:
                return "没有访问相册的权限"
            }
        }
    }
    
    /// 加载进度回调
    typealias ProgressCallback = (Double) -> Void
    
    /// 加载完成回调
    typealias CompletionCallback = (LoadResult) -> Void
    
    // MARK: - Properties
    
    /// 图片压缩质量
    private let compressionQuality: CGFloat
    
    /// 最大图片尺寸
    private let maxImageSize: CGFloat
    
    /// 当前加载任务
    private var loadingTasks: [UUID: URLSessionDataTask] = [:]
    
    /// 图片缓存
    private let imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    
    init(
        compressionQuality: CGFloat = ImageDragGridConstants.Performance.imageCompressionQuality,
        maxImageSize: CGFloat = ImageDragGridConstants.Performance.maxImageSize
    ) {
        self.compressionQuality = compressionQuality
        self.maxImageSize = maxImageSize
        setupImageCache()
    }
    
    private func setupImageCache() {
        imageCache.countLimit = 50  // 最多缓存50张图片
        imageCache.totalCostLimit = 50 * 1024 * 1024  // 最多使用50MB内存
    }
    
    // MARK: - Public Methods
    
    /**
     * 从 PHPickerResult 加载图片
     *
     * @param results 图片选择结果数组
     * @param progress 进度回调
     * @param completion 完成回调，返回成功加载的图片数组
     */
    func loadImages(
        from results: [PHPickerResult],
        progress: ProgressCallback? = nil,
        completion: @escaping ([UIImage]) -> Void
    ) {
        guard !results.isEmpty else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var loadedImages: [(image: UIImage, index: Int)] = []
        var completedCount = 0
        let totalCount = results.count
        
        // 并发加载所有图片
        for (index, result) in results.enumerated() {
            group.enter()
            
            loadImage(from: result) { [weak self] loadResult in
                defer { 
                    group.leave()
                    completedCount += 1
                    
                    // 更新进度
                    DispatchQueue.main.async {
                        progress?(Double(completedCount) / Double(totalCount))
                    }
                }
                
                switch loadResult {
                case .success(let image):
                    // 压缩和优化图片
                    if let optimizedImage = self?.optimizeImage(image) {
                        loadedImages.append((image: optimizedImage, index: index))
                    }
                    
                case .failure(let error):
                    print("Failed to load image at index \(index): \(error.localizedDescription)")
                    // 继续处理其他图片，不中断整个加载过程
                }
            }
        }
        
        // 所有图片处理完成后返回结果
        group.notify(queue: .main) {
            let sortedImages = loadedImages.sorted(by: { $0.index < $1.index })
            completion(sortedImages.map(\.image))
        }
    }
    
    /**
     * 从单个 PHPickerResult 加载图片
     *
     * @param result 图片选择结果
     * @param completion 完成回调
     */
    func loadImage(from result: PHPickerResult, completion: @escaping CompletionCallback) {
        let itemProvider = result.itemProvider
        
        // 检查是否支持图片类型
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else {
            completion(.failure(LoadError.invalidImageData))
            return
        }
        
        // 异步加载图片
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let image = object as? UIImage {
                    // 检查图片是否需要优化
                    if let optimizedImage = self?.optimizeImage(image) {
                        completion(.success(optimizedImage))
                    } else {
                        completion(.failure(LoadError.compressionFailed))
                    }
                } else {
                    completion(.failure(LoadError.invalidImageData))
                }
            }
        }
    }
    
    /**
     * 取消所有正在进行的加载任务
     */
    func cancelAllLoadingTasks() {
        loadingTasks.values.forEach({ $0.cancel() })
        loadingTasks.removeAll()
    }
    
    /**
     * 清除图片缓存
     */
    func clearImageCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Image Optimization
    
    /**
     * 优化图片（压缩和调整尺寸）
     *
     * @param image 原始图片
     * @return 优化后的图片
     */
    private func optimizeImage(_ image: UIImage) -> UIImage? {
        // 检查是否需要调整尺寸
        let resizedImage = resizeImageIfNeeded(image)
        
        // 压缩图片
        return compressImage(resizedImage)
    }
    
    /**
     * 调整图片尺寸（如果需要）
     *
     * @param image 原始图片
     * @return 调整尺寸后的图片
     */
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        // 如果图片尺寸小于最大值，直接返回
        guard maxDimension > maxImageSize else {
            return image
        }
        
        // 计算新的尺寸，保持宽高比
        let ratio = maxImageSize / maxDimension
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        // 创建新的图片
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    /**
     * 压缩图片
     *
     * @param image 要压缩的图片
     * @return 压缩后的图片
     */
    private func compressImage(_ image: UIImage) -> UIImage? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality),
              let compressedImage = UIImage(data: imageData) else {
            return nil
        }
        return compressedImage
    }
}

// MARK: - Error Presentation Helper

/**
 * 错误展示助手
 *
 * 提供统一的错误展示和用户反馈功能
 */
class ErrorPresentationHelper {
    
    /**
     * 显示错误警告框
     *
     * @param error 错误信息
     * @param viewController 展示的视图控制器
     * @param completion 用户操作完成回调
     */
    static func showError(
        _ error: Error,
        in viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        let title = "错误"
        let message = error.localizedDescription
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // 添加重试按钮（如果适用）
        if error is ImageLoadingManager.LoadError {
            alert.addAction(UIAlertAction(title: "重试", style: .default) { _ in
                completion?()
            })
        }
        
        // 添加确定按钮
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        viewController.present(alert, animated: true)
    }
    
    /**
     * 显示删除确认对话框
     *
     * @param viewController 展示的视图控制器
     * @param title 自定义标题（可选）
     * @param message 自定义消息（可选）
     * @param completion 用户确认回调
     */
    static func showDeleteConfirmation(
        in viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: title ?? ImageDragGridConstants.Text.deleteConfirmTitle,
            message: message ?? ImageDragGridConstants.Text.deleteConfirmMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: ImageDragGridConstants.Text.cancelButtonTitle, style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: ImageDragGridConstants.Text.confirmButtonTitle, style: .destructive) { _ in
            completion(true)
        })
        
        viewController.present(alert, animated: true)
    }
    
    /**
     * 显示成功提示
     *
     * @param message 提示信息
     * @param viewController 展示的视图控制器
     */
    static func showSuccess(
        _ message: String,
        in viewController: UIViewController
    ) {
        // 创建简单的成功提示
        let alert = UIAlertController(title: "成功", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        viewController.present(alert, animated: true)
        
        // 自动关闭提示（2秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alert.dismiss(animated: true)
        }
    }
}
