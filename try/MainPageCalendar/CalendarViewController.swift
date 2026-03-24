//
//  CalendarControllerView.swift
//  try
//
//  Created by 小余 on 2025/12/29.
//

/**
 首页日历视图控制器

 功能：
 1. 展示月视图日历
 2. 支持月份切换
 3. 展示日记概览（评分、内容摘要、图片）
 4. 处理日期点击事件，跳转或刷新选中状态
 5. 响应日记更新通知

 架构：
 MVC (配合 ViewModel 处理数据)

 主要职责：
 - 管理日历 UI 布局
 - 处理用户交互（点击、滑动、长按）
 - 协调 DiaryEditViewModel 和 DiaryStorageManager
 */
/*

// TODO: 1.scrollView contentSize 可以根据约束自动撑开吗？必须要设置吗？所有视图都坍缩了，我怀疑之前 collectionView 的问题也是因为 scrollView。回头研究一下他的 contentSize
 // TODO: 2.背景都为黑色，即使没有打开黑夜模式，是因为默认背景为黑色吗
 A: 添加了这一句：self.view.backgroundColor = .systemBackground 把背景色设为系统背景，但这仅仅在当前页面有效，无法全局应用
 // 一个很大的败笔：没有理清楚3个date的关系，导致后面用的时候想一出是一出，很混乱


*/
import UIKit
import SnapKit
import Foundation


extension String {
    func getHeightByWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = self.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }
}

enum DiaryShouldShow {
    case none
    case rate
    case description
    case images
}

// TODO: 常量数据 constant
struct Constant {
    /// 屏幕宽度
    static let screenWidth = UIScreen.main.bounds.width
    /// 屏幕高度
    static let screenHeight = UIScreen.main.bounds.height
    /// 高度
    static let monthLabelHeight = 25
    /// 组件之间的间距
    static let componentSpacing = 16
    /// 集合视图单元格宽度
    static let collectionViewCellWidth = (screenWidth - edge * 2)/7
    /// 组件宽度
    static let componentWidth = screenWidth - edge * 2
    /// 日历 cell 间的间隔
    static let spaceInCells = 0
    /// 组件视图左右留白宽度
    static let edge = 16.0
    /// 星期排头高度
    static let weekTitleViewHeight = 40
    /// cell 格子数
    static let datenum = 42
    /// 图片间的距离
    static let spacingInPictures = 3.0
}

/// 首页日历视图
class CalendarViewController: UIViewController {
    
    // MARK: - Data
    
    private let weekTitle = ["一", "二", "三", "四", "五", "六", "日"]
    /// 一个日期 cell 的宽高
    private let sigalItemW = (UIScreen.main.bounds.width - Constant.edge * 2)/7
    
    /// 负责处理日记数据的 ViewModel
    private let viewModel = CalendarViewViewModel()
    
//    Swift不允许在类的顶层直接执行赋值、方法调用等操作，只能放声明（属性、方法、协议、嵌套类型等）
//    let now = Date()
//    // TODO: K
//    // 知识点:
//    // Calendar.current: 返回用户当前系统设置的日历（如果用户修改了系统日历设置，这里会变）。
//    // Calendar(identifier: .gregorian): 强制使用公历，不受用户系统设置影响。通常在处理固定业务逻辑时更安全。
//    var calendar = Calendar.current
//    calendar.timeZone = TimeZone.current
    
    /// 当前时间（基准时间）
    var now = Date()
    /// 当前显示的月份所在的日期（用于翻页）
    var changedDate = Date()
   // private var selectedDate: Date = Date()
    /// 动态计算的日历行数
    var rowCount: CGFloat = 0 // 不能放在 dataSourse 中定义，因为每一次都会重新定义 rowCount 刷新。。导致不管多少次结果都是0
    
