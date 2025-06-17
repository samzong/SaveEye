# SaveEye macOS 应用构建和安装 Makefile

# 项目配置
PROJECT_NAME = SaveEye
SCHEME = SaveEye
CONFIGURATION = Release
BUILD_DIR = build
DERIVED_DATA_PATH = $(BUILD_DIR)/DerivedData

# 应用路径
APP_NAME = $(PROJECT_NAME).app
BUILT_APP_PATH = $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME)
INSTALL_PATH = /Applications/$(APP_NAME)
DIST_ZIP = $(BUILD_DIR)/$(CONFIGURATION)/$(PROJECT_NAME)-unsigned.zip

# 构建应用
build:
	@echo "🔨 构建 $(PROJECT_NAME) 应用..."
	@mkdir -p $(BUILD_DIR)
	xcodebuild \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-destination 'platform=macOS' \
		build \
		SYMROOT=$(BUILD_DIR)
	@echo "🧹 清理扩展属性..."
	@xattr -cr "$(BUILT_APP_PATH)"
	@echo "📦 打包分发版本..."
	@cd "$(BUILD_DIR)/$(CONFIGURATION)" && zip -r "$(PROJECT_NAME)-unsigned.zip" "$(APP_NAME)"
	@echo "✅ 构建完成！"
	@echo "📍 应用位置: $(BUILT_APP_PATH)"
	@echo "📦 分发包位置: $(DIST_ZIP)"

# 安装应用到 /Applications
install-app: build
	@echo "📦 安装 $(PROJECT_NAME) 到 /Applications..."
	@if [ -d "$(INSTALL_PATH)" ]; then \
		echo "⚠️  发现已安装的版本，正在删除..."; \
		sudo rm -rf "$(INSTALL_PATH)"; \
	fi
	@if [ -d "$(BUILT_APP_PATH)" ]; then \
		sudo cp -R "$(BUILT_APP_PATH)" /Applications/; \
		echo "✅ $(PROJECT_NAME) 已成功安装到 /Applications!"; \
		echo "🚀 您可以从 Launchpad 或 Applications 文件夹启动应用"; \
	else \
		echo "❌ 错误: 找不到构建的应用文件 $(BUILT_APP_PATH)"; \
		echo "💡 请先运行 'make build' 构建应用"; \
		exit 1; \
	fi

# 更新版本号
version:
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ 请指定版本号: make version VERSION=1.1.0"; \
		exit 1; \
	fi
	@echo "📝 更新版本号到 $(VERSION)..."
	@sed -i '' 's/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $(VERSION)/g' SaveEye.xcodeproj/project.pbxproj
	@echo "✅ 版本号已更新到 $(VERSION)"
	@echo "💡 请运行 'make build' 重新构建应用"

# 清理构建文件
clean:
	@echo "🧹 清理构建文件..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ 清理完成！"

# 显示帮助信息
help:
	@echo "SaveEye 构建工具使用说明："
	@echo ""
	@echo "可用命令："
	@echo "  make build        - 构建 SaveEye 应用并打包分发版本"
	@echo "  make install-app  - 构建并安装应用到 /Applications"
	@echo "  make version      - 更新版本号 (需要 VERSION 参数)"
	@echo "  make clean        - 清理构建文件"
	@echo "  make help         - 显示此帮助信息"
	@echo ""
	@echo "📝 注意事项："
	@echo "  • install-app 需要管理员权限 (sudo)"
	@echo "  • 安装前会自动删除已存在的旧版本"
	@echo "  • 构建文件存储在 ./build 目录中"
	@echo "  • build 命令会自动生成用于分发的 zip 包"
	@echo ""
	@echo "🚀 快速开始："
	@echo "  make install-app           # 一键构建并安装"
	@echo "  make version VERSION=1.1.0 # 更新版本号" 

# 声明伪目标
.PHONY: build install-app version clean help

.DEFAULT_GOAL := help