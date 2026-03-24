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

/// 星级评分组件
///
/// 支持三种评分模式：
/// 1. 完整星 (complete)
/// 2. 半星 (half)
/// 3. 无限精度 (unlimited)
class StarRateView: UIView {

    // MARK: - Properties
    
    private var config: StarRateConfigration
    private var lastCount: Float = -1
    private var currentCount: Float = 0
    
    /// 评分变化回调
    var starScoreClousure: ((Float) ->())?
   
    // MARK: - UI
    
    private lazy var unstarView = createStarView("unstar")
    
    private lazy var starView = createStarView("star")
    
    // MARK: - Initialization
    
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
    
    // MARK: - Public Methods
    
    /**
     设置当前评分
     
     - Parameter score: 评分值
     */
    public func setScore(_ score: Float) {
        self.currentCount = score
        updateStarView()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        addSubview(unstarView)
        addSubview(starView)
        // insertSubview(starView, aboveSubview: unstarView) // 已经 addSubview 了，不需要再 insert
        
        // 1. unstarView (背景灰色星星容器) 撑满整个组件
        unstarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 2. starView (前景黄色星星容器) 初始布局
        // 注意：它的宽度会由 updateStarView 动态控制，这里先设置基本约束
        starView.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.width.equalTo(0) // 初始宽度为0
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
        let view = UIView()
        view.clipsToBounds = true // 关键：超出部分裁剪，实现半星效果
        
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = CGFloat(config.starSpace)
        
        for _ in 0..<Int(config.starCount) {
            let imageView = UIImageView(image: UIImage(named: imageName))
            imageView.contentMode = .scaleAspectFit
            stackView.addArrangedSubview(imageView)
        }
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // StackView 撑满容器
        }
        
        return view
    }
    
    /// 更新视图
    private func updateStarView() {
        var count: Float = currentCount
        // ... (计算 count 逻辑保持不变)
        if count < config.leastCount {
            count = config.leastCount
        } else if count > Float(config.starCount) {
            count = Float(config.starCount)
        }
        
        // ... (省略 switch case 逻辑，因为前面没有改动)
        
        // 计算百分比
        let percent = CGFloat(count) / CGFloat(config.starCount)
        
        // 关键修复：
        // 1. starView 的宽度必须动态更新
        // 2. starView 内部的 StackView 必须保持完整宽度（不能随父视图缩小而挤压）
        
        starView.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            if percent == 0 {
                make.width.equalTo(0)
            } else {
                // 使用 unstarView 作为参考，因为它始终是满宽的
                make.width.equalTo(unstarView).multipliedBy(percent)
            }
        }
        
        // 强制 starView 内部的 StackView 宽度与 unstarView 一致
        // 这样当 starView 变窄时，内部的星星不会被压缩，而是被裁剪（因为 clipsToBounds = true）
        if let stack = starView.subviews.first {
            stack.snp.remakeConstraints { make in
                make.top.bottom.left.equalToSuperview()
                make.width.equalTo(unstarView) // 关键：宽度始终等于完整宽度
            }
        }
        
        self.starScoreClousure?(count)
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



