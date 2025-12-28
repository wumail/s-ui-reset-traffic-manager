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


[中文说明](./README_CN.md)

A simple tool to reset traffic statistics (upload/download) for the `s-ui` panel. It features both a monthly scheduled task and an HTTP API for manual triggers.

## Features

- **Automated Monthly Reset**: Automatically clears traffic for all clients on the 1st of every month at 00:00 (Asia/Shanghai).
- **Manual Reset API**: Provides an HTTP endpoint to trigger the reset manually at any time.
- **Pure Go Implementation**: Uses `modernc.org/sqlite`, so no CGO is required for compilation.
- **Easy Deployment**: Includes a systemd installation script for Linux servers.

## Installation

### 1. Build from Source

Ensure you have [Go](https://golang.org/dl/) installed.

```bash
# Clone the repository
git clone https://github.com/itning/reset-s-ui-traffic.git
cd reset-s-ui-traffic

# Build for your platform (e.g., Linux AMD64)
# You can also use the build.ps1 script on Windows
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o reset-traffic main.go
```

### 2. Deploy to Linux Server

1. Upload the compiled binary and `install.sh` to your server.
2. Run the installation script:

```bash
sudo chmod +x install.sh
sudo ./install.sh
```

Follow the menu prompts to install the service. The script will create a systemd service named `reset-traffic`.

## Usage

### HTTP API

The service listens on `127.0.0.1:52893` by default. You can manually trigger a reset by sending a request to the following endpoint:

**Endpoint**: `GET http://127.0.0.1:52893/api/traffic/reset`

**Response Example**:
```json
{
  "status": "success",
  "message": "Traffic reset successfully",
  "rows_affected": 10
}
```

### Scheduled Task

The cron job runs automatically inside the binary. By default, it is set to:
`0 0 1 * *` (At 00:00 on day-of-month 1).

## Configuration

You can customize the behavior using environment variables in the systemd service file or before running the binary:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `SUI_DB_PATH` | Path to the `s-ui.db` file | `/usr/local/s-ui/db/s-ui.db` |
| `PORT` | Listening port for the HTTP API | `52893` |

## License

[Apache-2.0](./LICENSE)
