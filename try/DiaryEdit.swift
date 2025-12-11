//
//  ViewController.swift
//  try
//
//  Created by 小余 on 2025/12/2.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    private var isPlaceholderActive: Bool = true

    // MARK: UI 控件
    private let titleLabel: UILabel = {
        let title = UILabel()
        title.text = "今日"
        title.textColor = .black
        title.font = .systemFont(ofSize: 20)
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
    private let starRateView: StarRateView = {
        let view = StarRateView(frame: CGRect(x: 0, y: 0, width: 200, height: 32), //
                                totalStarCount: 5,
                                currentStarCount: 0,
                                starSpace: 10)
        view.isPanEnable = true
        view.leastStar = 0
        view.starType = .half
        return view
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
    
    private let pictureContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let bottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("保存", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 15
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addView()
        setConstraints()
        starRateView.show(type: .default, isPanEnable: true, leastStar: 0) { score in
            print(score)
        }
    }
    
    
    //MARK: Private Methods
    private func addView() {
        view.addSubview(titleLabel)
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
            make.top.equalToSuperview().offset(56)
            make.centerX.equalToSuperview()
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
            make.width.equalToSuperview()
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

extension ViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if isPlaceholderActive {
            textView.text = ""
            textView.textColor = .black
            isPlaceholderActive = false
        }
    }
}

