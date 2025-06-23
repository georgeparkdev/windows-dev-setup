#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows Development Environment Setup
.DESCRIPTION
    Installs and configures essential development tools for Windows in an idempotent, modular fashion.
.NOTES
    Author: George Park
    Email: georgepark.dev@outlook.com
#>

param(
    [string]$GitUserName = "George Park",
    [string]$GitUserEmail = "georgepark.dev@outlook.com"
)

#------------------------------
# Global Configuration & Versions
#------------------------------
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$LogFile = "$env:TEMP\WinDevSetup_$(Get-Date -Format yyyyMMdd_HHmmss).log"
Start-Transcript -Path $LogFile -Force

$Applications = @{
    PowerToys       = 'Microsoft.PowerToys'
    Git             = 'Git.Git'
    WindowsTerminal = 'Microsoft.WindowsTerminal'
    PowerShell      = 'Microsoft.PowerShell'
    DotNetSDK       = 'Microsoft.DotNet.SDK.9'
    Python          = 'Python.Python.3.12'
    NodeJS          = 'OpenJS.NodeJS.LTS'
    PHP             = 'PHP.PHP.8.4'
    Docker          = 'Docker.DockerDesktop'
    VSCode          = 'Microsoft.VisualStudioCode'
    Ollama          = 'Ollama.Ollama'
}

#------------------------------
# Helper Functions
#------------------------------
function Write-Section {
    param([string]$Title)
    Write-Host "`n$Title" -ForegroundColor Cyan
    Write-Host ('-' * $Title.Length) -ForegroundColor Cyan
}

function Invoke-WithRetry {
    param(
        [ScriptBlock]$Action,
        [int]$MaxAttempts = 3
    )
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try { return & $Action } catch {
            if ($i -eq $MaxAttempts) { throw }
            Start-Sleep -Seconds (2 * $i)
        }
    }
}

function Install-WingetApp {
    param([string]$Id, [string]$Name)
    if (winget list --id $Id --exact 2>$null) {
        Write-Host "[SKIP] $Name already installed" -ForegroundColor Yellow
        return $true
    }
    Write-Host "Installing $Name..." -NoNewline
    $output = Invoke-WithRetry { winget install $Id --exact --silent --accept-source-agreements --accept-package-agreements } 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host " FAIL (Exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "Details:" -ForegroundColor DarkYellow
        $output | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        return $false
    }
}

function Update-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    [Environment]::SetEnvironmentVariable('Path', "$machine;$user", 'User')
    Write-Host 'User PATH persisted' -ForegroundColor Yellow
}

function Install-PythonPackages {
    Write-Host '-> Installing Python packages...' -NoNewline
    & python -m pip install --upgrade pip
    & pip install virtualenv pylint
    Write-Host ' Done' -ForegroundColor Green
}

function Install-NodePackages {
    Write-Host '-> Installing Node.js packages...' -NoNewline
    npm install -g typescript yarn eslint
    Write-Host ' Done' -ForegroundColor Green
}

function Install-Php {
    Write-Host '-> Installing PHP...' -ForegroundColor Cyan

    # Idempotent winget install of PHP 8.4
    if (Install-WingetApp -Id $Applications.PHP -Name 'PHP 8.4') {
        Write-Host ' PHP 8.4 is installed or already present.' -ForegroundColor Green
    }
    else {
        Write-Host ' PHP installation failed.' -ForegroundColor Red
        return
    }

    # Persist PATH so php.exe becomes available in this and future sessions
    Write-Host '-> Persisting PATH updates...' -ForegroundColor Cyan
    Update-Path

    # Immediate validation (reload env for current session)
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'User')
    Write-Host '-> Verifying PHP version...' -ForegroundColor Cyan
    php -v | Select-String '^PHP' | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Green
    }

    Write-Host 'PHP provisioning complete.' -ForegroundColor Green
}

function Ensure-WSL2 {
    if (-not (wsl.exe --status 2>$null)) {
        Write-Host '-> Enabling WSL2 feature...' -NoNewline
        Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -NoRestart | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -NoRestart | Out-Null
        Write-Host ' Done' -ForegroundColor Green
    }
}

function Install-DockerDesktop {
    Ensure-WSL2
    Install-WingetApp -Id $Applications.Docker -Name 'Docker Desktop'
}

function Configure-VSCodeGitEditor {
    Write-Host '-> Setting VS Code as Git editor...' -NoNewline
    git config --global core.editor 'code --wait'
    Write-Host ' Done' -ForegroundColor Green
}

#------------------------------
# Main Execution
#------------------------------
Write-Host '=== Windows Dev Setup ===' -ForegroundColor Cyan

Write-Section 'Core Utilities'
Install-WingetApp -Id $Applications.PowerToys -Name 'PowerToys'

Write-Section 'Windows Explorer'
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0
Write-Host 'Explorer configured' -ForegroundColor Green

Write-Section 'Git'
Install-WingetApp -Id $Applications.Git -Name 'Git'
if ($?) { git config --global user.name  $GitUserName; git config --global user.email $GitUserEmail; Write-Host 'Git user configured' -ForegroundColor Green }

Write-Section 'Terminal & Shell'
Install-WingetApp -Id $Applications.WindowsTerminal -Name 'Windows Terminal'
Install-WingetApp -Id $Applications.PowerShell -Name 'PowerShell 7'

Write-Section 'SDKs & Runtimes'
Install-WingetApp -Id $Applications.DotNetSDK -Name '.NET SDK 9'
Install-WingetApp -Id $Applications.Python  -Name 'Python 3.12'
if ($?) { Install-PythonPackages }
Install-WingetApp -Id $Applications.NodeJS  -Name 'Node.js LTS'
if ($?) { Install-NodePackages }

Write-Section 'PHP'
Install-Php

Write-Section 'Docker Desktop'
Install-DockerDesktop

Write-Section 'Visual Studio Code'
Install-WingetApp -Id $Applications.VSCode -Name 'Visual Studio Code'

Write-Section 'Ollama'
Install-WingetApp -Id $Applications.Ollama -Name 'Ollama'

Configure-VSCodeGitEditor

Write-Host "`nSetup complete. Log: $LogFile" -ForegroundColor Green
Stop-Transcript
