//
//  CalendarControllerViewCell.swift
//  try
//
//  Created by 小余 on 2025/12/29.
//
import UIKit
import SnapKit

/// 日历视图的 cell
class CalendarControllerViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "calendarCell" // 修正拼写
    
    // MARK: UI 控件
    let backgroundImageView: UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.layer.cornerRadius = 5
        bgImageView.clipsToBounds = true
        bgImageView.contentMode = .scaleAspectFit // 不同的填充方式
        return bgImageView
    }()
    
    let maskImageView: UIView = { // 这里的 maskImageView 实际上是用作半透明遮罩层 (Overlay)，不是 layer.mask
    let mv = UIView()
        mv.backgroundColor = .black
        mv.alpha = 0.5
        return mv
    }()
    
    let dateLabel: UILabel = {
        let dbl = UILabel()
        dbl.textColor = .white
        dbl.font = .systemFont(ofSize: 14, weight: .bold)
        return dbl
    }()
    
    // MARK: 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame) 
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: 1. 要加 contentView. 2. 圆角和裁剪要在 contentView 上进行
    // 回答: 是的，最佳实践是将子视图添加到 contentView 上。
    private func setupUI() {
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(maskImageView)
        contentView.addSubview(dateLabel)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        maskImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
    }
    
    func configDate(with dateNum: Int) {
        dateLabel.text = String(dateNum)
    }
}
