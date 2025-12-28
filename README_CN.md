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

### 1. 从源码编译

请确保已安装 [Go](https://golang.org/dl/)。

```bash
# 克隆仓库
git clone https://github.com/itning/reset-s-ui-traffic.git
cd reset-s-ui-traffic

# 为你的平台编译 (例如 Linux AMD64)
# 你也可以在 Windows 上使用 build.ps1 脚本
$env:GOOS="linux"; $env:GOARCH="amd64"; $env:CGO_ENABLED=0; go build -o reset-traffic main.go
```

### 2. 部署到 Linux 服务器

1. 将编译好的二进制文件和 `install.sh` 上传到服务器。
2. 运行安装脚本：

```bash
sudo chmod +x install.sh
sudo ./install.sh
```

按照菜单提示安装服务。脚本将创建一个名为 `reset-traffic` 的 systemd 服务。

## 使用方法

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

## 许可证

[Apache-2.0](./LICENSE)
