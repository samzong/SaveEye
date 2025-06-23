# SaveEye 发布指南

本文档说明如何发布 SaveEye 的新版本。

## 准备发布

### 1. 更新版本号
```bash
make version VERSION=1.1.0
```

### 2. 更新 CHANGELOG.md
在 `CHANGELOG.md` 中添加新版本的更新内容，包括：
- Added: 新增功能
- Changed: 功能改进
- Fixed: Bug 修复
- Removed: 移除的功能

### 3. 提交更改
```bash
git add .
git commit -m "chore: prepare release v1.1.0"
git push origin main
```

## 发布流程

### 自动发布（推荐）

1. 创建并推送 Git 标签：
```bash
git tag v1.1.0
git push origin v1.1.0
```

2. GitHub Actions 会自动：
   - 构建 DMG 安装包
   - 创建 GitHub Release
   - 上传安装包到 Release
   - 触发 Homebrew Cask 更新

### 手动发布

如果需要手动操作：

1. 构建 DMG：
```bash
make dmg VERSION=1.1.0
```

2. 手动创建 GitHub Release 并上传 DMG 文件

3. 更新 Homebrew Cask：
```bash
make update-homebrew VERSION=1.1.0
```

## 验证发布

### 检查 GitHub Release
- 确认 Release 页面包含正确的版本号和发布说明
- 验证 DMG 文件可以正常下载

### 测试 Homebrew 安装
```bash
brew tap samzong/tap
brew install saveeye
```

### 测试应用功能
- 启动应用
- 验证核心功能正常
- 检查版本号是否正确

## 故障排除

### GitHub Actions 失败
- 检查 Xcode 版本兼容性
- 验证代码签名设置
- 查看 Actions 日志定位问题

### Homebrew 更新失败
- 检查 DMG 文件 URL 是否正确
- 验证 SHA256 校验值
- 确认 PERSONAL_ACCESS_TOKEN 权限

### DMG 创建失败
- 检查 build 目录权限
- 验证应用签名状态
- 确认 hdiutil 命令可用

## 注意事项

1. **版本号格式**：使用语义化版本号 (vX.Y.Z)
2. **代码签名**：确保应用已正确签名
3. **权限设置**：需要 GitHub PERSONAL_ACCESS_TOKEN
4. **测试验证**：发布前进行充分测试