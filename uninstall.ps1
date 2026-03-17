# OpenClaw Uninstaller for Windows
# Usage: powershell -ExecutionPolicy Bypass -File uninstall.ps1
#        powershell -c "irm https://your-domain/uninstall.ps1 | iex"

param(
    [switch]$KeepConfig,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Confirm-Uninstall {
    Write-Host ""
    Write-Host "  OpenClaw Uninstaller" -ForegroundColor Cyan
    Write-Host ""
    Write-Warning "This will remove:"
    Write-Host "  • OpenClaw CLI and Gateway"
    Write-Host "  • Configuration files in $env:USERPROFILE\.openclaw"
    Write-Host "  • Global npm packages (openclaw, @openclaw/*)"
    Write-Host "  • Shell integration and PATH entries"
    Write-Host ""
    
    if (-not $Force) {
        $response = Read-Host "Continue with uninstallation? (y/N)"
        if ($response -notmatch '^[Yy]$') {
            Write-Info "Uninstallation cancelled"
            exit 0
        }
    }
}

function Stop-Gateway {
    Write-Step "Stopping OpenClaw Gateway"
    
    try {
        if (Get-Command openclaw -ErrorAction SilentlyContinue) {
            & openclaw gateway stop 2>$null
            Write-Success "Gateway stopped"
        } else {
            Write-Info "OpenClaw CLI not found, skipping gateway stop"
        }
    } catch {
        Write-Warning "Could not stop gateway: $_"
    }
}

function Remove-NpmPackages {
    Write-Step "Removing npm packages"
    
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Warning "npm not found, skipping npm package removal"
        return
    }
    
    $packages = @(
        "openclaw",
        "@openclaw/gateway",
        "@openclaw/cli"
    )
    
    foreach ($pkg in $packages) {
        try {
            $installed = npm list -g $pkg 2>$null
            if ($LASTEXITCODE -eq 0) {
                npm uninstall -g $pkg 2>$null | Out-Null
                Write-Success "Removed $pkg"
            }
        } catch {
            # Package not installed, skip
        }
    }
}

function Remove-GitInstallation {
    Write-Step "Checking for git-based installation"
    
    $gitDir = Join-Path $env:USERPROFILE "openclaw"
    
    if (Test-Path $gitDir) {
        if (-not $Force) {
            $response = Read-Host "Remove git repository at $gitDir? (y/N)"
            if ($response -notmatch '^[Yy]$') {
                Write-Info "Kept git repository"
                return
            }
        }
        
        Remove-Item -Path $gitDir -Recurse -Force
        Write-Success "Removed git repository"
    } else {
        Write-Info "No git installation found"
    }
    
    # Remove wrapper script
    $wrapperPath = Join-Path $env:USERPROFILE ".local\bin\openclaw.cmd"
    if (Test-Path $wrapperPath) {
        Remove-Item -Path $wrapperPath -Force
        Write-Success "Removed wrapper script"
    }
}

function Remove-ConfigFiles {
    Write-Step "Removing configuration files"
    
    $openclawDir = Join-Path $env:USERPROFILE ".openclaw"
    
    if (Test-Path $openclawDir) {
        if ($KeepConfig) {
            Write-Info "Keeping configuration files (--KeepConfig specified)"
            return
        }
        
        if (-not $Force) {
            $response = Read-Host "Remove $openclawDir directory? This will delete all your data. (y/N)"
            if ($response -notmatch '^[Yy]$') {
                Write-Info "Kept configuration directory"
                return
            }
        }
        
        Remove-Item -Path $openclawDir -Recurse -Force
        Write-Success "Removed $openclawDir"
    } else {
        Write-Info "$openclawDir not found"
    }
}

function Remove-PathEntries {
    Write-Step "Removing PATH entries"
    
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $modified = $false
    
    # Remove openclaw-related paths
    $pathsToRemove = @(
        "$env:USERPROFILE\.local\bin",
        "$env:USERPROFILE\openclaw\node_modules\.bin"
    )
    
    $newPath = ($userPath -split ';' | Where-Object {
        $path = $_
        $shouldKeep = $true
        foreach ($removePattern in $pathsToRemove) {
            if ($path -like "*$removePattern*") {
                $shouldKeep = $false
                $modified = $true
                break
            }
        }
        $shouldKeep
    }) -join ';'
    
    if ($modified) {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "Removed OpenClaw from PATH"
    } else {
        Write-Info "No OpenClaw entries found in PATH"
    }
}

function Remove-PowerShellProfile {
    Write-Step "Removing PowerShell profile integration"
    
    $profilePath = $PROFILE.CurrentUserAllHosts
    
    if (Test-Path $profilePath) {
        $content = Get-Content $profilePath -Raw
        
        if ($content -match 'openclaw') {
            # Create backup
            $backupPath = "$profilePath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item $profilePath $backupPath
            
            # Remove openclaw-related lines
            $newContent = ($content -split "`n" | Where-Object { $_ -notmatch 'openclaw' }) -join "`n"
            Set-Content -Path $profilePath -Value $newContent
            
            Write-Success "Removed integration from PowerShell profile"
            Write-Info "Backup saved to: $backupPath"
        } else {
            Write-Info "No OpenClaw integration found in PowerShell profile"
        }
    } else {
        Write-Info "PowerShell profile not found"
    }
}

function Remove-ScheduledTasks {
    Write-Step "Checking for scheduled tasks"
    
    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*openclaw*" }
        
        if ($tasks) {
            foreach ($task in $tasks) {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                Write-Success "Removed scheduled task: $($task.TaskName)"
            }
        } else {
            Write-Info "No scheduled tasks found"
        }
    } catch {
        Write-Warning "Could not check scheduled tasks: $_"
    }
}

function Remove-StartupEntries {
    Write-Step "Checking for startup entries"
    
    $startupPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $startupItems = Get-ChildItem -Path $startupPath -Filter "*openclaw*" -ErrorAction SilentlyContinue
    
    if ($startupItems) {
        foreach ($item in $startupItems) {
            Remove-Item -Path $item.FullName -Force
            Write-Success "Removed startup item: $($item.Name)"
        }
    } else {
        Write-Info "No startup entries found"
    }
}

function Remove-Cache {
    Write-Step "Cleaning up cache"
    
    $cacheDirs = @(
        (Join-Path $env:LOCALAPPDATA "openclaw"),
        (Join-Path $env:TEMP "openclaw")
    )
    
    foreach ($dir in $cacheDirs) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force
            Write-Success "Removed $dir"
        }
    }
}

function Main {
    Write-Host ""
    Confirm-Uninstall
    Write-Host ""
    
    Stop-Gateway
    Remove-ScheduledTasks
    Remove-StartupEntries
    Remove-NpmPackages
    Remove-GitInstallation
    Remove-PowerShellProfile
    Remove-PathEntries
    Remove-Cache
    Remove-ConfigFiles
    
    Write-Host ""
    Write-Success "OpenClaw has been uninstalled"
    Write-Host ""
    Write-Info "Note: Node.js was not removed (it may be used by other applications)"
    Write-Info "If you want to remove Node.js, use: winget uninstall OpenJS.NodeJS.LTS"
    Write-Host ""
    Write-Info "Please restart PowerShell for PATH changes to take effect"
    Write-Host ""
}

Main
