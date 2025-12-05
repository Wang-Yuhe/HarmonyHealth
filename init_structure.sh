#!/bin/bash

BASE_PATH="entry/src/main/ets"

# =============================
# 工具函数：为新文件写入注释内容
# =============================
add_description() {
    local filepath=$1
    local description=$2

    # 仅在文件为空时写入（避免覆盖已有内容）
    if [ ! -s "$filepath" ]; then
        echo "/**" >> "$filepath"
        echo " * @file $(basename "$filepath")" >> "$filepath"
        echo " * @description $description" >> "$filepath"
        echo " * @created $(date '+%Y-%m-%d %H:%M:%S')" >> "$filepath"
        echo " */" >> "$filepath"
        echo "" >> "$filepath"
    fi
}

echo "Creating directories..."

# Directories
mkdir -p $BASE_PATH/common/components
mkdir -p $BASE_PATH/common/model
mkdir -p $BASE_PATH/common/utils

mkdir -p $BASE_PATH/features/login/controller
mkdir -p $BASE_PATH/features/login/view

mkdir -p $BASE_PATH/features/healthStatus/viewmodel
mkdir -p $BASE_PATH/features/healthStatus/view

mkdir -p $BASE_PATH/features/device/service
mkdir -p $BASE_PATH/features/device/view

mkdir -p $BASE_PATH/database/Migrations

mkdir -p $BASE_PATH/pages

echo "Creating files with descriptions..."

# ========== Common/components ==========
files=(
  "$BASE_PATH/common/components/HealthChart.ets:健康折线图/柱状图组件"
  "$BASE_PATH/common/components/DataCard.ets:健康数据卡片显示组件"

  "$BASE_PATH/common/model/User.ets:用户数据模型"
  "$BASE_PATH/common/model/HealthData.ets:健康数据模型（如心率/步数等）"
  "$BASE_PATH/common/model/Device.ets:穿戴设备信息模型"

  "$BASE_PATH/common/utils/TimeUtil.ets:时间格式化工具类"
  "$BASE_PATH/common/utils/AuthUtil.ets:认证辅助工具类"

  "$BASE_PATH/features/login/controller/LoginVM.ets:登录模块的 ViewModel + 业务逻辑"
  "$BASE_PATH/features/login/view/LoginPage.ets:登录界面页面"

  "$BASE_PATH/features/healthStatus/viewmodel/HealthVM.ets:健康状态页面 ViewModel"
  "$BASE_PATH/features/healthStatus/view/StatusPage.ets:健康状态展示页面"

  "$BASE_PATH/features/device/service/DeviceService.ets:设备连接/数据读取服务"
  "$BASE_PATH/features/device/view/DevicePage.ets:设备绑定与状态展示页面"

  "$BASE_PATH/database/HealthDB.ets:数据库核心操作类"
  "$BASE_PATH/database/Migrations/InitMigration.ets:数据库初始化迁移脚本"

  "$BASE_PATH/pages/HomePage.ets:应用主界面"
  "$BASE_PATH/pages/Navigation.ets:底部导航栏控制器"
)

# 批量创建并写描述
for item in "${files[@]}"; do
    filepath="${item%%:*}"
    description="${item#*:}"

    # 创建文件（如果不存在）
    touch "$filepath"

    # 添加描述
    add_description "$filepath" "$description"
done

echo "Project structure and file descriptions completed!"
