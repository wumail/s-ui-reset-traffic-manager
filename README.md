<h3 align="center">Reset S-UI Traffic</h3>

<div align="center">

[![GitHub license](https://img.shields.io/github/license/wumail/s-ui-reset-traffic-manager.svg)](https://github.com/wumail/s-ui-reset-traffic-manager/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/wumail/s-ui-reset-traffic-manager.svg)](https://github.com/wumail/s-ui-reset-traffic-manager/releases)

</div>


[中文说明](./README_CN.md)

A simple tool to reset traffic statistics (upload/download) for the `s-ui` panel. It features both a monthly scheduled task and an HTTP API for manual triggers.

## About

S-UI traffic reset tool featuring:
- ⚙️ Interactive configuration management (database path, port, cron schedule)
- 🔄 Automated scheduled traffic reset (configurable cron expression)
- 🖱️ Manual traffic reset via HTTP API
- 📦 One-click install/update/uninstall service
- 📊 Reset log viewer (tracks timestamp and reset type)
- 🚀 Based on [itning/reset-s-ui-traffic](https://github.com/itning/reset-s-ui-traffic)

---

## Features

- **Automated Monthly Reset**: (Default) Automatically clears traffic for all clients on the 1st of every month at 00:00 (Asia/Shanghai).
- **Manual Reset API**: Provides an HTTP endpoint to trigger the reset manually at any time.
- **Pure Go Implementation**: Uses `modernc.org/sqlite`, so no CGO is required for compilation.
- **Easy Deployment**: Includes a systemd installation script for Linux servers.

## Installation

### 1. One-Click Deployment (Recommended)

Run the following command on your Linux server to download the management tool:

```bash
curl -fsSL https://raw.githubusercontent.com/wumail/s-ui-reset-traffic-manager/master/deploy.sh | sudo bash
```

Then run the management tool to install the service:

```bash
sudo reset-traffic-sui
# Select option 1 to install
```

### 2. Manual Installation

If you prefer to build from source or have already downloaded the binary:

#### Option A: Build from Source

Ensure you have [Go](https://golang.org/dl/) installed.

```bash
# Clone the repository
git clone https://github.com/wumail/s-ui-reset-traffic-manager.git
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

### Management Tool

After installation, you can use the `reset-traffic-sui` management tool:

```bash
sudo reset-traffic-sui
```

**Available Options:**
- **Option 1**: Install reset-traffic service (downloads latest version from GitHub)
- **Option 2**: Update reset-traffic service
- **Option 3**: Uninstall reset-traffic service
- **Option 4**: Modify SUI database path
- **Option 5**: Modify HTTP API port
- **Option 6**: Modify cron expression for scheduled tasks
- **Option 7**: Manually trigger traffic reset
- **Option 8**: View reset logs (shows timestamp and reset type: manual/automatic)
- **Option 0**: Exit (automatically restarts service if configuration changed)

All options support entering `0` to return to the main menu.

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

### Cron Expression Examples

| Expression | Description |
| :--- | :--- |
| `0 0 1 * *` | 1st of every month at 00:00 (default) |
| `0 0 * * 0` | Every Sunday at 00:00 |
| `0 0 * * 1` | Every Monday at 00:00 |
| `0 0 15 * *` | 15th of every month at 00:00 |
| `0 2 1 * *` | 1st of every month at 02:00 |
| `0 0 1 */3 *` | 1st day of every 3 months at 00:00 |

You can modify the cron expression by running `sudo reset-traffic-sui` and selecting option 6.

**Note**: All times are based on Asia/Shanghai timezone (UTC+8).

## Release Process

This project uses an automated release workflow. When the `VERSION` file is updated and pushed to the master branch, GitHub Actions will automatically build and create a new release.

### Creating a New Release

1. Edit the `VERSION` file and add a new version at the beginning of the `releases` array:

```json
{
  "version": "1.2.0",
  "releases": [
    {
      "version": "1.2.0",
      "changelog": [
        "Add: New feature description",
        "Fix: Bug fix description",
        "Improve: Performance improvement"
      ]
    },
    {
      "version": "1.1.0",
      "changelog": [...]
    }
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

## Acknowledgments & License

### Project Origin

This project is based on [itning/reset-s-ui-traffic](https://github.com/itning/reset-s-ui-traffic) with additional features and enhancements

## License

[Apache-2.0](./LICENSE)
