# SaveEye macOS 应用构建和安装 Makefile

# 项目配置
PROJECT_NAME = SaveEye
SCHEME = SaveEye
CONFIGURATION = Release
BUILD_DIR = build
DERIVED_DATA_PATH = $(BUILD_DIR)/DerivedData
VERSION = $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")

# 应用路径
APP_NAME = $(PROJECT_NAME).app
BUILT_APP_PATH = $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME)
INSTALL_PATH = /Applications/$(APP_NAME)
DIST_ZIP = $(BUILD_DIR)/$(CONFIGURATION)/$(PROJECT_NAME)-unsigned.zip
DMG_DIR = $(BUILD_DIR)/dmg
DMG_PATH = $(BUILD_DIR)/$(CONFIGURATION)/$(PROJECT_NAME)-$(VERSION)

# GitHub 仓库信息
GITHUB_USER = samzong
GITHUB_REPO = SaveEye
HOMEBREW_TAP_REPO = homebrew-tap

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

# 构建应用（无签名版本，用于 CI）
build-unsigned:
	@echo "🔨 构建 $(PROJECT_NAME) 应用 (无签名版本)..."
	@mkdir -p $(BUILD_DIR)
	xcodebuild \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-destination 'platform=macOS' \
		build \
		SYMROOT=$(BUILD_DIR) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO
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

# 创建 DMG 安装包
dmg: build
	@echo "📦 创建 DMG 安装包..."
	@mkdir -p $(DMG_DIR)
	@cp -R "$(BUILT_APP_PATH)" $(DMG_DIR)/
	@ln -sf /Applications $(DMG_DIR)/Applications
	@echo "Creating DMG for $(VERSION)..."
	@hdiutil create -volname "$(PROJECT_NAME) $(VERSION)" \
		-srcfolder $(DMG_DIR) \
		-ov -format UDZO \
		"$(DMG_PATH)-x86_64.dmg"
	@cp "$(DMG_PATH)-x86_64.dmg" "$(DMG_PATH)-arm64.dmg"
	@echo "✅ DMG 创建完成！"
	@echo "📍 x86_64 DMG: $(DMG_PATH)-x86_64.dmg"
	@echo "📍 arm64 DMG: $(DMG_PATH)-arm64.dmg"

# 创建 DMG 安装包（无签名版本，用于 CI）
dmg-unsigned: build-unsigned
	@echo "📦 创建 DMG 安装包 (无签名版本)..."
	@mkdir -p $(DMG_DIR)
	@cp -R "$(BUILT_APP_PATH)" $(DMG_DIR)/
	@ln -sf /Applications $(DMG_DIR)/Applications
	@echo "Creating DMG for $(VERSION)..."
	@hdiutil create -volname "$(PROJECT_NAME) $(VERSION)" \
		-srcfolder $(DMG_DIR) \
		-ov -format UDZO \
		"$(DMG_PATH)-x86_64.dmg"
	@cp "$(DMG_PATH)-x86_64.dmg" "$(DMG_PATH)-arm64.dmg"
	@echo "✅ DMG 创建完成！"
	@echo "📍 x86_64 DMG: $(DMG_PATH)-x86_64.dmg"
	@echo "📍 arm64 DMG: $(DMG_PATH)-arm64.dmg"

# 更新 Homebrew Cask
update-homebrew:
	@echo "🍺 更新 Homebrew Cask..."
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ 需要版本号: make update-homebrew VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "Downloading DMG files and calculating checksums..."
	@ARM64_URL="https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/releases/download/v$(VERSION)/$(PROJECT_NAME)-$(VERSION)-arm64.dmg"; \
	X86_64_URL="https://github.com/$(GITHUB_USER)/$(GITHUB_REPO)/releases/download/v$(VERSION)/$(PROJECT_NAME)-$(VERSION)-x86_64.dmg"; \
	ARM64_SHA=$$(curl -sL "$$ARM64_URL" | shasum -a 256 | cut -d' ' -f1); \
	X86_64_SHA=$$(curl -sL "$$X86_64_URL" | shasum -a 256 | cut -d' ' -f1); \
	echo "ARM64 SHA256: $$ARM64_SHA"; \
	echo "X86_64 SHA256: $$X86_64_SHA"; \
	TEMP_DIR=$$(mktemp -d); \
	cd "$$TEMP_DIR"; \
	git clone https://github.com/$(GITHUB_USER)/$(HOMEBREW_TAP_REPO).git; \
	cd $(HOMEBREW_TAP_REPO); \
	sed -i '' "s/version \".*\"/version \"$(VERSION)\"/" Casks/saveeye.rb; \
	sed -i '' "s|arm:.*|arm:   \"$$ARM64_SHA\"|" Casks/saveeye.rb; \
	sed -i '' "s|intel:.*|intel: \"$$X86_64_SHA\"|" Casks/saveeye.rb; \
	git add Casks/saveeye.rb; \
	git commit -m "Update SaveEye to version $(VERSION)"; \
	git push; \
	rm -rf "$$TEMP_DIR"
	@echo "✅ Homebrew Cask 更新完成！"

# 显示帮助信息
help:
	@echo "SaveEye 构建工具使用说明："
	@echo ""
	@echo "可用命令："
	@echo "  make build           - 构建 SaveEye 应用 (开发者签名版本)"
	@echo "  make build-unsigned  - 构建应用 (无签名版本，用于 CI/发布)"
	@echo "  make install-app     - 构建并安装应用到 /Applications"
	@echo "  make dmg             - 创建 DMG 安装包 (开发者签名版本)"
	@echo "  make dmg-unsigned    - 创建 DMG 安装包 (无签名版本，用于发布)"
	@echo "  make update-homebrew - 更新 Homebrew Cask (暂时不可用)"
	@echo "  make version         - 更新版本号 (需要 VERSION 参数)"
	@echo "  make clean           - 清理构建文件"
	@echo "  make help            - 显示此帮助信息"
	@echo ""
	@echo "📝 注意事项："
	@echo "  • install-app 需要管理员权限 (sudo)"
	@echo "  • 安装前会自动删除已存在的旧版本"
	@echo "  • 构建文件存储在 ./build 目录中"
	@echo "  • DMG 包会为 x86_64 和 arm64 架构创建"
	@echo ""
	@echo "🚀 快速开始："
	@echo "  make install-app          # 一键构建并安装 (本地使用)"
	@echo "  make dmg-unsigned         # 创建无签名 DMG (用于发布)"
	@echo "  make version VERSION=1.1.0 # 更新版本号"

# 声明伪目标
.PHONY: build build-unsigned install-app dmg dmg-unsigned update-homebrew version clean help

.DEFAULT_GOAL := help