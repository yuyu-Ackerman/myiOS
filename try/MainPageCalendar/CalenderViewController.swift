//
//  CalenderControllerView.swift
//  try
//
//  Created by 小余 on 2025/12/29.
//

// TODO: 1. 我不知道怎么写星期排头：一个大的 UIView + 7个label，配合 .dividedBy 方法

import UIKit
import SnapKit

struct Constant {
    /// 高度
    static let monthLabelHeight = 25
    /// 集合视图单元格间距
    static let spacingInCells = 0
    /// 组件之间的间距
    static let componentSpacing = 0
    /// 集合视图单元格宽度
    static let collectionViewCellWidth = 30
    static let scrollViewHeight = 300
    static let edge = 16
    static let weekTitleViewHeight = 40
}

/// 首页日历视图
class CalenderViewController: UIViewController {
    
    
    
    // MARK: UI 控件
    private let monthLabel: UILabel = {
        let mlbl = UILabel()
        mlbl.textColor = .lightText
        mlbl.text = "12"
        return mlbl
    }()
    
    private lazy var leftArrowImageView: UIImageView = {
        let liv = UIImageView()
        liv.image = UIImage(named: "")
        liv.contentMode = .scaleAspectFit
        liv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(leftArrowTapped)) // 什么情况要加括号
        liv.addGestureRecognizer(tap)
        return liv
    }()
    
    private lazy var rightArrowImageView: UIImageView = {
        let riv = UIImageView()
        riv.image = UIImage(named: "")
        riv.contentMode = .scaleAspectFit
        riv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(rightArrowTapped)) // 什么情况要加括号
        riv.addGestureRecognizer(tap)
        return riv
    }()
    
    private let weekTitleView = UIView()
    
    private lazy var calenderScrollView: UIScrollView = {
        let csv = UIScrollView()
        csv.isPagingEnabled = true
        csv.showsHorizontalScrollIndicator = false
        csv.delegate = self
        csv.backgroundColor = .blue
        return csv
    }()
    
    private lazy var calenderCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: Constant.collectionViewCellWidth, height: Constant.collectionViewCellWidth)
        layout.minimumLineSpacing = CGFloat(Constant.componentSpacing)
        layout.minimumInteritemSpacing = CGFloat(Constant.componentSpacing)
        
        let ccv = UICollectionView(frame: .zero, collectionViewLayout: layout) // frame: .zero 是什么意思
        ccv.delegate = self
        ccv.backgroundColor = .white
        ccv.showsHorizontalScrollIndicator = false
        ccv.register(CalendarControllerViewCell.self, forCellWithReuseIdentifier: CalendarControllerViewCell.reuseIdentifier)
        return ccv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addView()
        makeConstraints()
    }
    
    private func addView() {
        view.addSubview(monthLabel)
        view.addSubview(leftArrowImageView)
        view.addSubview(rightArrowImageView)
        view.addSubview(weekTitleView)
        view.addSubview(calenderScrollView)
        
        calenderScrollView.addSubview(calenderCollectionView)
    }
    
    private func makeConstraints() {
        monthLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(50)
            make.left.equalToSuperview().inset(Constant.edge)
        }
        
        rightArrowImageView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel)
            make.right.equalToSuperview().inset(Constant.edge)
            make.size.equalTo(CGSize(width: 6, height: 10))
        }
        
        leftArrowImageView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel)
            make.right.equalTo(rightArrowImageView.snp.left).inset(-5) // 正负分不清
            make.size.equalTo(CGSize(width: 6, height: 10))
        }
        
        weekTitleView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).inset(-5)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(Constant.weekTitleViewHeight)
        }
        
        calenderScrollView.snp.makeConstraints { make in
            make.top.equalTo(weekTitleView.snp.bottom).inset(-16)
            make.left.right.equalToSuperview().inset(Constant.edge)
            make.height.equalTo(Constant.scrollViewHeight)
        }
        
        calenderCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: Respond Methods
extension CalenderViewController {
    @objc private func leftArrowTapped() {
        
    }
    
    @objc private func rightArrowTapped() {
        
    }
}

// MARK: UIScrollViewDelegate
extension CalenderViewController: UIScrollViewDelegate {
    
}

// MARK: UICollectionViewDelegate
extension CalenderViewController: UICollectionViewDelegate {
    
}
