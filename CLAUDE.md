# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SaveEye 是一个 macOS 护眼提醒应用，使用 SwiftUI 开发。应用监控用户活动，定时提醒用户休息以保护视力。

### 核心架构

- **SaveEyeApp.swift**: 应用入口，管理两个主要窗口：配置窗口（Config）和护眼窗口（EyeCare）
- **AppState**: 中央状态管理器，协调所有组件之间的交互
- **EyeCareTimer**: 计时器核心，管理工作时间和休息提醒逻辑
- **ActivityMonitor**: 用户活动监控，通过系统事件检测键盘和鼠标活动
- **Settings**: 用户设置持久化，包括运行状态的恢复
- **AppManager**: 应用生命周期管理（单例模式）

### 关键特性

1. **全屏护眼模式**: 创建真正的全屏窗口覆盖所有显示器，隐藏 Dock 和菜单栏
2. **活动检测**: 监控键盘、鼠标活动，无活动时暂停计时
3. **状态持久化**: 应用重启后恢复之前的运行状态
4. **ESC 键退出机制**: 通过 ExitStateMachine 管理复杂的退出逻辑
5. **权限管理**: 需要辅助功能权限进行活动监控

## 常用命令

### 构建和安装

```bash
# 构建应用
make build

# 构建并安装到 /Applications（需要 sudo）
make install-app

# 清理构建文件
make clean

# 显示帮助
make help
```

### Xcode 开发

```bash
# 直接使用 Xcode 构建
xcodebuild -scheme SaveEye -configuration Release build

# 在 Xcode 中开发
open SaveEye.xcodeproj
```

### 测试

```bash
# 运行单元测试
xcodebuild test -scheme SaveEye -destination 'platform=macOS'
```

## 开发要点

### 状态管理流程

1. **AppState** 是中心状态管理器，所有组件状态变化都通过它协调
2. **Settings** 负责持久化，包括 `isProtectionRunning` 和 `lastWorkStartTime`
3. **EyeCareTimer** 通过 Combine 发布 `shouldShowEyeCare` 事件
4. **ActivityMonitor** 实时更新 `lastActivityTime`，计时器据此判断是否暂停

### 全屏护眼实现

- 使用 `NSWindow.Level.screenSaver` 确保窗口在最上层
- 通过 `NSApplication.PresentationOptions` 隐藏系统 UI
- 为每个显示器创建独立的全屏窗口

### 权限处理

- 应用需要辅助功能权限才能监控用户活动
- `ActivityMonitor` 定期检查权限状态
- 配置窗口提供权限申请引导

### 组件依赖关系

```
SaveEyeApp
├── AppState (中央协调器)
│   ├── EyeCareTimer (计时逻辑)
│   ├── ActivityMonitor (活动检测)
│   ├── ExitStateMachine (退出逻辑)
│   ├── EscapeKeyMonitor (ESC键监听)
│   └── Settings (设置持久化)
├── ConfigWindow (配置界面)
└── EyeCareWindow (护眼界面)
```

### 调试建议

- 所有组件都有详细的 print 日志输出
- 测试时可将 `breakIntervalMinutes` 设为 1 分钟以便快速验证
- 使用 `AppState.timerStatus` 查看当前计时器状态
