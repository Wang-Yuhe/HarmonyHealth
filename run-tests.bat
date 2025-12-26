@echo off
REM HarmonyHealth 测试执行脚本 (Windows版本)
REM 用于快速设置环境并运行测试

echo ========================================
echo   HarmonyHealth 测试执行脚本
echo ========================================

REM 检查Node.js
echo 检查Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ Node.js未安装
    echo 请从 https://nodejs.org/ 下载并安装Node.js 16+
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo ✓ Node.js已安装: %NODE_VERSION%
)

REM 检查npm
echo 检查npm...
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ npm未安装
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
    echo ✓ npm已安装: %NPM_VERSION%
)

REM 检查hvigor
echo 检查hvigor...
hvigor --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ hvigor未安装，正在安装...
    npm install -g @ohos/hvigor
    if %errorlevel% neq 0 (
        echo ✗ hvigor安装失败
        echo 请手动运行: npm install -g @ohos/hvigor
        pause
        exit /b 1
    ) else (
        echo ✓ hvigor安装成功
    )
) else (
    for /f "tokens=*" %%i in ('hvigor --version') do set HVIGOR_VERSION=%%i
    echo ✓ hvigor已安装: %HVIGOR_VERSION%
)

REM 检查ohpm
echo 检查ohpm...
ohpm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠ ohpm未安装 (通常随DevEco Studio安装)
    echo 建议使用DevEco Studio IDE运行测试
) else (
    echo ✓ ohpm已安装
)

REM 安装项目依赖
echo 安装项目依赖...
if exist "oh-package.json5" (
    if exist "ohpm" (
        ohpm install
    ) else (
        echo ⚠ 跳过ohpm依赖安装，请确保依赖已手动安装
    )
)

if exist "package.json" (
    npm install
)

echo.
echo ========================================
echo   选择测试执行方式:
echo ========================================
echo 1. 运行所有测试 (推荐)
echo 2. 运行单元测试
echo 3. 运行性能测试
echo 4. 运行稳定性测试
echo 5. 运行异常处理测试
echo 6. 运行ohosTest (DevEco Studio兼容)
echo 7. 构建测试版本
echo 8. 显示帮助信息
echo ========================================

REM 如果提供了命令行参数，直接执行
if "%1"=="" goto :menu
goto :execute

:menu
echo.
echo 使用方法:
echo   run-tests.bat all        - 运行所有测试
echo   run-tests.bat unit       - 运行单元测试
echo   run-tests.bat performance - 运行性能测试
echo   run-tests.bat stability  - 运行稳定性测试
echo   run-tests.bat build      - 构建测试版本
echo.
echo 或者直接运行: npm run test
goto :end

:execute
if "%1"=="all" (
    echo 运行所有测试...
    npm run test
    goto :end
)
if "%1"=="unit" (
    echo 运行单元测试...
    npm run test:unit
    goto :end
)
if "%1"=="performance" (
    echo 运行性能测试...
    npm run test:performance
    goto :end
)
if "%1"=="stability" (
    echo 运行稳定性测试...
    npm run test:stability
    goto :end
)
if "%1"=="ohtest" (
    echo 运行ohosTest (DevEco Studio兼容)...
    hvigor runOhosTest
    goto :end
)
if "%1"=="build" (
    echo 构建测试版本...
    npm run build:test
    goto :end
)
echo 无效参数: %1
echo 使用 run-tests.bat (无参数) 查看帮助
goto :end

:end
echo.
echo 测试执行完成
pause