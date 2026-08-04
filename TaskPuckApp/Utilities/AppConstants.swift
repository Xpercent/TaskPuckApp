import SwiftUI

/// 全局统一常量配置库
public enum AppConstants {
    // MARK: - AppStorage 存储键名
    public enum StorageKeys {
        public static let customColorPresets = "user_custom_color_presets"
        public static let appThemeHex = "app_theme_hex"
        public static let userName = "user_name"
        public static let userAvatarSymbol = "user_avatar_symbol"
    }

    // MARK: - 任务外观与预设配置
    public enum Appearance {
        public static let defaultTintHex = "EE8C8C"
        public static let defaultIconSymbol = "checklist"

        public static let defaultPresetHexes = [
            "F49898", "FF9D73", "E0A800", "8CBD68",
            "5E86A8", "1A8B6B", "8D3F68", "2C4A6F",
            "000000"
        ]

        public static let iconSymbols = [
            "checklist", "alarm.fill", "book.fill", "calendar", "bell.fill",
            "heart.fill", "star.fill", "figure.run", "fork.knife", "moon.fill",
            "house.fill", "briefcase.fill", "flame.fill", "drop.fill", "leaf.fill"
        ]
    }

    // MARK: - 用户个人信息默认值
    public enum Profile {
        public static let defaultUserName = "TaskPuck 用户"
        public static let defaultAvatarSymbol = "person.crop.circle.fill"
        public static let defaultThemeIcon = "paintpalette.fill"
    }

    // MARK: - UI 主题颜色 (全面重构为原生系统动态语义色，自动支持深浅模式)
    public enum Colors {
        /// 全局统一背景色 (系统一级分组背景，深色模式下自动变暗)
        public static let backgroundGrey = Color(uiColor: .systemGroupedBackground)
        /// 全局卡片/容器背景色 (系统二级分组背景，浅色为纯白，深色为深灰卡片)
        public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        /// 主要文字（自动适配深浅模式）
        public static let primaryTextDark = Color.primary
        /// 次要文字颜色（自动适配深浅模式）
        public static let textSecondaryDark = Color.secondary
        /// 首页年份粉色（动态对比度保持）
        public static let yearTextPink = Color(red: 0.93, green: 0.55, blue: 0.55)
        /// 未到达时间的轴线/图标底色（系统动态灰色5）
        public static let unreachedBg = Color(uiColor: .systemGray5)
        /// HEX 编辑器 # 前缀颜色
        public static let hexPrefixPink = Color(red: 0.9, green: 0.4, blue: 0.4)
    }

    // MARK: - 表单选项定义
    public enum TaskForm {
        public static let durationOptions: [DurationOption] = [
            DurationOption(title: "无", minutes: 0),
            DurationOption(title: "15m", minutes: 15),
            DurationOption(title: "30m", minutes: 30),
            DurationOption(title: "45m", minutes: 45),
            DurationOption(title: "1h", minutes: 60),
            DurationOption(title: "1.5h", minutes: 90)
        ]

        public static let weekdayOptions: [WeekdayOption] = [
            WeekdayOption(weekday: .sun, title: "日"),
            WeekdayOption(weekday: .mon, title: "一"),
            WeekdayOption(weekday: .tue, title: "二"),
            WeekdayOption(weekday: .wed, title: "三"),
            WeekdayOption(weekday: .thu, title: "四"),
            WeekdayOption(weekday: .fri, title: "五"),
            WeekdayOption(weekday: .sat, title: "六")
        ]
    }

    // MARK: - 时间轴参数
    public enum Timeline {
        public static let weekOffsetRange = Array(-260...260)
    }

    // MARK: - 任务分类元数据
    public enum Categories {
        public static func title(for category: TaskManagementCategory) -> String {
            switch category {
            case .today: "今天"
            case .daily: "每日"
            case .weekly: "每周"
            case .monthly: "每月"
            case .dateRange: "日期范围"
            case .once: "仅一次"
            }
        }

        public static func iconSymbol(for category: TaskManagementCategory) -> String {
            switch category {
            case .today: "calendar"
            case .daily: "arrow.triangle.2.circlepath"
            case .weekly: "calendar.badge.clock"
            case .monthly: "calendar"
            case .dateRange: "calendar.badge.plus"
            case .once: "1.circle"
            }
        }

        public static func colorHex(for category: TaskManagementCategory) -> String {
            switch category {
            case .today: "4F83CC"
            case .daily: "2C8B73"
            case .weekly: "8D3F68"
            case .monthly: "D58A3A"
            case .dateRange: "6E6AAE"
            case .once: "D05D69"
            }
        }
    }
}

// MARK: - 表单辅助模型
public struct DurationOption: Identifiable, Sendable {
    public let title: String
    public let minutes: Int
    public var id: Int { minutes }

    public init(title: String, minutes: Int) {
        self.title = title
        self.minutes = minutes
    }
}

public struct WeekdayOption: Identifiable, @unchecked Sendable {
    public let weekday: Weekday
    public let title: String
    public var id: Weekday { weekday }

    public init(weekday: Weekday, title: String) {
        self.weekday = weekday
        self.title = title
    }
}