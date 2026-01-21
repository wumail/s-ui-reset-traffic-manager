#!/bin/bash

# Reset S-UI Traffic 配置管理脚本
# 用于交互式配置和管理 reset-traffic 服务

set -e

SERVICE_NAME="reset-traffic"
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

# 检查服务是否存在
check_service() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: 服务文件不存在: $SERVICE_FILE${NC}"
        echo "请先安装 reset-traffic 服务"
        exit 1
    fi
}

# 从服务文件读取环境变量值
get_env_value() {
    local var_name=$1
    local default_value=$2
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
    # 基本验证: 应该有5个字段
    local field_count=$(echo "$cron" | awk '{print NF}')
    if [ "$field_count" -ne 5 ]; then
        return 1
    fi
    return 0
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Reset S-UI Traffic 配置管理${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo "当前配置:"
    echo -e "  数据库路径: ${YELLOW}$(get_env_value "SUI_DB_PATH" "/usr/local/s-ui/db/s-ui.db")${NC}"
    echo -e "  HTTP 端口:   ${YELLOW}$(get_env_value "PORT" "52893")${NC}"
    echo -e "  Cron 表达式: ${YELLOW}$(get_env_value "CRON_SCHEDULE" "0 0 1 * *")${NC}"
    echo ""
    echo "请选择操作:"
    echo "  1. 修改 SUI 数据库路径"
    echo "  2. 修改 HTTP API 端口"
    echo "  3. 修改定时任务 Cron 表达式"
    echo "  4. 手动重置流量"
    echo "  0. 退出"
    echo ""
    echo -n "请输入选项 [0-4]: "
}

# 选项 1: 修改数据库路径
option_modify_db_path() {
    clear
    echo -e "${BLUE}=== 修改 SUI 数据库路径 ===${NC}"
    echo ""
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
    
    # 检查路径是否存在 (仅警告,不阻止)
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

# 选项 2: 修改 HTTP 端口
option_modify_port() {
    clear
    echo -e "${BLUE}=== 修改 HTTP API 端口 ===${NC}"
    echo ""
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

# 选项 3: 修改 Cron 表达式
option_modify_cron() {
    clear
    echo -e "${BLUE}=== 修改定时任务 Cron 表达式 ===${NC}"
    echo ""
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

# 选项 4: 手动重置流量
option_manual_reset() {
    clear
    echo -e "${BLUE}=== 手动重置流量 ===${NC}"
    echo ""
    
    current_port=$(get_env_value "PORT" "52893")
    api_url="http://127.0.0.1:${current_port}/api/traffic/reset"
    
    echo "正在发送重置请求到: $api_url"
    echo ""
    
    # 使用 curl 发送请求
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

# 重启服务
restart_service() {
    echo ""
    echo -e "${YELLOW}配置已修改,正在重启服务...${NC}"
    
    # 重新加载 systemd
    systemctl daemon-reload
    
    # 重启服务
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
    check_service
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                option_modify_db_path
                ;;
            2)
                option_modify_port
                ;;
            3)
                option_modify_cron
                ;;
            4)
                option_manual_reset
                ;;
            0)
                clear
                if [ "$CONFIG_CHANGED" = true ]; then
                    restart_service
                fi
                echo -e "${GREEN}退出配置管理${NC}"
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
