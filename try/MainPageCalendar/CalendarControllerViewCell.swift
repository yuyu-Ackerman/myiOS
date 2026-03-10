//
//  CalendarControllerViewCell.swift
//  try
//
//  Created by 小余 on 2025/12/29.
//
import UIKit
import SnapKit

/**
 日历视图单元格
 
 功能：
 1. 展示日期数字
 2. 展示日记背景图
 3. 展示特殊状态（今天高光、选中标记、遮罩）
 */

class CalendarControllerViewCell: UICollectionViewCell {
    
    /// 复用标识符
    static let reuseIdentifier = "calendarCell"
    
    // MARK: - UI 控件
    
    /// 背景图片视图
    let backgroundImageView: UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.layer.cornerRadius = 10
        bgImageView.clipsToBounds = true
        bgImageView.contentMode = .scaleAspectFill // 不同的填充方式
        return bgImageView
    }()
    
    /// 半透明遮罩层 (用于非当前月份或未来日期的视觉区分)
    let maskImageView: UIView = {
    let mv = UIView()
        mv.backgroundColor = .white
        mv.alpha = 0.4
        mv.isHidden = true
        return mv
    }()
    
    /// 日期数字标签
    let dateLabel: UILabel = {
        let dbl = UILabel()
        dbl.textColor = .label
        dbl.font = .systemFont(ofSize: 16, weight: .bold)
        return dbl
    }()
    
    /// 今天日期的高光背景
    let todayHighLightView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 15
//        view.layer.borderWidth = 0.5
//        view.layer.borderColor = UIColor.gray.cgColor
        view.isHidden = true
        return view
    }()
    
    /// 日记标记小圆点
    private lazy var diaryIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()
    
    /// 选中状态标记
    private lazy var selectMarkView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame) // 初始化参数?
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.image = nil
        // maskImageView.backgroundColor = nil // 不应清除背景色，这会导致它变透明
        maskImageView.isHidden = true // 关键：重置显隐状态
        dateLabel.text = nil
       // todayHighLightView.backgroundColor = nil
        todayHighLightView.isHidden = true
        dateLabel.textColor = .black
        // 我为当前日期添加高光时，一开始没有重写该方法，导致复用时出现错误：我向前/向后切换月份时，出现了很多日期同时被高光的情况，在添加该方法和 todayHighLightView.isHidden = true 这一句后多高光问题解决
        // 所以！复用前一定要重置状态！
        diaryIndicatorView.isHidden = true
        selectMarkView.isHidden = true
        
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
        contentView.addSubview(todayHighLightView)
        contentView.addSubview(dateLabel)
        contentView.insertSubview(dateLabel, aboveSubview: todayHighLightView)
        contentView.addSubview(diaryIndicatorView)
        contentView.addSubview(selectMarkView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        maskImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        todayHighLightView.snp.makeConstraints { make in
            make.height.width.equalTo(30)
            make.center.equalToSuperview()
        }
        
        diaryIndicatorView.snp.makeConstraints { make in
            make.width.height.equalTo(6)
            make.centerX.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
        }
        
        selectMarkView.snp.makeConstraints { make in
            make.height.equalTo(5)
            make.width.equalTo(20)
            make.centerX.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
        }
    }
}

// MARK: public methods
extension CalendarControllerViewCell {
    /// 设置 cell 对应的日期
    func configDate(with dateNum: Int) {
        dateLabel.text = String(dateNum)
    }
    
    /// 显示灰色遮罩 (用于过去日期)
    func showMaskImageView() {
        maskImageView.isHidden = false
    }
    
    /// 当前日期显示高光
    /// - Parameter show: 是否显示
    func showTodayHighLight(_ show: Bool) {
        dateLabel.textColor = .white
        todayHighLightView.isHidden = !show
    }
    
//    func showSelectedHighLight(_ show: Bool) {
//        todayHighLightView.backgroundColor = .yellow
//        todayHighLightView.isHidden = !show
//    }
    
    /// 显示日期下面的蓝色圆点 (是否有日记)
    func showDiaryIndicator(_ show: Bool) {
        diaryIndicatorView.isHidden = !show
    }
    
    /// 显示选中状态的下划线
    func showSelectMarkView(_ show: Bool) {
        selectMarkView.isHidden = !show
    }
    
    /// 显示背景图片
    func showBackgroundImage(image: UIImage) {
        backgroundImageView.image = image
    }
}
