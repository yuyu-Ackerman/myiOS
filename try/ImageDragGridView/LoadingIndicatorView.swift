//
//  LoadingIndicatorView.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit
import SnapKit

/**
 * 加载指示器视图
 *
 * 提供美观的加载状态指示，支持进度显示和自定义样式
 */
class LoadingIndicatorView: UIView {
    
    // MARK: - UI Elements
    
    private lazy var backgroundView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = ImageDragGridConstants.Colors.primaryButton
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = ImageDragGridConstants.Colors.primaryButton
        progress.trackTintColor = UIColor.systemGray4
        progress.isHidden = true
        return progress
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()
    
    // MARK: - Properties
    
    /// 是否显示进度条
    var showsProgress: Bool = false {
        didSet {
            progressView.isHidden = !showsProgress
        }
    }
    
    /// 当前进度（0.0 - 1.0）
    var progress: Float = 0 {
        didSet {
            progressView.progress = progress
        }
    }
    
    /// 显示的消息文本
    var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = (message == nil)
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(message: String? = nil, showsProgress: Bool = false) {
        self.init(frame: .zero)
        self.message = message
        self.showsProgress = showsProgress
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        setupViewHierarchy()
        setupConstraints()
        
        // 初始状态设置
        isHidden = true
        alpha = 0
    }
    
    private func setupViewHierarchy() {
        addSubview(backgroundView)
        backgroundView.contentView.addSubview(containerView)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(progressView)
        containerView.addSubview(messageLabel)
    }
    
    private func setupConstraints() {
        // Background view
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Container view
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.greaterThanOrEqualTo(150)
            make.height.greaterThanOrEqualTo(100)
        }
        
        // Activity indicator
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
        }
        
        // Progress view
        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(activityIndicator.snp.bottom).offset(15)
        }
        
        // Message label
        messageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(progressView.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func updateUI() {
        messageLabel.text = message
        messageLabel.isHidden = (message == nil)
        progressView.isHidden = !showsProgress
        progressView.progress = progress
    }
    
    // MARK: - Public Methods
    
    /**
     * 显示加载指示器
     *
     * @param animated 是否使用动画
     */
    func show(animated: Bool = true) {
        isHidden = false
        activityIndicator.startAnimating()
        
        if animated {
            UIView.animate(withDuration: ImageDragGridConstants.Animation.quickDuration) {
                self.alpha = 1
            }
        } else {
            alpha = 1
        }
    }
    
    /**
     * 隐藏加载指示器
     *
     * @param animated 是否使用动画
     * @param completion 隐藏完成回调
     */
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        let hideBlock = {
            self.alpha = 0
            self.activityIndicator.stopAnimating()
        }
        
        if animated {
            UIView.animate(
                withDuration: ImageDragGridConstants.Animation.quickDuration,
                animations: hideBlock,
                completion: { _ in
                    self.isHidden = true
                    completion?()
                }
            )
        } else {
            hideBlock()
            isHidden = true
            completion?()
        }
    }
    
    /**
     * 更新进度
     *
     * @param progress 新的进度值（0.0 - 1.0）
     * @param animated 是否使用动画
     */
    func updateProgress(_ progress: Float, animated: Bool = true) {
        self.progress = progress
        progressView.setProgress(progress, animated: animated)
    }
    
    /**
     * 更新消息
     *
     * @param message 新的消息文本
     */
    func updateMessage(_ message: String?) {
        self.message = message
    }
}

// MARK: - Convenience Methods

extension LoadingIndicatorView {
    
    /**
     * 在指定视图上显示加载指示器
     *
     * @param parentView 父视图
     * @param message 显示的消息
     * @param showsProgress 是否显示进度条
     * @return 创建的加载指示器实例
     */
    static func show(
        in parentView: UIView,
        message: String? = ImageDragGridConstants.Text.loadingMessage,
        showsProgress: Bool = false
    ) -> LoadingIndicatorView {
        let loadingView = LoadingIndicatorView(message: message, showsProgress: showsProgress)
        
        parentView.addSubview(loadingView)
        
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingView.show(animated: true)
        return loadingView
    }
    
    /**
     * 在指定视图控制器上显示全屏加载指示器
     *
     * @param viewController 视图控制器
     * @param message 显示的消息
     * @param showsProgress 是否显示进度条
     * @return 创建的加载指示器实例
     */
    static func showFullScreen(
        in viewController: UIViewController,
        message: String? = ImageDragGridConstants.Text.loadingMessage,
        showsProgress: Bool = false
    ) -> LoadingIndicatorView {
        return show(in: viewController.view, message: message, showsProgress: showsProgress)
    }
}
