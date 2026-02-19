//
//  CalendarControllerView.swift
//  try
//
//  Created by 小余 on 2025/12/29.
//
/*

// TODO: 1.scrollView contentSize 可以根据约束自动撑开吗？必须要设置吗？所有视图都坍缩了，我怀疑之前 collectionView 的问题也是因为 scrollView。回头研究一下他的 contentSize
 // TODO: 2.背景都为黑色，即使没有打开黑夜模式，是因为默认背景为黑色吗
 A: 添加了这一句：self.view.backgroundColor = .systemBackground 把背景色设为系统背景，但这仅仅在当前页面有效，无法全局应用


*/
import UIKit
import SnapKit
import Foundation

// TODO: 常量数据 constant
struct Constant {
    /// 屏幕宽度
    static let screenWidth = UIScreen.main.bounds.width
    /// 屏幕高度
    static let screenHeight = UIScreen.main.bounds.height
    /// 高度
    static let monthLabelHeight = 25
    /// 集合视图单元格间距
    static let spacingInCells = 0
    /// 组件之间的间距
    static let componentSpacing = 0
    /// 集合视图单元格宽度
    static let collectionViewCellWidth = (screenWidth - edge * 2)/7
    /// 组件宽度
    static let componentWidth = screenWidth - edge * 2
    /// 日历 cell 间的间隔（暂未使用）
    static let spaceInCells = 1
    /// 组件视图左右留白宽度
    static let edge = 16.0
    /// 星期排头高度
    static let weekTitleViewHeight = 40
    /// cell 格子数
    static let datenum = 42
}

/// 首页日历视图
class CalendarViewController: UIViewController {
    
    private let weekTitle = ["一", "二", "三", "四", "五", "六", "日"]
    /// 一个日期 cell 的宽高
    private let sigalItemW = (UIScreen.main.bounds.width - Constant.edge * 2)/7
    
//    Swift不允许在类的顶层直接执行赋值、方法调用等操作，只能放声明（属性、方法、协议、嵌套类型等）
//    let now = Date()
//    // TODO: K
//    // 知识点:
//    // Calendar.current: 返回用户当前系统设置的日历（如果用户修改了系统日历设置，这里会变）。
//    // Calendar(identifier: .gregorian): 强制使用公历，不受用户系统设置影响。通常在处理固定业务逻辑时更安全。
//    var calendar = Calendar.current
//    calendar.timeZone = TimeZone.current
    
    var now = Date()
    var changedDate = Date()
    
    let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        cal.firstWeekday = 2
        return cal
    }()
    
    // MARK: UI 控件
    /// 整个屏幕内的 scrollView 便于滑动展示信息
    private lazy var scrollView: UIScrollView = {
        let slv = UIScrollView()
        slv.delegate = self
        slv.showsVerticalScrollIndicator = false
//        slv.contentSize.width = UIScreen.main.bounds.width
        // contentInsetAdjustmentBehavior = .never // 如果需要可以关闭自动调整
        return slv
    }()
    
    /// 月表示标签
    private lazy var monthLabel: UILabel = {
        let mlbl = UILabel()
        mlbl.textColor = .label
        mlbl.font = .systemFont(ofSize: 40, weight: .bold)
        return mlbl
    }()
    
    /// 左箭头
    private lazy var leftArrowImageView: UIImageView = {
        let liv = UIImageView()
        liv.image = UIImage(named: "left_arrow")
        liv.backgroundColor = .clear
        liv.contentMode = .scaleAspectFit
        liv.isUserInteractionEnabled = true
        // TODO: K
        // 提示：#selector 需要对应的函数有 @objc 标记。这里不需要加括号，因为是作为 selector 传递。
        // 如果要传参，selector 名字里会带冒号，如 #selector(tapped(_:))
        let tap = UITapGestureRecognizer(target: self, action: #selector(leftArrowTapped))
        liv.addGestureRecognizer(tap)
        return liv
    }()
    
    /// 右箭头
    private lazy var rightArrowImageView: UIImageView = {
        let riv = UIImageView()
        riv.backgroundColor = .clear
        riv.image = UIImage(named: "right_arrow")
        riv.contentMode = .scaleAspectFit
        riv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(rightArrowTapped)) // 什么情况要加括号
        riv.addGestureRecognizer(tap)
        return riv
    }()
    
    // 建议使用 UIStackView 来布局星期排头，比手动计算 frame 或约束更简单且自适应
    /// 星期排头
    private lazy var weekTitleStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        return stack
    }()
    
    // 移除 CalendarScrollView，因为 UICollectionView 本身就是 ScrollView，嵌套使用会导致布局困难且无必要
    /// 日历视图
    private lazy var CalendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: sigalItemW, height: sigalItemW)
        layout.minimumLineSpacing = CGFloat(Constant.componentSpacing)
        layout.minimumInteritemSpacing = CGFloat(Constant.componentSpacing)
