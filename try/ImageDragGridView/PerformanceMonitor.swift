//
//  PerformanceMonitor.swift
//  TESTDRAG
//
//  Created by Claude on 2025/8/26.
//

import UIKit

/**
 * 性能监控助手
 *
 * 提供内存使用监控、FPS 监控和性能分析工具
 * 帮助优化应用性能和识别性能瓶颈
 */
class PerformanceMonitor {
    
    // MARK: - Singleton
    
    static let shared = PerformanceMonitor()
    
    private init() {}
    
    // MARK: - Memory Monitoring
    
    /**
     * 获取当前内存使用情况
     *
     * @return 内存使用量（MB）
     */
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
    
    /**
     * 检查内存警告阈值
     *
     * @return 是否接近内存警告
     */
    func isApproachingMemoryWarning() -> Bool {
        let currentUsage = getCurrentMemoryUsage()
        let warningThreshold: Double = 100 // MB
        
        return currentUsage > warningThreshold
    }
    
    /**
     * 记录内存使用情况
     *
     * @param context 上下文描述
     */
    func logMemoryUsage(context: String = "") {
        let usage = getCurrentMemoryUsage()
        print("🧠 Memory Usage \(context): \(String(format: "%.2f", usage)) MB")
        
        if isApproachingMemoryWarning() {
            print("⚠️ Warning: High memory usage detected!")
        }
    }
    
    // MARK: - Performance Timing
    
    private var timers: [String: CFAbsoluteTime] = [:]
    
    /**
     * 开始性能计时
     *
     * @param identifier 计时器标识符
     */
    func startTimer(_ identifier: String) {
        timers[identifier] = CFAbsoluteTimeGetCurrent()
    }
    
    /**
     * 结束性能计时并记录结果
     *
     * @param identifier 计时器标识符
     * @return 执行时间（秒）
     */
    @discardableResult
    func endTimer(_ identifier: String) -> Double {
        guard let startTime = timers[identifier] else {
            print("⚠️ Timer '\(identifier)' not found")
            return 0
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        timers.removeValue(forKey: identifier)
        
        print("⏱️ Performance [\(identifier)]: \(String(format: "%.4f", duration))s")
        return duration
    }
    
    /**
     * 测量代码块执行时间
     *
     * @param identifier 标识符
     * @param block 要测量的代码块
     * @return 执行时间（秒）
     */
    @discardableResult
    func measureTime<T>(_ identifier: String, block: () throws -> T) rethrows -> (result: T, duration: Double) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        print("⏱️ Performance [\(identifier)]: \(String(format: "%.4f", duration))s")
        return (result, duration)
    }
    
    // MARK: - View Hierarchy Analysis
    
    /**
     * 分析视图层级复杂度
     *
     * @param view 根视图
     * @return 层级深度和视图数量
     */
    func analyzeViewHierarchy(_ view: UIView) -> (depth: Int, viewCount: Int) {
        var maxDepth = 0
        var totalViews = 0
        
        func traverse(_ currentView: UIView, currentDepth: Int) {
            totalViews += 1
            maxDepth = max(maxDepth, currentDepth)
            
            for subview in currentView.subviews {
                traverse(subview, currentDepth: currentDepth + 1)
            }
        }
        
        traverse(view, currentDepth: 0)
        
        print("🏗️ View Hierarchy - Depth: \(maxDepth), Views: \(totalViews)")
        return (depth: maxDepth, viewCount: totalViews)
    }
    
    // MARK: - Animation Performance
    
    /**
     * 监控动画性能
     *
     * @param animationBlock 动画代码块
     * @param identifier 动画标识符
     */
    func monitorAnimation(_ identifier: String, animationBlock: @escaping () -> Void) {
        startTimer("Animation_\(identifier)")
        
        animationBlock()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.endTimer("Animation_\(identifier)")
        }
    }
    
    // MARK: - Image Processing Performance
    
    /**
     * 监控图片处理性能
     *
     * @param imageCount 处理的图片数量
     * @param processingBlock 图片处理代码块
     */
    func monitorImageProcessing(imageCount: Int, processingBlock: @escaping () -> Void) {
        logMemoryUsage(context: "Before Image Processing")
        startTimer("ImageProcessing_\(imageCount)")
        
        processingBlock()
        
        endTimer("ImageProcessing_\(imageCount)")
        logMemoryUsage(context: "After Image Processing")
    }
    
    // MARK: - Layout Performance
    
    /**
     * 监控布局性能
     *
     * @param viewCount 参与布局的视图数量
     * @param layoutBlock 布局代码块
     */
    func monitorLayout(viewCount: Int, layoutBlock: @escaping () -> Void) {
        startTimer("Layout_\(viewCount)_views")
        
        layoutBlock()
        
        endTimer("Layout_\(viewCount)_views")
    }
}

// MARK: - Performance Extensions

extension UIView {
    
    /**
     * 分析当前视图的性能状态
     */
    func analyzePerformance() {
        PerformanceMonitor.shared.analyzeViewHierarchy(self)
        
        // 检查可能的性能问题
        checkForPerformanceIssues()
    }
    
    private func checkForPerformanceIssues() {
        var issues: [String] = []
        
        // 检查透明度相关问题
        if alpha < 1.0 && alpha > 0.0 {
            issues.append("半透明视图可能影响性能")
        }
        
        // 检查圆角和阴影
        if layer.cornerRadius > 0 && layer.masksToBounds == false {
            issues.append("圆角和阴影同时使用可能影响性能")
        }
        
        // 检查子视图数量
        if subviews.count > 20 {
            issues.append("子视图过多 (\(subviews.count)) 可能影响性能")
        }
        
        if !issues.isEmpty {
            print("⚠️ 性能警告 - \(issues.joined(separator: ", "))")
        }
    }
}

// MARK: - ImageGridManager Performance Extension

extension ImageGridManager {
    
    /**
     * 监控布局性能的增强版更新方法
     */
    func updatePositionsWithPerformanceMonitoring(
        for imageViews: [UIImageView],
        excluding excludedView: UIImageView? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        PerformanceMonitor.shared.monitorLayout(viewCount: imageViews.count) {
            self.updatePositions(
                for: imageViews,
                excluding: excludedView,
                animated: animated,
                completion: completion
            )
        }
    }
}