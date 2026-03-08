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

class ImageZoomManager {
    static let shared = ImageZoomManager()
    
    init() {}
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
