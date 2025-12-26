#!/bin/bash

# HarmonyHealth 测试执行脚本
# 用于快速设置环境并运行测试

echo "========================================"
echo "  HarmonyHealth 测试执行脚本"
echo "========================================"

# 检查操作系统
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    IS_WINDOWS=true
    echo "检测到Windows操作系统"
else
    IS_WINDOWS=false
    echo "检测到非Windows操作系统"
fi

# 检查Node.js
echo "检查Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js已安装: $NODE_VERSION"
else
    echo "✗ Node.js未安装"
    echo "请从 https://nodejs.org/ 下载并安装Node.js 16+"
    exit 1
fi

# 检查npm
echo "检查npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✓ npm已安装: $NPM_VERSION"
else
    echo "✗ npm未安装"
    exit 1
fi

# 检查hvigor
echo "检查hvigor..."
if command -v hvigor &> /dev/null; then
    HVIGOR_VERSION=$(hvigor --version)
    echo "✓ hvigor已安装: $HVIGOR_VERSION"
else
    echo "✗ hvigor未安装，正在安装..."
    npm install -g @ohos/hvigor
    if [ $? -eq 0 ]; then
        echo "✓ hvigor安装成功"
    else
        echo "✗ hvigor安装失败"
        echo "请手动运行: npm install -g @ohos/hvigor"
        exit 1
    fi
fi

# 检查ohpm
echo "检查ohpm..."
if command -v ohpm &> /dev/null; then
    echo "✓ ohpm已安装"
else
    echo "⚠ ohpm未安装 (通常随DevEco Studio安装)"
    echo "建议使用DevEco Studio IDE运行测试"
fi

# 安装项目依赖
echo "安装项目依赖..."
if [ -f "oh-package.json5" ]; then
    if command -v ohpm &> /dev/null; then
        ohpm install
    else
        echo "⚠ 跳过ohpm依赖安装，请确保依赖已手动安装"
    fi
fi

if [ -f "package.json" ]; then
    npm install
fi

echo ""
echo "========================================"
echo "  选择测试执行方式:"
echo "========================================"
echo "1. 运行所有测试 (推荐)"
echo "2. 运行单元测试"
echo "3. 运行性能测试"
echo "4. 运行稳定性测试"
echo "5. 运行异常处理测试"
echo "6. 构建测试版本"
echo "7. 显示帮助信息"
echo "========================================"

if [ "$IS_WINDOWS" = true ]; then
    echo "注意: 在Windows上，建议使用DevEco Studio IDE运行测试"
    echo "或者使用PowerShell运行以下命令:"
    echo "  npm run test"
fi

# 如果提供了命令行参数，直接执行
if [ $# -gt 0 ]; then
    case $1 in
        "all")
            echo "运行所有测试..."
            npm run test
            ;;
        "unit")
            echo "运行单元测试..."
            npm run test:unit
            ;;
        "performance")
            echo "运行性能测试..."
            npm run test:performance
            ;;
        "stability")
            echo "运行稳定性测试..."
            npm run test:stability
            ;;
        "build")
            echo "构建测试版本..."
            npm run build:test
            ;;
        *)
            echo "无效参数。使用 --help 查看帮助"
            ;;
    esac
else
    echo "运行 'bash run-tests.sh all' 来运行所有测试"
    echo "或者运行 'npm run test' 使用npm脚本"
fi</content>
<parameter name="filePath">d:\HarmonyHealth\HarmonyHealth\run-tests.sh