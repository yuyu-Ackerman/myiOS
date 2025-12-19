//
//  StarRateView.swift
//  practice
//
//  Created by 小余 on 2025/12/17.
//

/* 问题：
   1. 初始的选择的星星数显示不出来：因为 starWidth = bounds.width * percent ，而 bounds.width 在刚刚加载视图时为0
 
 */

import UIKit
import SnapKit

class StarRateView: UIView {

    private var config: StarRateConfigration
    private var lastCount: Float = -1
    private var currentCount: Float = 0
    
    var starScoreClousure: ((Float) ->())?
   
    private lazy var unstarView = createStarView("unstar")
    
    private lazy var starView = createStarView("star")
    
    init(config:StarRateConfigration) {
        self.config = config
        // TODO: 什么意思
        super.init(frame: .zero)
        setupUI()
        setupGesture()
        updateStarView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(unstarView)
        addSubview(starView)
        insertSubview(starView, aboveSubview: unstarView)
        
        unstarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        
        starView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalTo(self)
        }
        
        /* ③ 把两个 stack 的宽度重新绑定到 self（StarRateView）*/
        unstarView.subviews.first!.snp.makeConstraints { make in   // 背景 stack
            make.leading.trailing.equalTo(self)
        }
        starView.subviews.first!.snp.makeConstraints { make in     // 前景 stack
            make.leading.trailing.equalTo(self)
        }
    }
    
    /// 手势设置
    private func setupGesture() {
        guard config.isEditable else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(starTapped))
        self.addGestureRecognizer(tap)
        
        if config.isPanable {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(starPaned))
            self.addGestureRecognizer(pan)
        }
    }
    
    /// 创建星星视图
    private func createStarView(_ imageName: String) -> UIView {
        let view: UIView = UIView()
        view.clipsToBounds = true
        
        let stackView: UIStackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = CGFloat(config.starSpace)
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            // 3
            make.left.right.equalToSuperview()
        }
        
        for _ in 0..<Int(config.starCount) {
            let imageView: UIImageView = UIImageView(image: UIImage(named: imageName))
            stackView.addArrangedSubview(imageView)
        }
        return view
    }
    
    /// 更新视图
    private func updateStarView() {
        var count: Float = currentCount
        if count < config.leastCount {
            count = config.leastCount
        } else if count > Float(config.starCount) {
            count = Float(config.starCount)
        }
        
        switch config.starType {
        case .complete:
            count = ceil(count)
        case .half:
            count = ceil(count * 2)/2
        case .unlimited:
            break
        }
        
        self.starScoreClousure?(count)
        
        if count == lastCount {
            return
        } else {
            lastCount = count
        }

        let percent = CGFloat(count) / CGFloat(config.starCount)
        //let starWidth = viewWidth * percent
        starView.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(unstarView.snp.width).multipliedBy(percent) // 改了这一句后就能显示 leastStar 了
        }
    }
}


extension StarRateView {
    /// 点击手势处理
    @objc private func starTapped(_ gesture: UIGestureRecognizer) {
        let pointX = gesture.location(in: self).x
        if pointX < 0 {
            self.currentCount = 0
        } else {
            self.currentCount = Float(pointX/self.bounds.width) * Float(config.starCount)
        }
        updateStarView()
    }
    
    /// 拖拽手势处理
    @objc private func starPaned(_ gesture: UIPanGestureRecognizer) {
        // 当前手指在视图里的绝对坐标
        let locationX = gesture.location(in: self).x
        let percent   = max(0, min(1, locationX / bounds.width))   // 钳口 0~1
        let newCount  = Float(percent * CGFloat(config.starCount))  // 0~5 星
        
        //只有变化才刷新，避免手指微抖不断重绘
        guard newCount != currentCount else {return}
        
        currentCount = newCount
        
        updateStarView()
    }
}



