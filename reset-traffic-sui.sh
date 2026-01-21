#!/bin/bash

# Reset S-UI Traffic 管理工具
# 用于安装、更新、卸载和配置 reset-traffic 服务

set -e

SCRIPT_VERSION="1.0.3"
REPO="wumail/s-ui-reset-traffic-manager"

SCRIPT_INSTALL_PATH="/usr/local/bin/reset-traffic-sui"
SERVICE_NAME="reset-traffic"
INSTALL_PATH="/usr/local/bin/$SERVICE_NAME"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
CONFIG_CHANGED=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否以 root 运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误: 此脚本需要 root 权限运行${NC}"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统架构
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            BINARY_NAME="reset-traffic-linux-amd64"
            ;;
        aarch64|arm64)
            BINARY_NAME="reset-traffic-linux-arm64"
            ;;
        *)
            echo -e "${RED}错误: 不支持的架构: $ARCH${NC}"
            return 1
            ;;
    esac
    return 0
}

# 从服务文件读取环境变量值
get_env_value() {
    local var_name=$1
    local default_value=$2
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$default_value"
        return
    fi
    
    local value=$(grep "Environment=\"${var_name}=" "$SERVICE_FILE" 2>/dev/null | sed -n "s/.*Environment=\"${var_name}=\([^\"]*\)\".*/\1/p" | head -1)
    
    if [ -z "$value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# 更新或添加环境变量到服务文件
set_env_value() {
    local var_name=$1
    local var_value=$2
    
    # 检查环境变量是否已存在
    if grep -q "Environment=\"${var_name}=" "$SERVICE_FILE"; then
        # 更新现有值
        sed -i.bak "s|Environment=\"${var_name}=.*\"|Environment=\"${var_name}=${var_value}\"|g" "$SERVICE_FILE"
    else
        # 在 [Service] 部分后添加新的环境变量
        sed -i.bak "/^\[Service\]/a\\
Environment=\"${var_name}=${var_value}\"" "$SERVICE_FILE"
    fi
    
    CONFIG_CHANGED=true
    echo -e "${GREEN}✓ 配置已更新${NC}"
}

# 验证端口号
validate_port() {
    local port=$1
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# 验证 cron 表达式 (基本验证)
validate_cron() {
    local cron=$1
    local field_count=$(echo "$cron" | awk '{print NF}')
    if [ "$field_count" -ne 5 ]; then
        return 1
    fi
    return 0
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${BLUE}====================================${NC}"
    echo -e "${BLUE}  Reset S-UI Traffic 管理工具${NC}"
    echo -e "${BLUE}  版本: v${SCRIPT_VERSION}${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo ""
    
    # 检查服务状态
    if [ -f "$SERVICE_FILE" ]; then
        local status=$(systemctl is-active $SERVICE_NAME 2>/dev/null || echo "未运行")
        echo -e "服务状态: ${GREEN}${status}${NC}"
        echo ""
        echo "当前配置:"
        echo -e "  数据库路径: ${YELLOW}$(get_env_value "SUI_DB_PATH" "/usr/local/s-ui/db/s-ui.db")${NC}"
        echo -e "  HTTP 端口:   ${YELLOW}$(get_env_value "PORT" "52893")${NC}"
        echo -e "  Cron 表达式: ${YELLOW}$(get_env_value "CRON_SCHEDULE" "0 0 1 * *")${NC}"
    else
        echo -e "服务状态: ${RED}未安装${NC}"
    fi
    
    echo ""
    echo "请选择操作:"
    echo ""
    echo -e "------${GREEN}[服务管理]${NC}------"
    echo "  1. 安装 reset-traffic 服务"
    echo "  2. 更新 reset-traffic 服务"
    echo "  3. 卸载 reset-traffic 服务"
    echo "  4. 暂停 reset-traffic 服务"
    echo "  5. 启动 reset-traffic 服务"
    echo ""
    echo -e "------${GREEN}[配置管理]${NC}------"
    echo "  6. 修改 SUI 数据库路径"
    echo "  7. 修改 HTTP API 端口"
    echo "  8. 修改定时任务 Cron 表达式"
    echo ""
    echo -e "------${GREEN}[操作功能]${NC}------"
    echo "  9. 手动重置流量"
    echo " 10. 查看重置日志"
    echo ""
    echo " 11. 更新脚本"
    echo "" 
    echo "  0. 退出"
    echo ""
    echo -n "请输入选项 [0-11]: "
}

# 安装服务
option_install_service() {
    clear
    echo -e "${BLUE}=== 安装 reset-traffic 服务 ===${NC}"
    echo ""
    
    if [ -f "$SERVICE_FILE" ]; then
        echo -e "${YELLOW}警告: 服务已安装${NC}"
        echo -n "是否重新安装? (y/n, 输入 0 返回): "
        read confirm
        if [ "$confirm" = "0" ]; then
            return
        fi
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            return
        fi
    fi
    
    echo "1. 检测系统架构..."
    if ! detect_arch; then
        sleep 3
        return
    fi
    echo -e "   架构: ${GREEN}$ARCH${NC}, 二进制文件: ${GREEN}$BINARY_NAME${NC}"
    
    echo "2. 获取最新版本信息..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$LATEST_TAG" ]; then
        echo -e "${RED}错误: 无法获取最新版本信息${NC}"
        sleep 3
        return
    fi
    echo -e "   最新版本: ${GREEN}$LATEST_TAG${NC}"
    
    echo "3. 下载二进制文件..."
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$BINARY_NAME"
    TMP_BINARY="/tmp/$BINARY_NAME"
    
    if ! curl -L "$DOWNLOAD_URL" -o "$TMP_BINARY"; then
        echo -e "${RED}错误: 下载失败${NC}"
        sleep 3
        return
    fi
    
    if [ ! -s "$TMP_BINARY" ]; then
        echo -e "${RED}错误: 下载的文件为空${NC}"
        sleep 3
        return
    fi
    
    echo "4. 安装二进制文件..."
    mv "$TMP_BINARY" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    
    echo "5. 创建 systemd 服务..."
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=S-UI Traffic Reset Service (Monthly & HTTP)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_PATH
Restart=on-failure
WorkingDirectory=/usr/local/bin

[Install]
WantedBy=multi-user.target
EOF
    
    echo "6. 启动服务..."
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    echo ""
    echo -e "${GREEN}✓ 安装成功!${NC}"
    echo -e "服务状态: $(systemctl is-active $SERVICE_NAME)"
    echo ""
    echo -n "按回车键返回..."
    read
}

# 更新服务
option_update_service() {
    clear
    echo -e "${BLUE}=== 更新 reset-traffic 服务 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        echo "请先使用选项 1 安装服务"
        sleep 3
        return
    fi
    
    echo -n "确认更新到最新版本? (y/n, 输入 0 返回): "
    read confirm
    if [ "$confirm" = "0" ]; then
        return
    fi
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "1. 检测系统架构..."
    if ! detect_arch; then
        sleep 3
        return
    fi
    echo -e "   架构: ${GREEN}$ARCH${NC}"
    
    echo "2. 获取最新版本信息..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$LATEST_TAG" ]; then
        echo -e "${RED}错误: 无法获取最新版本信息${NC}"
        sleep 3
        return
    fi
    echo -e "   最新版本: ${GREEN}$LATEST_TAG${NC}"
    
    echo "3. 下载新版本..."
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$BINARY_NAME"
    TMP_BINARY="/tmp/$BINARY_NAME"
    
    if ! curl -L "$DOWNLOAD_URL" -o "$TMP_BINARY"; then
        echo -e "${RED}错误: 下载失败${NC}"
        sleep 3
        return
    fi
    
    echo "4. 停止服务..."
    systemctl stop "$SERVICE_NAME"
    
    echo "5. 替换二进制文件..."
    mv "$TMP_BINARY" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    
    echo "6. 重启服务..."
    systemctl start "$SERVICE_NAME"
    
    echo ""
    echo -e "${GREEN}✓ 更新成功!${NC}"
    echo -e "服务状态: $(systemctl is-active $SERVICE_NAME)"
    echo ""
    echo -n "按回车键返回..."
    read
}

# 卸载服务
option_uninstall_service() {
    clear
    echo -e "${BLUE}=== 卸载 reset-traffic 服务 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${YELLOW}服务未安装${NC}"
        sleep 2
        return
    fi
    
    echo -e "${RED}警告: 此操作将完全删除 reset-traffic 服务${NC}"
    echo -n "确认卸载? (y/n, 输入 0 返回): "
    read confirm
    if [ "$confirm" = "0" ]; then
        return
    fi
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "1. 停止服务..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    
    echo "2. 禁用服务..."
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    
    echo "3. 删除服务文件..."
    rm -f "$SERVICE_FILE"
    
    echo "4. 删除二进制文件..."
    rm -f "$INSTALL_PATH"
    
    echo "5. 重新加载 systemd..."
    systemctl daemon-reload
    
    echo ""
    echo -e "${GREEN}✓ 卸载成功!${NC}"
    echo ""
    echo -n "按回车键返回..."
    read
}

# 暂停服务
option_pause_service() {
    clear
    echo -e "${BLUE}=== 暂停 reset-traffic 服务 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        sleep 2
        return
    fi
    
    local status=$(systemctl is-active $SERVICE_NAME 2>/dev/null || echo "未运行")
    if [ "$status" != "active" ]; then
        echo -e "${YELLOW}服务当前未运行${NC}"
        sleep 2
        return
    fi
    
    echo "正在暂停服务..."
    if systemctl stop "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ 服务已暂停${NC}"
    else
        echo -e "${RED}✗ 暂停服务失败${NC}"
    fi
    
    echo ""
    echo -n "按回车键返回..."
    read
}

# 启动服务
option_resume_service() {
    clear
    echo -e "${BLUE}=== 启动 reset-traffic 服务 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        sleep 2
        return
    fi
    
    local status=$(systemctl is-active $SERVICE_NAME 2>/dev/null || echo "未运行")
    if [ "$status" = "active" ]; then
        echo -e "${YELLOW}服务已在运行中${NC}"
        sleep 2
        return
    fi
    
    echo "正在启动服务..."
    if systemctl start "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ 服务已启动${NC}"
    else
        echo -e "${RED}✗ 启动服务失败${NC}"
        systemctl status "$SERVICE_NAME" --no-pager
    fi
    
    echo ""
    echo -n "按回车键返回..."
    read
}

# 修改数据库路径
option_modify_db_path() {
    clear
    echo -e "${BLUE}=== 修改 SUI 数据库路径 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        sleep 2
        return
    fi
    
    current_path=$(get_env_value "SUI_DB_PATH" "/usr/local/s-ui/db/s-ui.db")
    echo -e "当前路径: ${YELLOW}${current_path}${NC}"
    echo ""
    echo -n "请输入新的数据库路径 (输入 0 返回): "
    read new_path
    
    if [ "$new_path" = "0" ]; then
        return
    fi
    
    if [ -z "$new_path" ]; then
        echo -e "${RED}错误: 路径不能为空${NC}"
        sleep 2
        return
    fi
    
    if [ ! -f "$new_path" ]; then
        echo -e "${YELLOW}警告: 文件不存在: $new_path${NC}"
        echo -n "是否继续? (y/n): "
        read confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            return
        fi
    fi
    
    set_env_value "SUI_DB_PATH" "$new_path"
    sleep 2
}

# 修改 HTTP 端口
option_modify_port() {
    clear
    echo -e "${BLUE}=== 修改 HTTP API 端口 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        sleep 2
        return
    fi
    
    current_port=$(get_env_value "PORT" "52893")
    echo -e "当前端口: ${YELLOW}${current_port}${NC}"
    echo ""
    echo -n "请输入新的端口号 (1-65535, 输入 0 返回): "
    read new_port
    
    if [ "$new_port" = "0" ]; then
        return
    fi
    
    if ! validate_port "$new_port"; then
        echo -e "${RED}错误: 无效的端口号 (必须是 1-65535 之间的数字)${NC}"
        sleep 2
        return
    fi
    
    set_env_value "PORT" "$new_port"
    sleep 2
}

# 修改 Cron 表达式
option_modify_cron() {
    clear
    echo -e "${BLUE}=== 修改定时任务 Cron 表达式 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        sleep 2
        return
    fi
    
    current_cron=$(get_env_value "CRON_SCHEDULE" "0 0 1 * *")
    echo -e "当前表达式: ${YELLOW}${current_cron}${NC}"
    echo ""
    echo "Cron 表达式格式: 分 时 日 月 周"
    echo "示例:"
    echo "  0 0 1 * *     - 每月1号 00:00"
    echo "  0 0 * * 0     - 每周日 00:00"
    echo "  0 0 15 * *    - 每月15号 00:00"
    echo ""
    echo -n "请输入新的 Cron 表达式 (输入 0 返回): "
    read new_cron
    
    if [ "$new_cron" = "0" ]; then
        return
    fi
    
    if [ -z "$new_cron" ]; then
        echo -e "${RED}错误: Cron 表达式不能为空${NC}"
        sleep 2
        return
    fi
    
    if ! validate_cron "$new_cron"; then
        echo -e "${RED}错误: 无效的 Cron 表达式 (应包含5个字段)${NC}"
        sleep 2
        return
    fi
    
    set_env_value "CRON_SCHEDULE" "$new_cron"
    sleep 2
}

# 手动重置流量
option_manual_reset() {
    clear
    echo -e "${BLUE}=== 手动重置流量 ===${NC}"
    echo ""
    
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务未安装${NC}"
        sleep 2
        return
    fi
    
    current_port=$(get_env_value "PORT" "52893")
    api_url="http://127.0.0.1:${current_port}/api/traffic/reset"
    
    echo "正在发送重置请求到: $api_url"
    echo ""
    
    if command -v curl &> /dev/null; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$api_url" 2>&1)
        http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
        body=$(echo "$response" | grep -v "HTTP_CODE:")
        
        if [ "$http_code" = "200" ]; then
            echo -e "${GREEN}✓ 重置成功${NC}"
            echo ""
            echo "响应:"
            echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
        else
            echo -e "${RED}✗ 重置失败 (HTTP $http_code)${NC}"
            echo ""
            echo "响应:"
            echo "$body"
        fi
    else
        echo -e "${RED}错误: 未找到 curl 命令${NC}"
    fi
    
    echo ""
    echo -n "按回车键返回..."
    read
}

# 查看重置日志
option_view_logs() {
    clear
    echo -e "${BLUE}=== 查看重置日志 ===${NC}"
    echo ""
    
    LOG_FILE="/usr/local/s-ui/logs/reset-traffic.log"
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}暂无重置日志${NC}"
        echo ""
        echo -n "按回车键返回..."
        read
        return
    fi
    
    echo "最近 20 条重置记录:"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    tail -n 20 "$LOG_FILE"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "日志文件位置: $LOG_FILE"
    echo "查看完整日志: cat $LOG_FILE"
    echo ""
    echo -n "按回车键返回..."
    read
}

