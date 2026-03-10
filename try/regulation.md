
# iOS 项目注释规范（Swift）

## 一、注释的基本原则

### 1. 注释的核心目的

注释不是解释代码“做了什么”，而是解释：

* 为什么这样设计
* 代码的意图
* 复杂逻辑的原理
* 使用方法
* 注意事项

示例：

❌ 无意义注释

```swift
// 设置标题
titleLabel.text = "Hello"
```

代码本身已经说明了。

---

✅ 有价值的注释

```swift
// 为了避免 TableView 重用导致的闪烁问题，必须在此处重置图片
imageView.image = nil
```

解释 **原因**。

---

### 2. 好的注释标准

好的注释应满足：

| 标准   | 说明        |
| ---- | --------- |
| 准确   | 与代码保持一致   |
| 简洁   | 不冗长       |
| 解释原因 | 不只是描述行为   |
| 维护性  | 修改代码时同步更新 |

---

### 3. 不应该写的注释

以下情况**不要写注释**：

| 情况     | 示例          |
| ------ | ----------- |
| 解释简单代码 | `// 给变量赋值`  |
| 重复代码逻辑 | `// 循环遍历数组` |
| 废弃代码   | 不要保留        |

❌

```swift
// old code
// tableView.reloadData()
```

应直接删除。

---

# 二、文件级注释规范

每个 Swift 文件建议包含文件说明。

格式：

```swift
//
//  LoginViewController.swift
//  DemoApp
//
//  Created by Author on 2026/03/10.
//

/**
 Login 页面控制器

 功能：
 1. 用户登录
 2. 输入验证
 3. 登录请求

 设计模式：
 MVVM

 主要职责：
 - 管理 UI
 - 绑定 ViewModel
 - 响应用户操作
 */
```

---

# 三、类（Class）注释规范

每个重要类都应有说明。

推荐使用 **Swift 文档注释 `///`**

示例：

```swift
/// 用户管理器
///
/// 负责处理用户相关业务逻辑，例如：
/// - 登录
/// - 登出
/// - 获取用户信息
///
/// 设计原则：
/// 该类只负责业务逻辑，不负责 UI
class UserManager {
}
```

---

# 四、属性（Property）注释规范

当属性具有业务意义时，需要说明。

示例：

```swift
/// 当前登录用户
var currentUser: User?

/// 登录状态
var isLogin: Bool = false
```

---

复杂属性：

```swift
/// 最大重试次数
/// 防止网络异常导致无限请求
private let maxRetryCount = 3
```

---

# 五、方法（Function）注释规范

方法注释是最重要的一部分。

使用 **Swift 标准格式**

```
/**
 方法说明

 - Parameter 参数名: 参数说明
 - Returns: 返回值说明
 - Throws: 抛出错误
 */
```

示例：

```swift
/**
 登录接口

 - Parameter username: 用户名
 - Parameter password: 密码
 - Returns: 登录结果
 */
func login(username: String, password: String) -> Bool {
    return true
}
```

---

### 更完整示例

```swift
/**
 获取用户信息

 - Parameter userId: 用户唯一ID
 - Parameter completion: 请求完成回调
 - Returns: 无返回值

 注意：
 该方法在后台线程执行
 */
func fetchUserInfo(userId: String,
                   completion: @escaping (User?) -> Void) {
}
```

---

# 六、复杂逻辑注释

复杂算法必须写注释。

示例：

```swift
// 二分查找算法
// 时间复杂度 O(log n)
func binarySearch(_ array: [Int], target: Int) -> Int? {
    
    var left = 0
    var right = array.count - 1
    
    while left <= right {
        
        // 计算中间位置
        let mid = (left + right) / 2
        
        if array[mid] == target {
            return mid
        } else if array[mid] < target {
            left = mid + 1
        } else {
            right = mid - 1
        }
    }
    
    return nil
}
```

---

# 七、代码块注释

对于一段逻辑代码，需要说明逻辑。

示例：

```swift
// MARK: - 数据加载流程
// 1. 检查缓存
// 2. 如果缓存存在直接返回
// 3. 如果缓存不存在请求网络
// 4. 更新缓存
```

---

# 八、MARK 分区规范

Swift 项目强烈推荐使用 `MARK` 进行代码分区。

示例：

```swift
class HomeViewController: UIViewController {

    // MARK: - UI
    
    private let tableView = UITableView()
    
    
    // MARK: - Data
    
    private var articles: [Article] = []
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - Setup
    
    private func setupUI() {
    }
    
    
    // MARK: - Network
    
    private func fetchData() {
    }
}
```

这样 Xcode 会自动显示目录结构。

---

# 九、TODO / FIXME 规范

### TODO

表示未来需要完成。

```swift
// TODO: 添加缓存机制
```

---

### FIXME

表示代码存在问题。

```swift
// FIXME: 这里存在内存泄漏
```

---

### WARNING

提示注意事项。

```swift
// WARNING: 必须在主线程调用
```

---

# 十、扩展（Extension）注释

每个 extension 应该说明用途。

示例：

```swift
// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {
}
```

---

# 十一、UI 组件注释

对于自定义组件必须说明用途。

示例：

```swift
/// 星级评分组件
///
/// 支持三种评分模式：
/// 1. 完整星
/// 2. 半星
/// 3. 无限精度
class StarRateView: UIView {
}
```

（你之前写的 `StarRateView` 就属于这种情况）

---

# 十二、网络接口注释

示例：

```swift
/// 获取文章列表
///
/// API: GET /api/articles
///
/// 参数:
/// - page: 页码
/// - pageSize: 每页数量
///
/// 返回:
/// - ArticleListResponse
func fetchArticles(page: Int) {
}
```

---

# 十三、示例代码注释

如果方法复杂，可以给使用示例。

```swift
/**
 计算折扣价格
 
 示例：
 
 let price = calculateDiscount(100, 0.8)
 print(price) // 80
 */
```

---

# 十四、项目推荐注释比例

推荐：

| 类型   | 注释比例 |
| ---- | ---- |
| 业务逻辑 | 20%  |
| 算法代码 | 40%  |
| UI代码 | 10%  |
| 简单代码 | 0%   |

不要：

```swift
注释 > 代码
```

---

# 十五、最终注释示例（工程级）

```swift
/// 用户列表控制器
///
/// 功能：
/// 1. 展示用户列表
/// 2. 支持分页加载
/// 3. 支持下拉刷新
///
/// 架构：
/// MVVM
class UserListViewController: UIViewController {

    // MARK: - UI
    
    /// 用户列表
    private let tableView = UITableView()
    
    
    // MARK: - Data
    
    /// 当前页码
    private var page = 1
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadData()
    }
    
    
    // MARK: - Setup
    
    /// 初始化 UI
    private func setupUI() {
        view.addSubview(tableView)
    }
    
    
    // MARK: - Network
    
    /**
     加载用户数据
     
     数据流程：
     1. 请求服务器
     2. 解析数据
     3. 更新 UI
     */
    private func loadData() {
        
        // TODO: 添加缓存机制
        
    }
}
```

---

# 总结

一个优秀的 iOS 项目注释应该做到：

1️⃣ 解释 **为什么这样写**
2️⃣ 使用 **Swift 文档注释格式**
3️⃣ 使用 **MARK 结构化代码**
4️⃣ 为 **类 / 方法 / 复杂逻辑写注释**
5️⃣ 不写无意义注释
