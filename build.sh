#!/bin/bash

# 多平台构建脚本 - Linux/macOS
# 支持构建所有平台或指定平台

set -e

BIN_NAME="reset-traffic"
OUTPUT_DIR="build"

# 所有支持的平台
ALL_PLATFORMS=(
    "windows/amd64/.exe"
    "windows/arm64/.exe"
    "linux/amd64/"
    "linux/arm64/"
    "darwin/amd64/"
    "darwin/arm64/"
)

# 显示帮助信息
show_help() {
    echo "用法: $0 [平台...]"
    echo ""
    echo "构建 Reset S-UI Traffic 二进制文件"
    echo ""
    echo "选项:"
    echo "  无参数          构建所有平台"
    echo "  平台列表        只构建指定平台"
    echo ""
    echo "支持的平台:"
    echo "  windows/amd64   Windows 64位 (Intel/AMD)"
    echo "  windows/arm64   Windows ARM64"
    echo "  linux/amd64     Linux 64位 (Intel/AMD)"
    echo "  linux/arm64     Linux ARM64"
    echo "  darwin/amd64    macOS Intel"
    echo "  darwin/arm64    macOS Apple Silicon"
    echo ""
    echo "示例:"
    echo "  $0                      # 构建所有平台"
    echo "  $0 linux/amd64          # 只构建 Linux AMD64"
    echo "  $0 linux/amd64 linux/arm64  # 构建 Linux 两个架构"
    echo ""
}

# 解析命令行参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 确定要构建的平台
if [ $# -eq 0 ]; then
    # 无参数，构建所有平台
    PLATFORMS=("${ALL_PLATFORMS[@]}")
    echo "========================================="
    echo "  多平台构建 - Reset S-UI Traffic"
    echo "  构建所有平台"
    echo "========================================="
else
    # 有参数，只构建指定平台
    PLATFORMS=()
    for target in "$@"; do
        found=false
        for platform in "${ALL_PLATFORMS[@]}"; do
            IFS='/' read -r os arch ext <<< "$platform"
            if [ "$target" = "$os/$arch" ]; then
                PLATFORMS+=("$platform")
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            echo "错误: 不支持的平台 '$target'"
            echo "运行 '$0 --help' 查看支持的平台"
            exit 1
        fi
    done
    
    echo "========================================="
    echo "  多平台构建 - Reset S-UI Traffic"
    echo "  构建平台: $@"
    echo "========================================="
fi

echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检测是否安装 UPX
UPX_AVAILABLE=false
if command -v upx &> /dev/null; then
    UPX_AVAILABLE=true
    echo "✓ 检测到 UPX，将自动压缩二进制文件"
    echo ""
fi

# 构建指定平台
for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -r os arch ext <<< "$platform"
    OUTPUT_NAME="${BIN_NAME}-${os}-${arch}${ext}"
    OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_NAME}"
    
    echo "构建 ${OUTPUT_NAME}..."
    
    # 编译
    GOOS=$os GOARCH=$arch CGO_ENABLED=0 go build \
        -ldflags="-s -w" \
        -o "$OUTPUT_PATH" \
        main.go
    
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
        echo "  ✓ 编译完成: ${SIZE}"
        
        # UPX 压缩（跳过 macOS 和 Windows ARM64，这些平台可能不兼容）
        if [ "$UPX_AVAILABLE" = true ] && [ "$os" != "darwin" ] && [ "$os/$arch" != "windows/arm64" ]; then
            echo "  压缩中 (UPX)..."
            if upx --best --lzma "$OUTPUT_PATH" 2>/dev/null; then
                SIZE_COMPRESSED=$(du -h "$OUTPUT_PATH" | cut -f1)
                echo "  ✓ 压缩完成: ${SIZE_COMPRESSED}"
            else
                echo "  ⚠ 压缩失败，保留未压缩版本"
            fi
        fi
    else
        echo "  ✗ 编译失败"
    fi
    
    echo ""
done

echo "========================================="
echo "构建完成! 文件位于 ${OUTPUT_DIR}/ 目录"
echo "========================================="
echo ""
echo "文件列表:"
ls -lh "$OUTPUT_DIR/" 2>/dev/null || echo "  (无文件)"
echo ""

# 提示如何安装 UPX
if [ "$UPX_AVAILABLE" = false ]; then
    echo "提示: 安装 UPX 可以进一步压缩二进制文件 (减小 60-70%)"
    echo "  Ubuntu/Debian: sudo apt-get install upx"
    echo "  macOS:         brew install upx"
    echo ""
fi
