<h3 align="center">Reset S-UI Traffic</h3>
<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/itning/reset-s-ui-traffic.svg?style=social&label=Stars)](https://github.com/itning/reset-s-ui-traffic/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/itning/reset-s-ui-traffic.svg?style=social&label=Fork)](https://github.com/itning/reset-s-ui-traffic/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/itning/reset-s-ui-traffic.svg?style=social&label=Watch)](https://github.com/itning/reset-s-ui-traffic/watchers)
[![GitHub followers](https://img.shields.io/github/followers/itning.svg?style=social&label=Follow)](https://github.com/itning?tab=followers)


</div>

<div align="center">

[![GitHub issues](https://img.shields.io/github/issues/itning/reset-s-ui-traffic.svg)](https://github.com/itning/reset-s-ui-traffic/issues)
[![GitHub license](https://img.shields.io/github/license/itning/reset-s-ui-traffic.svg)](https://github.com/itning/reset-s-ui-traffic/blob/master/LICENSE)
[![GitHub last commit](https://img.shields.io/github/last-commit/itning/reset-s-ui-traffic.svg)](https://github.com/itning/reset-s-ui-traffic/commits)
[![GitHub release](https://img.shields.io/github/release/itning/reset-s-ui-traffic.svg)](https://github.com/itning/reset-s-ui-traffic/releases)
[![GitHub repo size in bytes](https://img.shields.io/github/repo-size/itning/reset-s-ui-traffic.svg)](https://github.com/itning/reset-s-ui-traffic)
[![Hits](https://hitcount.itning.com?u=itning&r=reset-s-ui-traffic)](https://github.com/itning/hit-count)
[![language](https://img.shields.io/badge/language-Go-blue.svg)](https://github.com/itning/reset-s-ui-traffic)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/itning/reset-s-ui-traffic/total)

</div>


[English](./README.md)

一个用于重置 `s-ui` 面板流量统计（上行/下行）的简单工具。它包含每月定时任务和用于手动触发的 HTTP API。

## 功能

- **自动每月重置**: 每月 1 号凌晨 00:00（亚洲/上海时间）自动清空所有客户端的流量。
- **手动重置 API**: 提供一个 HTTP 接口，可随时手动触发流量重置。
- **纯 Go 实现**: 使用 `modernc.org/sqlite`，编译时无需 CGO。
- **部署简单**: 包含适用于 Linux 服务器的 Systemd 安装脚本。

## 安装

### 1. 一键部署 (推荐)

在你的 Linux 服务器上运行以下命令，会自动下载管理工具:

```bash
curl -fsSL https://raw.githubusercontent.com/wumail/reset-s-ui-traffic/master/deploy.sh | sudo bash
```

然后运行管理工具进行安装:

```bash
sudo reset-traffic-sui
# 选择选项 1 进行安装
```

### 2. 手动安装

如果你希望从源码构建或已经下载了二进制文件：

#### 选项 A: 从源码编译

请确保已安装 [Go](https://golang.org/dl/)。

```bash
# 克隆仓库
git clone https://github.com/itning/reset-s-ui-traffic.git
cd reset-s-ui-traffic

# 为你的平台编译 (例如 Linux AMD64)
$env:GOOS="linux"; $env:GOARCH="amd64"; $env:CGO_ENABLED=0; go build -o reset-traffic main.go
```

#### 选项 B: 使用本地二进制部署

1. 将编译好的二进制文件和 `install.sh` 上传到服务器。
2. 运行安装脚本：

```bash
sudo chmod +x install.sh
sudo ./install.sh
```

按照菜单提示安装服务。脚本将创建一个名为 `reset-traffic` 的 systemd 服务。

## 使用方法

### 管理工具

安装后,可以使用 `reset-traffic-sui` 管理工具来管理服务:

```bash
sudo reset-traffic-sui
```

**功能选项:**
- **选项 1**: 安装 reset-traffic 服务 (从 GitHub 下载最新版本)
- **选项 2**: 更新 reset-traffic 服务
- **选项 3**: 卸载 reset-traffic 服务
- **选项 4**: 修改 SUI 数据库路径
- **选项 5**: 修改 HTTP API 端口
- **选项 6**: 修改定时任务 Cron 表达式
- **选项 7**: 手动重置流量
- **选项 0**: 退出 (如果配置有变化会自动重启服务)

所有选项都支持输入 `0` 返回主菜单。

### HTTP API

服务默认监听 `127.0.0.1:52893`。你可以通过请求以下接口来手动触发重置：

**接口**: `GET http://127.0.0.1:52893/api/traffic/reset`

**响应示例**:
```json
{
  "status": "success",
  "message": "Traffic reset successfully",
  "rows_affected": 10
}
```

### 定时任务

定时任务在程序内部自动运行。默认设置为：
`0 0 1 * *` (每月 1 号 00:00)。

## 配置

你可以通过环境变量来自定义行为，可以在 systemd 服务文件中设置或在运行二进制文件前设置：

| 环境变量 | 描述 | 默认值 |
| :--- | :--- | :--- |
| `SUI_DB_PATH` | `s-ui.db` 文件的路径 | `/usr/local/s-ui/db/s-ui.db` |
| `PORT` | HTTP API 的监听端口 | `52893` |
| `CRON_SCHEDULE` | 定时任务的 cron 表达式 (格式: 分 时 日 月 周) | `0 0 1 * *` (每月1号00:00) |

### Cron 表达式示例

| 表达式 | 说明 |
| :--- | :--- |
| `0 0 1 * *` | 每月1号 00:00 (默认) |
| `0 0 * * 0` | 每周日 00:00 |
| `0 0 * * 1` | 每周一 00:00 |
| `0 0 15 * *` | 每月15号 00:00 |
| `0 2 1 * *` | 每月1号 02:00 |
| `0 0 1 */3 *` | 每3个月的1号 00:00 |

**注意**: 所有时间均基于 Asia/Shanghai 时区 (东八区).

## 发布流程

本项目使用自动化发布流程。当 `VERSION` 文件更新并推送到 master 分支时,GitHub Actions 会自动构建并创建新版本。

### 创建新版本

1. 编辑 `VERSION` 文件,更新版本号和改动日志:

```json
{
  "version": "1.1.0",
  "changelog": [
    "新功能: 添加了某某功能",
    "修复: 修复了某某问题",
    "改进: 优化了某某性能"
  ]
}
```

2. 提交并推送到 master 分支:

```bash
git add .
git commit -m "chore: bump version to 1.1.0"
git push origin master
```

3. GitHub Actions 会自动:
   - 检测版本号变化
   - 构建所有平台的二进制文件
   - 创建 GitHub Release (标签: `v1.1.0`)
   - 上传所有二进制文件作为发布资产
   - 附带版本改动信息

## 许可证

[Apache-2.0](./LICENSE)
