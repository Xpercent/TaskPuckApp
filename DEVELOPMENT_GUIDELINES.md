# 📘 SwiftUI 代码开发规范指南 (AI Agent 必读)

> ⚠️ **AI Agent 强制执行指令 (Mandatory Pre-requisite)**:
> 在读取、修改或编写任何 Swift / SwiftUI 代码之前，**必须首先读取并理解以下两个核心基础设施文件**：
>
> 1. **`AppConstants.swift`**（掌握全局常量、主题颜色、存储 Key、表单选项与分类元数据）
> 2. **`UIComponents.swift`**（掌握项目已抽象的原子化 UI 组件及其 Mode 变体）
>
> **严禁在未读取上述两个文件的情况下直接生成、修改或重构视图代码！**

---

## 目录

1. [硬编码零容忍与全局常量集 (`AppConstants.swift`)](#1-硬编码零容忍与全局常量集-appconstants)
2. [命名一致性规范 (消除“一物多名”)](#2-命名一致性规范-消除一物多名)
3. [原子化 UI 组件复用规范 (`UIComponents.swift`)](#3-原子化-ui-组件复用规范-uicomponents)
4. [严格并发安全 (Strict Concurrency & Sendable)](#4-严格并发安全-strict-concurrency--sendable)
5. [AI Agent 代码提交前自查清单 (Checklist)](#5-ai-agent-代码提交前自查清单-checklist)

---

## 1. 硬编码零容忍与全局常量集 (`AppConstants`)

**原则**：禁止在视图 (`View`) 或业务逻辑 (`Engine/ViewModel`) 中直接硬编码任何文字、颜色、尺寸、AppStorage 键名或表单预设。

### 规则要求：

- **存储键名**：必须使用 `AppConstants.StorageKeys.*`。
- **主题与颜色**：必须使用 `AppConstants.Colors.*` 或 `AppConstants.Appearance.defaultTintHex`。
- **预设数组与选项**：表单时长、星期选择、图标列表必须从 `AppConstants.TaskForm.*` 或 `AppConstants.Appearance.*` 引用。

❌ **反面示例 (BAD)**:

```swift
// 严禁在 View 中直接硬编码
@AppStorage("user_custom_color_presets") private var raw = ""
let bg = Color(red: 0.96, green: 0.96, blue: 0.97)
let defaultHex = "EE8C8C"
```

✅ **正面示例 (GOOD)**:

```swift
@AppStorage(AppConstants.StorageKeys.customColorPresets) private var raw = ""
let bg = AppConstants.Colors.backgroundGrey
let defaultHex = AppConstants.Appearance.defaultTintHex
```

---

## 2. 命名一致性规范 (消除“一物多名”)

**原则**：贯穿“模型层 $\rightarrow$ 视图逻辑层 $\rightarrow$ 视图渲染层 $\rightarrow$ 事件回调”的全链路，核心概念的命名必须严格统一，禁止混用含义相近的别名或缩写。

### 术语映射标准表：

| 业务概念           | 模型层 (Model/Engine)            | 视图状态/计算属性 (View)   | 事件回调/动作 (Action) | 禁用别名 (Forbidden)                     |
| :----------------- | :------------------------------- | :------------------------- | :--------------------- | :--------------------------------------- |
| **任务完成状态**   | `InstanceStatus == .done`        | `isDone: Bool`             | `onToggle: () -> Void` | `isCompleted`, `completed`, `statusBool` |
| **排期与时间汇总** | `defaultPlacement` / `placement` | `placementSummary: String` | -                      | `placementText`, `headerSummaryText`     |
| **外观主题色**     | `tintHex: String`                | `tintHex: String`          | -                      | `color`, `hexString`, `themeColor`       |
| **图标名称**       | `iconSymbol: String`             | `iconSymbol: String`       | -                      | `icon`, `symbolName`, `imageName`        |

❌ **反面示例 (BAD)**:

```swift
// 同一项目中不同的 Row 视图给勾选状态取不同的名字
@State private var isCompleted = false // ❌
let completedStatus: Bool              // ❌
let placementText: String              // ❌
```

✅ **正面示例 (GOOD)**:

```swift
@State private var isDone = false      // ✅ 全局统一
let isDone: Bool                       // ✅
private var placementSummary: String   // ✅ 统一描述排期文本
```

---

## 3. 原子化 UI 组件复用规范 (`UIComponents`)

**原则**：当某个 UI 结构的逻辑或几何形状在多处出现时，**严禁手写重复代码**，必须抽离为 `UIComponents.swift` 中的原子组件，并支持必要的**变体模式 (Mode/Variant)**。

### 核心标准组件规范：

#### 1. 任务勾选框组件 `TaskStatusCheckbox`

- **规则**：凡是涉及任务完成/未完成状态切换的按钮，必须统一调用 `TaskStatusCheckbox`。
- **变体支持**：
  - `.standard`：用于白色/浅色背景（彩色边框，选中后彩色填充 + 白色勾）。
  - `.inverted`：用于彩色 Header 背景（白色边框，选中后白色填充 + 主题色勾）。

```swift
// ✅ 统一使用原子组件
TaskStatusCheckbox(
    isDone: item.instance?.status == .done,
    tintColor: Color(hex: item.task.tintHex),
    mode: .standard,
    onToggle: onToggle
)
```

---

## 4. 严格并发安全 (Strict Concurrency & Sendable)

**原则**：全代码库需符合 Swift 6 严格并发检查标准。

1. **静态全局常量**：`AppConstants` 中包含的结构体/数组必须符合 `Sendable` 协议。
2. **外部不可变模型桥接**：对于引用了外部模型的结构体（如包装了 `Weekday` 枚举的 `WeekdayOption`），显式标注 `@unchecked Sendable` 以确保编译零 Error/Warning。
3. **UI 线程隔离**：所有 SwiftUI View 及其子组件自动运行在 `@MainActor` 隔离域。

---

## 5. AI Agent 代码提交前自查清单 (Checklist)

在生成或修改任何 Swift 代码后，AI Agent **必须**按照以下清单进行逐项自查：

- [ ] **[前置文件读取]** 是否在编码前已读取 `AppConstants.swift` 和 `UIComponents.swift`？
- [ ] **[硬编码检查]** 视图代码中是否存在 `Color(red:green:blue:)` 或 `"EE8C8C"` 等硬编码值？（必须迁移至 `AppConstants`）
- [ ] **[组件复用检查]** 是否在视图中手写了可复用组件
- [ ] **[命名一致性检查]** 避免一物多名
