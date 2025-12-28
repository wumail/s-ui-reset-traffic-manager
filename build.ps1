# Build script for multi-platform Go executable

$binName = "reset-traffic"
$outputDir = "build"

# Create output directory if it doesn't exist
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

# Define target platforms (OS and Architecture)
$targets = @(
    @{ os = "windows"; arch = "amd64"; ext = ".exe" },
    @{ os = "windows"; arch = "arm64"; ext = ".exe" },
    @{ os = "linux";   arch = "amd64"; ext = "" },
    @{ os = "linux";   arch = "arm64"; ext = "" },
    @{ os = "darwin";  arch = "amd64"; ext = "" }, # Intel Mac
    @{ os = "darwin";  arch = "arm64"; ext = "" }  # Apple Silicon Mac
)

Write-Host "Starting multi-platform build..." -ForegroundColor Cyan

foreach ($target in $targets) {
    $os = $target.os
    $arch = $target.arch
    $ext = $target.ext
    
    $outputName = "$binName-$os-$arch$ext"
    $outputPath = Join-Path $outputDir $outputName

    Write-Host "Building: $outputName..." -NoNewline
    
    # Set environment variables for cross-compilation
    $env:GOOS = $os
    $env:GOARCH = $arch
    $env:CGO_ENABLED = 0 # Ensure pure Go build

    # Execute build
    go build -o $outputPath main.go

    if ($LASTEXITCODE -eq 0) {
        Write-Host " [Success]" -ForegroundColor Green
    } else {
        Write-Host " [Failed]" -ForegroundColor Red
    }
}

# Reset environment variables back to default
$env:GOOS = ""
$env:GOARCH = ""
$env:CGO_ENABLED = ""

Write-Host "`nBuild process finished. Check the '$outputDir' directory." -ForegroundColor Cyan
