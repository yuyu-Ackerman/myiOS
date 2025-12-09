//
//  ViewController.swift
//  try
//
//  Created by 小余 on 2025/12/2.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

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
    
    private let starRateView: StarRateView = {
        let view = StarRateView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), totalStarCount: 5, currentStarCount: 0, starSpace: 10)
        view.isPanEnable = true
        view.leastStar = 0
        view.starType = .default
        return view
    }()
    
    private let textTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "说点什么"
        label.textColor = .black
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private let textEditField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "说点什么吧..."
        textField.layer.cornerRadius = 12
        return textField
    }()
    
    private let addPictureLabel: UILabel = {
        let label = UILabel()
        label.text = "来几张图片"
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
        contentScrollView.addSubview(textEditField)
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
            make.left.right.equalToSuperview().inset(80)
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
        
        textEditField.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(textTitleLabel.snp.bottom).offset(12)
            make.width.equalToSuperview()
            make.height.equalTo(180)
        }
        
        addPictureLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(textEditField.snp.bottom).offset(20)
        }
        
        pictureContainerView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(200)
        }
    }
}

