# SaveEye

一个极简的 macOS 护眼提醒应用，帮助你养成健康的用眼习惯。

## 功能特点

- **定时提醒** - 每隔一段时间提醒你休息眼睛
- **全屏护眼** - 休息时全屏显示护眼界面，强制休息
- **智能检测** - 自动监测键盘鼠标活动，无活动时暂停计时
- **个性设置** - 可自定义工作时长、休息时长等参数
- **极简体验** - 支持开机自启动，不占用 Dock 和菜单栏
- **护眼设计** - 采用深色背景和柔和动画，减少视觉疲劳

## 安装方式

### 通过 Homebrew 安装（推荐）

```bash
brew tap samzong/tap
brew install saveeye
```

### 手动安装

1. 从 [Releases](https://github.com/samzong/SaveEye/releases) 页面下载对应架构的 DMG 文件
2. 双击安装到 Applications 文件夹

### 源码编译

```bash
# 克隆项目
git clone https://github.com/samzong/SaveEye.git
cd SaveEye

# 一键构建并安装
make install-app
```

### 使用说明

1. 启动应用后，首次使用需要授予**辅助功能权限**
2. 在配置窗口设置工作时长（默认 20 分钟）和休息时长（默认 20 秒）
3. 点击"开始保护"即可开始护眼计时
4. 到时间后会自动全屏显示休息提醒，按 ESC 键可退出

## 系统要求

- macOS 15+
- 需要辅助功能权限（用于监测用户活动）

## 开发指南

### 构建命令

```bash
make build           # 构建应用
make dmg             # 创建 DMG 安装包
make install-app     # 构建并安装到 /Applications
make clean           # 清理构建文件
make help            # 显示帮助信息
```

### 发布流程

```bash
# 1. 更新版本号
make version VERSION=1.1.0

# 2. 提交更改并创建标签
git add .
git commit -m "chore: prepare release v1.1.0"
git tag v1.1.0
git push origin main
git push origin v1.1.0
```

GitHub Actions 会自动构建并发布新版本。

### 项目架构

- **SaveEyeApp.swift** - 应用入口，管理窗口
- **AppState** - 中央状态管理器
- **EyeCareTimer** - 护眼计时核心逻辑
- **ActivityMonitor** - 用户活动监控
- **Settings** - 设置持久化

详细开发说明请参考 [RELEASE.md](RELEASE.md)。

## License

[MIT License](LICENSE)
