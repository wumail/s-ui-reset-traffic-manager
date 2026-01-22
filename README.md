<h3 align="center">Reset S-UI Traffic</h3>
<div align="center">

[![GitHub license](https://img.shields.io/github/license/wumail/s-ui-reset-traffic-manager.svg)](https://github.com/wumail/s-ui-reset-traffic-manager/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/wumail/s-ui-reset-traffic-manager.svg)](https://github.com/wumail/s-ui-reset-traffic-manager/releases)

</div>

[中文文档](./README_CN.md)

A simple tool to reset traffic statistics (upload/download) for the `s-ui` panel. It includes a monthly scheduled task and an HTTP API for manual triggering.

## Project Overview

S-UI Traffic Reset Manager provides:
- ⚙️ Interactive configuration management (database path, port, scheduled tasks)
- 🔄 Automatic scheduled traffic reset (configurable Cron expression)
- 🖱️ Manual traffic reset trigger (HTTP API)
- 📦 One-click install/update/uninstall service
- 📊 Reset log viewing (records time and reset method)
- 🚀 Based on [itning/reset-s-ui-traffic](https://github.com/itning/reset-s-ui-traffic)

---

## Features

- **Automatic Monthly Reset**: (Default) Automatically clears all client traffic at 00:00 on the 1st of each month (Asia/Shanghai timezone).
- **Manual Reset API**: Provides an HTTP interface to manually trigger traffic reset at any time.
- **Pure Go Implementation**: Uses `modernc.org/sqlite`, no CGO required for compilation.
- **Simple Deployment**: Includes Systemd installation script for Linux servers.

## Installation

### 1. One-Click Deployment (Recommended)

Run the following command on your Linux server to automatically download the management tool:

```bash
curl -fsSL https://raw.githubusercontent.com/wumail/s-ui-reset-traffic-manager/master/deploy.sh | sudo bash
```

Then run the management tool to install:

```bash
sudo reset-traffic-sui
# Select option 1 to install
```

### 2. Manual Installation

If you want to build from source or have already downloaded the binary:

#### Option A: Build from Source

Make sure [Go](https://golang.org/dl/) is installed.

```bash
# Clone the repository
git clone https://github.com/wumail/s-ui-reset-traffic-manager.git
cd s-ui-reset-traffic-manager

# Build for your platform
chmod +x build.sh
./build.sh
```

#### Option B: Deploy with Local Binary

1. Upload the compiled binary and `install.sh` to your server.
2. Run the installation script:

```bash
sudo chmod +x install.sh
sudo ./install.sh
```

Follow the menu prompts to install the service. The script will create a systemd service named `reset-traffic`.

## Usage

### Management Tool

After installation, use the `reset-traffic-sui` management tool to manage the service:

```bash
sudo reset-traffic-sui
```

**Feature Options:**

**[Service Management]**
- **Option 1**: Install reset-traffic service (download latest version from GitHub)
- **Option 2**: Update reset-traffic service
- **Option 3**: Uninstall reset-traffic service
- **Option 4**: Pause reset-traffic service
- **Option 5**: Start reset-traffic service

**[Configuration Management]**
- **Option 6**: Modify SUI database path
- **Option 7**: Modify HTTP API port
- **Option 8**: Modify scheduled task Cron expression

**[Operation Functions]**
- **Option 9**: Manual traffic reset
- **Option 10**: View reset logs (shows time and reset method: manual/automatic)
- **Option 11**: Update script to latest version

- **Option 0**: Exit (automatically restarts service if configuration changed)

All options support entering `0` to return to the main menu.

**Log File Location**: Reset logs are stored at `/usr/local/s-ui/logs/reset-traffic.log`. The log directory is automatically created when the service first writes logs.

### HTTP API

The service listens on `127.0.0.1:52893` by default. You can manually trigger a reset by requesting:

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

The scheduled task runs automatically within the program. Default setting:
`0 0 1 * *` (00:00 on the 1st of each month).

### Cron Expression Examples

| Expression | Description |
| :--- | :--- |
| `0 0 1 * *` | 1st of every month at 00:00 (default) |
| `0 0 * * 0` | Every Sunday at 00:00 |
| `0 0 * * 1` | Every Monday at 00:00 |
| `0 0 15 * *` | 15th of every month at 00:00 |
| `0 2 1 * *` | 1st of every month at 02:00 |
| `0 0 1 */3 *` | 1st day of every 3 months at 00:00 |

You can modify the scheduled task's Cron expression by running `sudo reset-traffic-sui` and selecting option 8.

**Note**: All times are based on Asia/Shanghai timezone (UTC+8).

## Build Script

The project includes an optimized build script for Linux/macOS:

### `build.sh`

**Build all platforms:**
```bash
chmod +x build.sh
# Build all platforms
./build.sh
```

**Build specific platforms:**
```bash
# Show help
./build.sh --help

# Build only Linux AMD64
./build.sh linux/amd64

# Build Linux AMD64 and ARM64
./build.sh linux/amd64 linux/arm64

# Build all Windows platforms
./build.sh windows/amd64 windows/arm64
```

**Supported platforms:**
- `windows/amd64` - Windows 64-bit (Intel/AMD)
- `windows/arm64` - Windows ARM64
- `linux/amd64` - Linux 64-bit (Intel/AMD)
- `linux/arm64` - Linux ARM64
- `darwin/amd64` - macOS Intel
- `darwin/arm64` - macOS Apple Silicon

**Installing UPX (Optional):**

For even smaller binaries during local builds, install UPX:

**Ubuntu/Debian:**
```bash
sudo apt-get install upx
```

**macOS:**
```bash
brew install upx
```

With UPX, binary sizes can be reduced from ~7MB to ~2-3MB.

## Release Process

This project uses an automated release process. When the `VERSION` file is updated and pushed to the master branch, GitHub Actions automatically builds and creates a new release.

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
git add .
git commit -m "chore: bump version to 1.2.0"
git push origin master
```

3. GitHub Actions will automatically:
   - Detect version number change
   - Build binaries for all platforms with optimization flags
   - Create GitHub Release (tag: `v1.2.0`)
   - Upload all binaries as release assets
   - Include version changelog

## Acknowledgments & License

### Project Origin

This project is based on [itning/reset-s-ui-traffic](https://github.com/itning/reset-s-ui-traffic) with secondary development and feature enhancements.

## License

[Apache-2.0](./LICENSE)
