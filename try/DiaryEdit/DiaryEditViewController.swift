//
//  ViewController.swift
//  try
//
//  Created by 小余 on 2025/12/2.
//

import UIKit
import SnapKit

class DiaryEditViewController: UIViewController {
    
    private let viewModel = DiaryEditViewModel()
    private var isPlaceholderActive: Bool = true

    // MARK: UI 控件
    private lazy var backButtonImageView: UIImageView = {
        let biv = UIImageView()
        biv.contentMode = .scaleAspectFill
        biv.isUserInteractionEnabled = true
        biv.image = UIImage(named: "left_arrow")
        let tap = UITapGestureRecognizer(target: self, action: #selector(backButtonTapped))
        biv.addGestureRecognizer(tap)
        //biv.image = UIImage(systemName: )
        return biv
    }()
    
    private let titleLabel: UILabel = {
        let title = UILabel()
        title.text = "今日"
        title.textColor = .black
        title.font = .systemFont(ofSize: 24, weight: .bold)
        return title
    }()
    
    private let splitLine: UIView = {
        let line = UIView()
        line.backgroundColor = .gray
        return line
    }()
    
    private let contentScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let starRateLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "今日评分"
        lbl.textColor = .black
        lbl.font = .systemFont(ofSize: 18)
        return lbl
    }()
    
    //TODO: 搞明白 frame 约束的影响
    private lazy var starRateView: StarRateView = {
        let srv = StarRateView(config: StarRateConfigration())
        // 接收评分回调并打印
        srv.starScoreClousure = {[weak self] score in  // [weak self] 避免强引用
            print("当前评分：\(score)")
            self?.viewModel.setScore(score)
        }
        return srv
    }()
    
    private let textTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "说点什么"
        label.textColor = .black
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private lazy var textEditView: UITextView = {
        let attr = NSMutableAttributedString(string: "说点什么吧...")
        attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: attr.length))
        attr.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: 0, length: attr.length))
        let textView = UITextView()

        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.attributedText = attr
        return textView
    }()
    
    private let addPictureLabel: UILabel = {
        let label = UILabel()
        label.text = "晒晒照片"
        label.textColor = .black
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private let pictureContainerView = ImageDragGridView()
    
    private lazy var bottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("保存", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .label
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        btn.layer.cornerRadius = 15
        btn.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    // 当前编辑的日期，默认为今天。应该由外部传入
    var currentDate: Date = Date() {
        didSet {
            // 如果视图已经加载，更新标题
            if isViewLoaded {
                updateTitle()
                loadDiaryData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        addView()
        setConstraints()
        setupTapGesture()
        
        updateTitle()
        loadDiaryData()
    }
    
    //MARK: Private Methods
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: view)
        let convertedLocation = view.convert(tapLocation, to: textEditView)
        let isInsideTextView = textEditView.bounds.contains(convertedLocation)
        
        if !isInsideTextView && textEditView.isFirstResponder {
            textEditView.resignFirstResponder()
        }
    }
    
    /// 更新编辑界面标题
    private func updateTitle() {
        if Calendar.current.isDateInToday(currentDate) {
            titleLabel.text = "今日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日"
            titleLabel.text = formatter.string(from: currentDate)
        }
    }
    
    /// 加载对应日期的日记信息
    private func loadDiaryData() {
        // 1. 让 ViewModel 加载数据
        viewModel.loadData(for: currentDate)
        
        // 2. 从 ViewModel 获取数据更新 UI
        
        // 评分
        let score = viewModel.getScore()
        DispatchQueue.main.async {
            self.starRateView.setScore(score)
        }
        
        // 内容
        let content = viewModel.getContent()
        if !content.isEmpty {
            textEditView.text = content
            textEditView.textColor = .label
            isPlaceholderActive = false
        } else {
            // 重置为占位符
            textEditView.text = "说点什么吧..."
            textEditView.textColor = .gray
            isPlaceholderActive = true
        }
        
        // 图片
        let images = viewModel.getImages()
        pictureContainerView.removeAllImages(animated: false)
        if !images.isEmpty {
            pictureContainerView.addImages(images, animated: false)
        }
    }
    
    private func addView() {
        view.addSubview(titleLabel)
        view.addSubview(backButtonImageView)
        view.addSubview(splitLine)
        view.addSubview(contentScrollView)
        view.addSubview(bottomButton)
        
        contentScrollView.addSubview(starRateLabel)
        contentScrollView.addSubview(starRateView)
        contentScrollView.addSubview(textTitleLabel)
        contentScrollView.addSubview(textEditView)
        contentScrollView.addSubview(addPictureLabel)
        contentScrollView.addSubview(pictureContainerView)
    }
    
    private func setConstraints() {
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
            make.centerX.equalToSuperview()
        }
        
        backButtonImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top)
            make.left.equalToSuperview().inset(24)
            make.height.width.equalTo(titleLabel.font.lineHeight)
        }
        
        splitLine.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.width.equalToSuperview()
            make.height.equalTo(0.5)
            make.centerX.equalToSuperview().inset(32)
        }
        
        bottomButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(50)
            make.left.right.equalToSuperview().inset(90)
        }
        
        contentScrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalTo(splitLine.snp.bottom).offset(20)
            make.bottom.equalTo(bottomButton.snp.top)
        }
        
        starRateLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }
        
        starRateView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(starRateLabel.snp.bottom).offset(12)
            make.width.equalTo(200)
            make.height.equalTo(32)
        }
        
        textTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(starRateView.snp.bottom).offset(20)
        }
        
        textEditView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(textTitleLabel.snp.bottom).offset(12)
            make.width.equalToSuperview()
            make.height.equalTo(180)
        }
        
        addPictureLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(textEditView.snp.bottom).offset(20)
        }
        
        pictureContainerView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(addPictureLabel.snp.bottom).offset(12)
            make.height.equalTo(200)
            make.bottom.equalToSuperview().inset(20)
        }
    }
}

// MARK: UITextViewDelegate
extension DiaryEditViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if isPlaceholderActive {
            textView.text = ""
            textView.textColor = .label
            isPlaceholderActive = false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel.setContent(textView.text)
        textView.isHidden = false
        let height = textView.text.getHeightByWidth(Constant.componentWidth - 32, font: .systemFont(ofSize: 16)) // 为什么是减32, 不应该是两个内边距的距离22吗
        if height > 180 {
            textView.snp.remakeConstraints { make in
                make.height.equalTo(height + 22)
                make.left.equalToSuperview()
                make.top.equalTo(textTitleLabel.snp.bottom).offset(12)
                make.width.equalToSuperview()
            }
        }
    }
}

// MARK: Respond methods
extension DiaryEditViewController {
    /// 返回按钮点击响应
    @objc private func backButtonTapped() {
        let alert = UIAlertController(title: nil, message: "要保存已有内容吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .destructive, handler: {[weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "保存", style: .default, handler: {[weak self] _ in
            self?.saveButtonTapped()
        }))
        
        self.present(alert, animated: true)
    }
    
    /// 保存按钮点击响应
    @objc private func saveButtonTapped() {
        // 更新 ViewModel 中的图片数据
        let images = pictureContainerView.getAllImages()
        viewModel.setImages(images)
        
        // 调用 ViewModel 保存
        viewModel.save()
        
        // 提示成功并退出
        let alert = UIAlertController(title: nil, message: "日记已保存", preferredStyle: .alert)
        // TODO: 能不能不要 title, 只显示提示框
        alert.addAction(UIAlertAction(title: "好的", style: .cancel, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true)
        
        // TODO: 更新首页日记显示
    }
}