//        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 0, right: 0)
        
        // frame: .zero 表示初始化时大小为 0，因为后续会通过 SnapKit (makeConstraints) 来设置布局，所以初始 frame 不重要
        let ccv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        ccv.delegate = self
        ccv.dataSource = self
        ccv.backgroundColor = .clear
        ccv.showsHorizontalScrollIndicator = false
        ccv.register(CalendarControllerViewCell.self, forCellWithReuseIdentifier: CalendarControllerViewCell.reuseIdentifier)
        return ccv
    }()
    
    private lazy var addButtonImageView: UIImageView = {
        let abtn = UIImageView()
        abtn.contentMode = .scaleAspectFill
        abtn.image = UIImage(named: "add_button")
        abtn.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
        abtn.addGestureRecognizer(tap)
        return abtn
    }()
    
    
    // MARK: initialize
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        //self.overrideUserInterfaceStyle = .unspecified
        addView()
        makeConstraints()
        setWeekTitle()
        updateCalendarUI()
        test()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("CalendarCollectionView frame: \(CalendarCollectionView.frame)")
        print("CalendarCollectionView superview: \(String(describing: CalendarCollectionView.superview))")
        print("scrollView contentSize: \(scrollView.contentSize)") //(0.0, 0.0)
        // 说明 contentSize 的大小为0，意思是直接通过最外层的 view 设置约束没有办法撑开 contentSize
        print("scrollView frame: \(scrollView.frame)")
        
        // 加个红色边框看看位置
//        CalendarCollectionView.layer.borderColor = UIColor.red.cgColor
//        CalendarCollectionView.layer.borderWidth = 2
    }
    
       
    
    // MARK: private methods
    private func addView() {
        view.addSubview(scrollView)
        view.addSubview(monthLabel)
        view.addSubview(leftArrowImageView)
        view.addSubview(rightArrowImageView)
        view.addSubview(addButtonImageView)
        scrollView.addSubview(weekTitleStackView) // 使用 StackView
        // 直接添加 collectionView
        scrollView.addSubview(CalendarCollectionView)
    }
    
    /// 更新日历 UI：标题和列表
    private func updateCalendarUI() {
        // 1. 更新月份标题
        let year = calendar.component(.year, from: changedDate)
        let month = calendar.component(.month, from: changedDate)
        monthLabel.text = "\(year).\(month)"
        
        // 2. 刷新 CollectionView
        CalendarCollectionView.reloadData()
    }
    
    private func makeConstraints() {
        monthLabel.snp.makeConstraints { make in
//            make.top.equalToSuperview().inset(50)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10) // 约束在顶部安全区下
            make.left.equalToSuperview().inset(Constant.edge)
        }
        
        rightArrowImageView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel)
            make.right.equalToSuperview().inset(Constant.edge)
            make.size.equalTo(CGSize(width: monthLabel.font.lineHeight, height: monthLabel.font.lineHeight))
        }
        
        leftArrowImageView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel)
            // inset 正值表示向内缩进。对于 right 约束，正值是向左，负值是向右。
            // 这里想让 leftArrow 在 rightArrow 的左边，应该用 make.right.equalTo(rightArrowImageView.snp.left).offset(-5)
            // 或者 make.trailing.equalTo(rightArrowImageView.snp.leading).offset(-5)
            make.right.equalTo(rightArrowImageView.snp.left).offset(-5)
            make.size.equalTo(CGSize(width: monthLabel.font.lineHeight, height: monthLabel.font.lineHeight))
        }
        
        addButtonImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().inset(200)
            make.width.height.equalTo(70)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        
        weekTitleStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalTo(Constant.componentWidth)
            make.height.equalTo(Constant.weekTitleViewHeight)
            make.centerX.equalToSuperview()
        }
        
        CalendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekTitleStackView.snp.bottom).offset(3)
            make.width.equalTo(Constant.componentWidth)
            // 改成这样以后就可以显示出日历了，但是 contentSize 依旧是(0.0, 0.0)
            make.height.equalTo(sigalItemW * 6)
            make.centerX.equalToSuperview()
        }
    }
    
    /// 设置星期排头的文字
    private func setWeekTitle() {
        for title in weekTitle {
            let label = UILabel()
            label.text = title
            label.textColor = .label
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 22, weight: .bold)
            weekTitleStackView.addArrangedSubview(label)
        }
    }
    
    /// 获取当月第一天的星期信息
    private func getFirstWeekDayOfMonth(from date: Date) -> Int {
        
        // 这是只获取了当前时间的年份和月份信息，没有精确到天
        let firstDayComponents = calendar.dateComponents([.year, .month], from: date)
        
        // 因此在从 firstDayComponents 中获取日期时，只能到月，返回该月第一天
        guard let firstDayOfMonth = calendar.date(from: firstDayComponents) else {
            fatalError("无法获取该月第一天")
        }
        
        // 获取第一天的星期信息，很巧妙的方法
        let weekdayNumber = calendar.component(.weekday, from: firstDayOfMonth)
        
        return weekdayNumber
    }
    
    /// 获取当天信息
    private func getTodayInfo() -> DateComponents {
        let today = calendar.dateComponents([.year, .month, .day], from: now)
        return today
    }
    
}