    /// 日历对象
    let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        cal.firstWeekday = 2
        return cal
    }()
    
    /// 存储有日记的日期字符串集合
    private var diaryDates: Set<String> = []
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - UI 控件
    
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
        mlbl.font = .systemFont(ofSize: 28, weight: .bold)
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
        layout.minimumLineSpacing = CGFloat(Constant.spaceInCells)
        layout.minimumInteritemSpacing = CGFloat(Constant.spaceInCells)
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
        abtn.backgroundColor = .white
        abtn.layer.cornerRadius = 40
        abtn.image = UIImage(named: "add_button")
        abtn.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
        abtn.addGestureRecognizer(tap)
        
        return abtn
    }()
    
    private lazy var starRateView: StarRateView = {
        let srv = StarRateView(config: StarRateConfigration(
            isPanable: false,
            isEditable: false))
        return srv
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
//        textView.text = "111111nihciuvhodcml;sm"
        textView.layer.cornerRadius = 12
        textView.showsVerticalScrollIndicator = false
        textView.bounces = false
        textView.layer.borderWidth = 1
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 10)
        return textView
    }()
    
    private let pictureContainerView = UIView()
    
    private let dateLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = .label
        return lbl
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupViews()
        setupConstraints()
        setWeekTitle()
        
        
        // 注册日记更新通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleDiaryUpdate), name: .diaryUpdated, object: nil)
        
   //     updateCalendarUI()
        
        // 初始加载日记数据
        fetchDiaryDates()
    }
    
    // TODO: 为什么要加 deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        print("CalendarCollectionView frame: \(CalendarCollectionView.frame)")
