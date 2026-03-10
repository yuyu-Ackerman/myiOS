//
//  ImageZoomManager.swift
//  try
//
//  Created by 小余 on 2026/3/8.
//


// TODO: 问题遗留：
/*  长截图无法显示完全
    未来可以考虑实现双指放大/缩小
 */

import UIKit

/**
 图片放大管理器
 
 功能：
 1. 提供全屏查看图片的动画效果
 2. 支持点击放大和点击缩小还原
 3. 自动计算图片缩放比例
 
 架构：
 单例模式
 */
class ImageZoomManager {
    
    // MARK: - Singleton
    
    static let shared = ImageZoomManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private var oldFrame: CGRect = .zero
    
    private lazy var zoomImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideView))
        image.addGestureRecognizer(tap)
        return image
    }()
    
    private var backgroundView: UIView = {
        let bgdView = UIView(frame: UIScreen.main.bounds) //
        bgdView.backgroundColor = .white
        bgdView.alpha = 0
        return bgdView
    }()
        
    // MARK: - Public Methods
    
    /**
     放大展示图片
     
     - Parameter imageView: 被点击的源图片视图
     
     动画流程：
     1. 获取源视图在 Window 中的坐标
     2. 创建临时放大视图，初始位置设为源视图位置
     3. 添加全屏背景
     4. 动画过渡到全屏居中显示
     */
    func zoom(imageView: UIImageView) {
        guard let image  = imageView.image,
        let window = UIApplication.shared.keyWindow else { return }
        
        oldFrame = imageView.convert(imageView.bounds, to: window)
        zoomImageView.frame = oldFrame
        zoomImageView.image = image
        
        window.addSubview(backgroundView)
        window.addSubview(zoomImageView)
        
        
        UIView.animate(withDuration: 0.4) {
            let screenW = UIScreen.main.bounds.width
            let scale = screenW / image.size.width
            let height = image.size.height * scale
            let y = (UIScreen.main.bounds.height - height) * 0.5
            
            self.zoomImageView.frame = CGRect(x: 0, y: y, width: screenW, height: height)
            self.backgroundView.alpha = 1
        }
    }
    
    // MARK: - Actions
    
    /**
     隐藏放大视图
     
     动画还原到原始位置，完成后移除视图
     */
    @objc private func hideView() {
        UIView.animate(withDuration: 0.4, animations: {
            self.zoomImageView.frame = self.oldFrame
            self.backgroundView.alpha = 0
        }, completion: { _ in
            self.zoomImageView.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
        })
        
    }
}