# 获取最新脚本版本
get_latest_script_version() {
    local latest_version=$(curl -s --max-time 5 --connect-timeout 1 \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Cache-Control: no-cache, no-store, must-revalidate" \
        "https://api.github.com/repos/$REPO/releases/latest" \
        2>/dev/null | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
    echo "$latest_version"
}

# 更新脚本
option_update_script() {
    clear
    echo -e "${BLUE}=== 更新管理脚本 ===${NC}"
    echo ""
    
    echo "当前版本: v${SCRIPT_VERSION}"
    echo "正在检查最新版本..."
    echo ""
    
    latest_version=$(get_latest_script_version 2>/dev/null)
    
    if [ -z "$latest_version" ]; then
        echo -e "${RED}错误: 无法获取最新版本信息${NC}"
        sleep 3
        return
    fi
    
    echo -e "最新版本: ${GREEN}v${latest_version}${NC}"
    echo ""
    
    if [ "$latest_version" = "$SCRIPT_VERSION" ]; then
        echo -e "${GREEN}✓ 已是最新版本${NC}"
        sleep 2
        return
    fi
    
    echo -n "确认更新到 v${latest_version}? (y/n, 输入 0 返回): "
    read confirm
    if [ "$confirm" = "0" ]; then
        return
    fi
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "正在下载最新版本..."
    
    TMP_SCRIPT="/tmp/reset-traffic-sui.sh"
    DOWNLOAD_URL="https://raw.githubusercontent.com/$REPO/master/reset-traffic-sui.sh"
    
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_SCRIPT"; then
        echo -e "${RED}错误: 下载失败${NC}"
        sleep 3
        return
    fi
    
    if [ ! -s "$TMP_SCRIPT" ]; then
        echo -e "${RED}错误: 下载的文件为空${NC}"
        sleep 3
        return
    fi
    
    echo "正在安装..."
    chmod +x "$TMP_SCRIPT"
    mv "$TMP_SCRIPT" "$SCRIPT_INSTALL_PATH"
    
    echo ""
    echo -e "${GREEN}✓ 更新成功! 脚本将重新启动...${NC}"
    sleep 2
    
    # 重新启动脚本
    exec "$SCRIPT_INSTALL_PATH"
}

# 重启服务
restart_service() {
    if [ ! -f "$SERVICE_FILE" ]; then
        return
    fi
    
    echo ""
    echo -e "${YELLOW}配置已修改,正在重启服务...${NC}"
    
    systemctl daemon-reload
    
    if systemctl restart "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ 服务重启成功${NC}"
    else
        echo -e "${RED}✗ 服务重启失败${NC}"
        systemctl status "$SERVICE_NAME" --no-pager
    fi
}

# 主循环
main() {
    check_root
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                option_install_service
                ;;
            2)
                option_update_service
                ;;
            3)
                option_uninstall_service
                ;;
            4)
                option_pause_service
                ;;
            5)
                option_resume_service
                ;;
            6)
                option_modify_db_path
                ;;
            7)
                option_modify_port
                ;;
            8)
                option_modify_cron
                ;;
            9)
                option_manual_reset
                ;;
            10)
                option_view_logs
                ;;
            11)
                option_update_script
                ;;
            0)
                clear
                if [ "$CONFIG_CHANGED" = true ]; then
                    restart_service
                fi
                echo -e "${GREEN}退出管理工具${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项,请重新选择${NC}"
                sleep 1
                ;;
        esac
    done
}

main