//        print("CalendarCollectionView superview: \(String(describing: CalendarCollectionView.superview))")
//        print("scrollView contentSize: \(scrollView.contentSize)") //(0.0, 0.0)
//        // 说明 contentSize 的大小为0，意思是直接通过最外层的 view 设置约束没有办法撑开 contentSize
//        print("scrollView frame: \(scrollView.frame)")
//
//        // 加个红色边框看看位置
//        CalendarCollectionView.layer.borderColor = UIColor.red.cgColor
//        CalendarCollectionView.layer.borderWidth = 2
//    }
           
    
    // MARK: private methods
    /// 添加子视图
    private func setupViews() {
        view.addSubview(scrollView)
        view.addSubview(monthLabel)
        view.addSubview(leftArrowImageView)
        view.addSubview(rightArrowImageView)
        view.addSubview(addButtonImageView)
        scrollView.addSubview(weekTitleStackView) // 使用 StackView
        // 直接添加 collectionView
        scrollView.addSubview(CalendarCollectionView)
        scrollView.addSubview(dateLabel)
        scrollView.addSubview(starRateView)
        scrollView.addSubview(textView)
        scrollView.addSubview(pictureContainerView)
    }
    

    
    /**
     更新日历 UI：标题和列表
     
     触发场景：
     - 切换月份
     - 初始化
     - 数据更新
     */
    private func updateCalendarUI() {
        // 1. 更新月份标题
        let year = calendar.component(.year, from: changedDate)
        let month = calendar.component(.month, from: changedDate)
        monthLabel.text = "\(year).\(month)"
        
        // 2. 刷新 CollectionView
        CalendarCollectionView.reloadData()
//        // TODO: load data 之前应该清除缓存
//        DiaryStorageManager.shared.clearBuffer(date: changedDate)
        // 不能清，不然会导致每次切换月份时，每次切换月份或刷新日历时，系统都会删除当前日期对应的日记图片！
        loadData(date: changedDate) // 为什么 now 不行
    }
    
    private func setupConstraints() {
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
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(CalendarCollectionView.snp.bottom).offset(Constant.componentSpacing)
            make.left.equalToSuperview().inset(16)
        }
        
        starRateView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.width.equalTo(160)
            make.height.equalTo(25)
            
            make.top.equalTo(dateLabel.snp.bottom).offset(Constant.componentSpacing)
        }
        
        textView.snp.makeConstraints { make in
            make.width.equalTo(Constant.componentWidth)
            make.top.equalTo(starRateView.snp.bottom).offset(Constant.componentSpacing)
            make.centerX.equalToSuperview()
        }
        
        pictureContainerView.snp.makeConstraints { make in
            make.width.equalTo(Constant.componentWidth)
            make.height.equalTo(0)
            make.top.equalTo(textView.snp.bottom).offset(Constant.componentSpacing)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(10) //
        }
    }
    

    /// 设置星期排头的文字
    private func setWeekTitle() {
        for title in weekTitle {
            let label = UILabel()
            label.text = title
            label.textColor = .black
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16, weight: .bold)
            weekTitleStackView.addArrangedSubview(label)
        }
    }
    
    /**
     加载指定日期的日记数据
     
     - Parameter date: 要加载的日期
     
     流程：
     1. 通过 ViewModel 获取数据
     2. 更新评分、文本、图片 UI
     3. 如果没有数据则隐藏详情区域
     */
    private func loadData(date: Date) {
        viewModel.loadData(for: date)
        let score = viewModel.getScore()
        let text = viewModel.getContent()
        let images = viewModel.getImages()
        
        if text.isEmpty, images.isEmpty {
            hideDiary()
            return
        }
        self.starRateView.isHidden = false //
        self.dateLabel.isHidden = false //
        let day = calendar.component(.day, from: date)
        self.dateLabel.text = "About Day\(day):"
        self.starRateView.setScore(score)
                
        self.textView.text = text
        if text.isEmpty {
            textView.isHidden = true
        } else {
            textView.isHidden = false
            let height = self.textView.text.getHeightByWidth(Constant.componentWidth - 32, font: .systemFont(ofSize: 16)) // 为什么是减32, 不应该是两个内边距的距离22吗
            textView.snp.remakeConstraints { make in
                make.height.equalTo(height + 22)
                make.width.equalTo(Constant.componentWidth)
                make.top.equalTo(starRateView.snp.bottom).offset(Constant.componentSpacing)
                make.centerX.equalToSuperview()
            }
        }
        
        setPictures(images: images)
    }
    
    private func hideDiary() {
        self.dateLabel.isHidden = true
        self.starRateView.isHidden = true
        self.textView.isHidden = true
        self.pictureContainerView.isHidden = true
    }
    
    /**
     设置日记图片展示
     
     - Parameter images: 图片数组
     
     布局逻辑：
     - 九宫格布局
     - 动态计算高度
     - 支持点击放大和长按保存
     */
    private func setPictures(images: [UIImage]) {
        // 清除旧的图片视图
        pictureContainerView.subviews.forEach { $0.removeFromSuperview() }
        // 原因是在刷新日记详情区域的图片时， CalendarViewController 没有清除旧的图片视图，直接在上面添加了新的图片视图，导致了重叠
        
        guard !images.isEmpty, images.count <= 9 else {
            self.pictureContainerView.isHidden = true
            return
        }
        
        self.pictureContainerView.isHidden = false
        for image in images {
            guard let index = images.firstIndex(of: image) else { return}
            let line = index % 3
            let col = index / 3
            let size = (Constant.componentWidth - Constant.spacingInPictures * 2) / 3
            
            let Yoffset = size * CGFloat(col) + Constant.spacingInPictures * CGFloat(col)
            
            let Xoffset = size * CGFloat(line) + Constant.spacingInPictures * CGFloat(line)
            
            let height = size * CGFloat(col + 1) + Constant.spacingInPictures * CGFloat(col)
            
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.layer.cornerRadius = 12
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(zoomImage))
            imageView.addGestureRecognizer(tap)
            // 长按保存
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressSave))
            imageView.addGestureRecognizer(longPress)
            
            pictureContainerView.addSubview(imageView)
            
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(size)
                make.top.equalToSuperview().inset(Yoffset)
                make.left.equalToSuperview().inset(Xoffset)
            }
            
            pictureContainerView.snp.remakeConstraints{ make in
                make.width.equalTo(Constant.componentWidth)
                make.height.equalTo(height)
                make.top.equalTo(textView.snp.bottom).offset(Constant.componentSpacing)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(10)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     获取当月第一天是星期几
     
     - Parameter date: 当前月份的任意日期
     - Returns: 星期数 (1=Sun, 2=Mon, ..., 7=Sat)
     */
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
    
    /**
     获取所有有日记的日期
     
     1. 从 StorageManager 获取所有日记
     2. 提取日期并格式化
     3. 更新 UI
     */
    private func fetchDiaryDates() {
        
        let year = calendar.component(.year, from: changedDate)
        let month = calendar.component(.month, from: changedDate)
        monthLabel.text = "\(year).\(month)"
        
        let diaries = DiaryStorageManager.shared.getAllDiaries()
        diaryDates = Set(diaries.map { dateFormatter.string(from: $0.date) })
        // fetchDiaryDates calls updateCalendarUI which handles reloadData and constraints
        updateCalendarUI()
    }
    
    // 本来是在dataSource 里面的，改在刷新的时候进行了，每个月份加载的时候进行一次
    /**
     计算当月需要的行数
     
     - Parameter date: 当前月份
     - Returns: 行数 (4, 5, or 6)
     
     算法：
     1. 获取当月天数
     2. 获取第一天偏移量
     3. 计算总格子数
     4. 向上取整除以7
     */
    private func calculateRows(for date: Date) -> Int {
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let firstWeekDayOfMonth = getFirstWeekDayOfMonth(from: date)
        
        var offset = firstWeekDayOfMonth - calendar.firstWeekday
        if offset < 0 {
            offset += 7
        }
        
        let totalCells = offset + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))
        return rows
    }
    
    /// 计算当前日期是否是本月
    private func isThisMonth(of date: Date) -> Bool {
        let month = calendar.component(.month, from: date)
        let thisMonth = calendar.component(.month, from: now)
        
        if month == thisMonth {
            return true
        } else {
            return false
        }
    }
}

