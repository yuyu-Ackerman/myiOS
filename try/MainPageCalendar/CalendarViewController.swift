//
//  CalendarControllerView.swift
//  try
//
//  Created by 小余 on 2025/12/29.
//


// TODO: 1. 我不知道怎么写星期排头：一个大的 UIView + 7个label，配合 .dividedBy 方法

import UIKit
import SnapKit
import Foundation

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
    static let edge = 16.0
    static let weekTitleViewHeight = 40
    static let datenum = 35
}

/// 首页日历视图
class CalendarViewController: UIViewController {
    
    private let weekTitle = ["一", "二", "三", "四", "五", "六", "日"]
    private let sigalItemW = (UIScreen.main.bounds.width - Constant.edge * 2)/7
    
    let now = Date()
    // 知识点:
    // Calendar.current: 返回用户当前系统设置的日历（如果用户修改了系统日历设置，这里会变）。
    // Calendar(identifier: .gregorian): 强制使用公历，不受用户系统设置影响。通常在处理固定业务逻辑时更安全。
    var calendar = Calendar.current
    
    
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
        // 提示：#selector 需要对应的函数有 @objc 标记。这里不需要加括号，因为是作为 selector 传递。
        // 如果要传参，selector 名字里会带冒号，如 #selector(tapped(_:))
        let tap = UITapGestureRecognizer(target: self, action: #selector(leftArrowTapped))
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
    
    // 建议使用 UIStackView 来布局星期排头，比手动计算 frame 或约束更简单且自适应
    private lazy var weekTitleStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        return stack
    }()
    
    // 移除 CalendarScrollView，因为 UICollectionView 本身就是 ScrollView，嵌套使用会导致布局困难且无必要
    private lazy var CalendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: sigalItemW, height: sigalItemW)
        layout.minimumLineSpacing = CGFloat(Constant.componentSpacing)
        layout.minimumInteritemSpacing = CGFloat(Constant.componentSpacing)
        
        // frame: .zero 表示初始化时大小为 0，因为后续会通过 SnapKit (makeConstraints) 来设置布局，所以初始 frame 不重要
        let ccv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        ccv.delegate = self
        ccv.dataSource = self
        ccv.backgroundColor = .white
        ccv.showsHorizontalScrollIndicator = false
        ccv.register(CalendarControllerViewCell.self, forCellWithReuseIdentifier: CalendarControllerViewCell.reuseIdentifier)
        return ccv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addView()
        makeConstraints()
        setWeekTitle()
        test()
    }
    
    private func addView() {
        view.addSubview(monthLabel)
        view.addSubview(leftArrowImageView)
        view.addSubview(rightArrowImageView)
        view.addSubview(weekTitleStackView) // 使用 StackView
        // 直接添加 collectionView
        view.addSubview(CalendarCollectionView)
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
            // inset 正值表示向内缩进。对于 right 约束，正值是向左，负值是向右。
            // 这里想让 leftArrow 在 rightArrow 的左边，应该用 make.right.equalTo(rightArrowImageView.snp.left).offset(-5)
            // 或者 make.trailing.equalTo(rightArrowImageView.snp.leading).offset(-5)
            make.right.equalTo(rightArrowImageView.snp.left).offset(-15) 
            make.size.equalTo(CGSize(width: 6, height: 10))
        }
        
        weekTitleStackView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(5)
            make.left.right.equalToSuperview().inset(Constant.edge) // 两边对齐
            make.height.equalTo(Constant.weekTitleViewHeight)
        }
        
        CalendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekTitleStackView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(Constant.edge)
            make.height.equalTo(Constant.scrollViewHeight)
        }
    }
    
    private func setWeekTitle() {
        for title in weekTitle {
            let label = UILabel()
            label.text = title
            label.textColor = .black // 修正颜色，white 在白底上看不见
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14)
            weekTitleStackView.addArrangedSubview(label)
        }
    }
    
    private func getFirstWeekDayOfMonth() -> Int {
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2
        
        let firstDayComponents = calendar.dateComponents([.year, .month], from: now)
        
        guard let firstDayOfMonth = calendar.date(from: firstDayComponents) else {
            fatalError("无法获取本月第一天")
        }
        
        let weekdayNumber = calendar.component(.weekday, from: firstDayOfMonth)
        
        return weekdayNumber
    }
}

// MARK: Respond Methods
extension CalendarViewController {
    @objc private func leftArrowTapped() {
        
    }
    
    @objc private func rightArrowTapped() {
        
    }
}