// MARK: Respond Methods
extension CalendarViewController {
    @objc private func leftArrowTapped() {
        // 获取上个月的日期
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: changedDate) else { return }
        // 更新当前日期
        changedDate = previousMonthDate
        // 刷新 UI
        updateCalendarUI()
    }
    
    @objc private func rightArrowTapped() {
        // 获取下个月的日期
        guard let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: changedDate) else { return }
        // 更新当前日期
        changedDate = nextMonthDate
        // 刷新 UI
        updateCalendarUI()
    }
    
    @objc private func addButtonTapped() {
        let editDiaryVC = DiaryEditViewController()
        editDiaryVC.modalPresentationStyle = .fullScreen
        self.present(editDiaryVC, animated: true)
        
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
        
        let firstWeekDayOfMonth = getFirstWeekDayOfMonth(from: changedDate)
        
        // 计算偏移量
        // firstWeekDayOfMonth: 1=Sun, 2=Mon, ..., 7=Sat
        // calendar.firstWeekday = 2 (设为了周一)
        var offset = firstWeekDayOfMonth - calendar.firstWeekday
        if offset < 0 {
            offset += 7
        }
        
        let day = indexPath.item - offset + 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: changedDate)?.count ?? 30
        
        if day > 0 && day <= daysInMonth {
            cell.configDate(with: day)
            cell.isHidden = false
            
            /*
             let dayToToday = calendar.dateComponents([.day], from: changedDate, to: now)
                         if dayToToday.day ?? 0 > 0 {
                             cell.showMaskImageView()
                         } else if dayToToday.day == 0 {
                             let today = calendar.component(.day, from: now)
                             if indexPath.item < today {
                                 cell.showMaskImageView()
                             } else if indexPath.item == today {
             */
            
            // 构造当前 cell 代表的完整日期
            var dateComponents = calendar.dateComponents([.year, .month], from: changedDate)
            dateComponents.day = day
                        
            if let cellDate = calendar.date(from: dateComponents) {
                // 比较 cell 日期和今天 (now)
                // 使用 compare(_:to:toGranularity:) 忽略时分秒差异，只比较日期
                let comparison = calendar.compare(cellDate, to: now, toGranularity: .day)
                
                if comparison == .orderedSame {
                    // 是今天
                    cell.showTodayHighLight()
                } else if comparison == .orderedAscending {
                    // 今天之前的日期 (过去) -> 显示遮罩 (假设业务需求是过去不可用/已过期)
                    cell.showMaskImageView()
                } else {
                    // 今天之后的日期 (未来) -> 正常显示
                    // cell.showMaskImageView() // 如果未来不可用，则在这里显示 mask
                }
            }
        } else {
            cell.isHidden = true
        }
        
        // 这里的 monthLabel 更新已经移到了 updateCalendarUI 中统一处理，这里删除
        // monthLabel.text = "\(calendar.component(.month, from: now))月"
        
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
        print("本月第一天是：\(firstDayOfMonth)\(weekDayString)（数字：\(weekdayNumber)）")
        
        
//        if let futureDate = calendar.date(byAdding: .month, value: -1, to: now) {
//            print("前一个月第一天：\(futureDate)")
//            // 前一个月第一天：2026-01-09 15:57:20 +0000
//            // 不是1月1日
//        } else {
//            print("计算失败")
//        }
        
        // 上月第一天 = 本月第一天 - 1个月
        let thisFirstDay = calendar.dateComponents([.year, .month], from: now)
        guard let firstDayOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            fatalError("无法获取本月第一天")
        }
        
        if let lastFirstDay = calendar.date(byAdding: .month, value: -1, to: firstDayOfCurrentMonth) {
            print("前一个月第一天：\(lastFirstDay)")
            //前一个月第一天：2025-12-31 16:00:00 +0000
        } else {
            print("计算失败")
        }
        
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

