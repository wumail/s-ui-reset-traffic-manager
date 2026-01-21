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

### 1. One-Click Installation (Recommended)

Run the following command on your Linux server to automatically download the latest version and install it as a systemd service:

```bash
curl -fsSL https://raw.githubusercontent.com/itning/reset-s-ui-traffic/master/deploy.sh | sudo bash -s install
```

### 2. Manual Installation

If you prefer to build from source or have already downloaded the binary:

#### Option A: Build from Source

Ensure you have [Go](https://golang.org/dl/) installed.

```bash
# Clone the repository
git clone https://github.com/itning/reset-s-ui-traffic.git
cd reset-s-ui-traffic

# Build for your platform (e.g., Linux AMD64)
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o reset-traffic main.go
```

#### Option B: Deploy with local binary

1. Upload your compiled binary and `install.sh` to your server.
2. Run the installation script:

```bash
sudo chmod +x install.sh
sudo ./install.sh
```

Follow the menu prompts to install the service. The script will create a systemd service named `reset-traffic`.

## Usage

### Configuration Management Script

After installation, you can use the interactive configuration script to manage the service:

```bash
sudo reset-traffic-config
```

**Configuration Options:**
- **Option 1**: Modify SUI database path
- **Option 2**: Modify HTTP API port
- **Option 3**: Modify cron expression for scheduled tasks
- **Option 4**: Manually trigger traffic reset
- **Option 0**: Exit (automatically restarts service if configuration changed)

Each option supports entering `0` to return to the main menu.

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
| `CRON_SCHEDULE` | Cron expression for scheduled task (format: minute hour day month weekday) | `0 0 1 * *` (1st of month at 00:00) |

### Cron Expression Examples

| Expression | Description |
| :--- | :--- |
| `0 0 1 * *` | 1st of every month at 00:00 (default) |
| `0 0 * * 0` | Every Sunday at 00:00 |
| `0 0 * * 1` | Every Monday at 00:00 |
| `0 0 15 * *` | 15th of every month at 00:00 |
| `0 2 1 * *` | 1st of every month at 02:00 |
| `0 0 1 */3 *` | 1st day of every 3 months at 00:00 |

**Note**: All times are based on Asia/Shanghai timezone (UTC+8).

## Release Process

This project uses an automated release workflow. When the `VERSION` file is updated and pushed to the master branch, GitHub Actions will automatically build and create a new release.

### Creating a New Release

1. Edit the `VERSION` file to update the version number and changelog:

```json
{
  "version": "1.1.0",
  "changelog": [
    "Feature: Added some new feature",
    "Fix: Fixed some issue",
    "Improvement: Optimized some performance"
  ]
}
```

2. Commit and push to master branch:

```bash
git add VERSION
git commit -m "chore: bump version to 1.1.0"
git push origin master
```

3. GitHub Actions will automatically:
   - Detect version changes
   - Build binaries for all platforms
   - Create GitHub Release (tag: `v1.1.0`)
   - Upload all binaries as release assets
   - Include changelog in release notes

## License

[Apache-2.0](./LICENSE)