// MARK: Respond Methods
extension CalendarViewController {
    /// 左箭头点击：切换到上个月
    @objc private func leftArrowTapped() {
        // 获取上个月的日期
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: changedDate) else { return }
        
        if isThisMonth(of: previousMonthDate) {
            changedDate = now
        } else {
            let component = calendar.dateComponents([.year, .month], from: previousMonthDate)
            guard let firstDayOfMonth = calendar.date(from: component) else { return }
            changedDate = firstDayOfMonth
        }
       
        // 刷新 UI
        updateCalendarUI()
    }
    
    /// 右箭头点击：切换到下个月
    @objc private func rightArrowTapped() {
        // 获取下个月的日期
        guard let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: changedDate) else { return }
        // 更新当前日期
        if isThisMonth(of: nextMonthDate) {
            changedDate = now
        } else {
            let component = calendar.dateComponents([.year, .month], from: nextMonthDate)
            guard let firstDayOfMonth = calendar.date(from: component) else { return }
            changedDate = firstDayOfMonth
        }
        // 刷新 UI
        updateCalendarUI()
    }
    
    /// 添加按钮点击：打开日记编辑页
    @objc private func addButtonTapped() {
        // Open Diary Edit
        let editDiaryVC = DiaryEditViewController()
        editDiaryVC.currentDate = changedDate
        editDiaryVC.modalPresentationStyle = .fullScreen
        self.present(editDiaryVC, animated: true)
    }
    
    /// 处理日记数据更新通知
    @objc private func handleDiaryUpdate() {
        fetchDiaryDates()
    }
    
    /// 点击图片放大
    @objc private func zoomImage(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        ImageZoomManager.shared.zoom(imageView: imageView)
    }
    
    /// 长按图片保存
    @objc private func longPressSave(_ gesture: UILongPressGestureRecognizer) {
        // 只在开始时触发一次
        guard gesture.state == .began else { return }
        
        let alert = UIAlertController(title: "保存图片", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .destructive, handler: { [weak self] _ in
          //  self?.saveToAlbum(imageView: gesture.view?.largeContentImage)
            guard let image = gesture.view?.largeContentImage else { return }
            
            // 保存到相册
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        }))
        present(alert, animated: true)
    }
    
    private func saveToAlbum(imageView: UIImageView) {
        guard let image = imageView.image else { return }
        
        // 保存到相册
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // 保存结果回调
    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let msg = error == nil ? "保存成功" : "保存失败：\(error!.localizedDescription)"
        let alert = UIAlertController(title: "提示", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension CalendarViewController: UIScrollViewDelegate { }

// MARK: - UICollectionViewDelegate

extension CalendarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let firstWeekDayOfMonth = getFirstWeekDayOfMonth(from: changedDate)
        var offset = firstWeekDayOfMonth - calendar.firstWeekday
        if offset < 0 {
            offset += 7
        }
        
        let day = indexPath.item - offset + 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: changedDate)?.count ?? 30
        
        if day > 0 && day <= daysInMonth {
            var dateComponents = calendar.dateComponents([.year, .month], from: changedDate)
            dateComponents.day = day
            
            if let cellDate = calendar.date(from: dateComponents) {
                // 更新选中日期并刷新 UI
                changedDate = cellDate
                collectionView.reloadData()
                
                
                loadData(date: cellDate)
            }
            
            self.addButtonImageView.tag = day
            
            
        }
    }
}

