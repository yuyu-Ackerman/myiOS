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
            self?.viewModel.starRate = score //
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
    
    private let pictureContainerView: ImageDragGridView = {
        let view = ImageDragGridView()
        return view
    }()
    
    private lazy var bottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("保存", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .label
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
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
                // 清除旧数据重新加载？通常只会设置一次
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        addView()
        setConstraints()
        
        updateTitle()
        loadDiaryData()
    }
    
    private func updateTitle() {
        if Calendar.current.isDateInToday(currentDate) {
            titleLabel.text = "今日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日"
            titleLabel.text = formatter.string(from: currentDate)
        }
    }
    
    private func loadDiaryData() {
        if let diary = DiaryStorageManager.shared.getDiary(for: currentDate) {
            // Populate ViewModel
            viewModel.starRate = diary.score
            viewModel.description = diary.content
            
            // Update UI
            // 延迟一点设置评分，确保视图布局完成（虽然 snapkit 应该能处理）
            DispatchQueue.main.async {
                self.starRateView.setScore(diary.score)
            }
            
            if !diary.content.isEmpty {
                textEditView.text = diary.content
                textEditView.textColor = .label
                isPlaceholderActive = false
            }
            
            // Load images
            var images: [UIImage] = []
            for path in diary.imagePaths {
                if let image = DiaryStorageManager.shared.loadImage(named: path) {
                    images.append(image)
                }
            }
            if !images.isEmpty {
                pictureContainerView.addImages(images, animated: false)
            }
        }
    }
    
    //MARK: Private Methods
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
        }
    }
}

extension DiaryEditViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if isPlaceholderActive {
            textView.text = ""
            textView.textColor = .label
            isPlaceholderActive = false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel.description = textView.text
    }
}

extension DiaryEditViewController {
    @objc private func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveButtonTapped() {
        // 获取数据
        let score = viewModel.starRate
        let content = viewModel.description
        let images = pictureContainerView.getAllImages()
        
        // 保存
        DiaryStorageManager.shared.saveDiary(date: currentDate, score: score, content: content, images: images)
        
        // 提示成功并退出
        let alert = UIAlertController(title: "成功", message: "日记已保存", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true)
    }
}