// MARK: UIScrollViewDelegate
extension CalendarViewController: UIScrollViewDelegate {
    
}

// MARK: UICollectionViewDelegate
extension CalendarViewController: UICollectionViewDelegate {
    
}

// MARK: UICollectionViewDataSource
extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Constant.datenum
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // TODO: 弄清楚下面这个方法
        // dequeueReusableCell: 从复用池中取出一个可用的 cell。如果池中没有，系统会创建一个新的（基于注册的类或 nib）。
        // 这样可以避免频繁创建销毁对象，提高性能。
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarControllerViewCell.reuseIdentifier, for: indexPath) as? CalendarControllerViewCell
        guard let cell = cell else { return CalendarControllerViewCell() }
        
        let firstWeekDayOfMonth = getFirstWeekDayOfMonth()
        
        // 计算偏移量
        // firstWeekDayOfMonth: 1=Sun, 2=Mon, ..., 7=Sat
        // calendar.firstWeekday = 2 (设为了周一)
        var offset = firstWeekDayOfMonth - calendar.firstWeekday
        if offset < 0 {
            offset += 7
        }
        
        let day = indexPath.item - offset + 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        
        if day > 0 && day <= daysInMonth {
            cell.configDate(with: day)
            cell.isHidden = false
        } else {
            cell.isHidden = true
        }
        
        return cell
    }
}

// MARK: Test
extension CalendarViewController {
    func test() {
        let now = Date()
        // TODO: Calendar(identifier: .gregorian) 和 Calendar.current 的区别
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2
        
        let firstDayComponents = calendar.dateComponents([.year, .month], from: now)
        
        guard let firstDayOfMonth = calendar.date(from: firstDayComponents) else {
            fatalError("无法获取本月第一天")
        }
        
        let weekdayNumber = calendar.component(.weekday, from: firstDayOfMonth)
        
        let weekDays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekDayString = weekDays[weekdayNumber - 1]

        // 结果
        print("本月第一天是：\(weekDayString)（数字：\(weekdayNumber)）")
        
    }
}

/*
 Errors:
 1. collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath:) 方法没执行
    A：命名出了问题（calendar&&calender）
 
 */

/*
 ### 🛠️ 主要修复与改进
 1. 日历逻辑修复 ( cellForItemAt )
    
    - 问题 ：原代码中 cellForItemAt 使用了错误的循环逻辑，导致 cell 配置混乱。
    - 修复 ：重写了逻辑。现在根据 firstWeekDayOfMonth 计算偏移量，正确地将 indexPath.item 映射到具体的日期数字，并处理了非本月日期的隐藏。
 2. 星期排头改进 ( setWeekTitle )
    
    - 问题 ：TODO 中提到不知道如何写星期排头。
    - 修复 ：将原先的手动布局改为 UIStackView 。这是处理等宽、等间距排列（如星期标题）的最佳实践，代码更简洁且自适应性更强。
 3. 拼写修正
    
    - 将代码中的 Calendar 修正为 calendar （如 reuseIdentifier ）。
    - 建议后续将文件名 CalendarViewController.swift 重命名为 CalendarViewController.swift 以保持一致。
 ### 💡 针对代码注释的解答
 我在代码中直接添加了解释性注释，这里汇总一下关键点：

 - Calendar.current vs Calendar(identifier: .gregorian)
   
   - Calendar.current :跟随用户系统的日历设置（例如用户可能设置了日本历或佛教历）。
   - Calendar(identifier: .gregorian) : 强制使用公历。对于大多数 App 的业务逻辑，强制指定公历通常更安全。
 - #selector 括号问题
   
   - #selector(methodName) 不需要加 () 。如果方法有参数，写法是 #selector(methodName(_:)) 。你原本的写法是正确的。
 - frame: .zero
   
   - 当你计划使用 Auto Layout (SnapKit) 来设置视图的大小时，初始化时的 frame 并不重要，所以习惯传 .zero (即 CGRect.zero )。
 - setupUI 中的 contentView
   
   - Cell : 自定义 UICollectionViewCell 时，子视图（Subviews） 必须 添加到 contentView 上，而不是直接添加到 cell 本身。这样可以避免被系统背景视图遮挡，并正确处理编辑模式和布局转换。
 - 约束 inset 的正负
   
   - inset 表示“向内缩进”。
   - top/left : 正值向右下移（增加坐标）。
   - bottom/right : 正值向左上移（减小坐标）。
   - 例如： make.right.equalToSuperview().inset(10) 意味着 view 的右边缘距离 superview 的右边缘 10pt。
 */