// MARK: - UICollectionViewDataSource

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
                        
            guard let targetDate = calendar.date(from: dateComponents) else {
                print("无法解析 DateComponents 为有效日期")
                return CalendarControllerViewCell()
            }

            
                        
            if let cellDate = calendar.date(from: dateComponents) {
                // 比较 cell 日期和今天 (now)
                // 使用 compare(_:to:toGranularity:) 忽略时分秒差异，只比较日期
                let comparison = calendar.compare(cellDate, to: now, toGranularity: .day)
                let isSelected = calendar.isDate(cellDate, inSameDayAs: changedDate)
                
                // 4. 提取星期几（.weekday 组件）
                let weekday = calendar.component(.weekday, from: targetDate)
                print("weekday:\(weekday)")
                
                if weekday == 2 {
                    rowCount = rowCount + 1
                    print("row1:\(rowCount)")
                }
                
                if isSelected && comparison != .orderedSame { // 解决了今天和选择日期的冲突问题
                    cell.showSelectMarkView(true)
                } else if comparison == .orderedSame {
                    // 是今天
                    cell.showTodayHighLight(true)
                    cell.showSelectMarkView(false)
                } else {
                    cell.showSelectMarkView(false)
                }
                
                if comparison == .orderedAscending {
                    // 今天之前的日期 (过去) -> 显示遮罩 
                    cell.showMaskImageView()
                    
                    // 尝试加载日记背景图
                    if let diary = DiaryStorageManager.shared.getDiary(for: cellDate),
                       let firstPath = diary.imagePaths.first,
                       let image = DiaryStorageManager.shared.loadImage(named: firstPath) {
                        cell.showBackgroundImage(image: image)
                    }
                }
                
                // 检查是否有日记
                //let dateString = dateFormatter.string(from: cellDate)
                //cell.showDiaryIndicator(diaryDates.contains(dateString))
            }
            
            if day == daysInMonth {
                if firstWeekDayOfMonth != 2 {
                    rowCount += 1
                }// 新的问题1 解决，但是 问题2: 我的日历数据无法显示了：问题所在：在刷新过几次以后 rowCount 无限累加了，导致 collectionView 高度很高。。
                print("row:\(rowCount)")
                CalendarCollectionView.snp.remakeConstraints { make in
                    make.top.equalTo(weekTitleStackView.snp.bottom).offset(3)
                    make.width.equalTo(Constant.componentWidth)
                    make.height.equalTo(sigalItemW * rowCount)
                    make.centerX.equalToSuperview()
                }
                rowCount = 0 //问题2 解决
            }// 新的问题1：首次加载出来3月只有5行（29天），但是刷新过又是正常的
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

