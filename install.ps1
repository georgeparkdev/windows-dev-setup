#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows Development Environment Setup 
.DESCRIPTION
    Installs essential development tools for Windows.
.NOTES
    Author: George Park
    Email: georgepark.dev@outlook.com
#>

param(
    [string]$GitUserName = "George Park",
    [string]$GitUserEmail = "georgepark.dev@outlook.com"
)

# PowerToys
Write-Host "PowerToys"
Write-Host "----------------------------------------"
winget install Microsoft.PowerToys --exact --no-upgrade --silent
Write-Host "DONE: PowerToys." -ForegroundColor Green

# Registry Update
Write-Host "Registry Update"
Write-Host "----------------------------------------"
## Show hidden files
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1
## Show file extensions for known file types
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0
Write-Host "DONE: Registry updated." -ForegroundColor Green

# Git
Write-Host "Git"
Write-Host "----------------------------------------"
winget install Git.Git --exact --no-upgrade --silent
git config --global user.name $GitUserName
git config --global user.email $GitUserEmail
Write-Host "DONE: Git has been installed and user has been configured." -ForegroundColor Green

# Windows Terminal
Write-Host "Windows Terminal"
Write-Host "----------------------------------------"
winget install Microsoft.WindowsTerminal --exact --no-upgrade --silent
Write-Host "DONE: Windows Terminal." -ForegroundColor Green

# PowerShell 7
Write-Host "PowerShell 7"
Write-Host "----------------------------------------"
winget install Microsoft.PowerShell --exact --no-upgrade --silent
Write-Host "DONE: PowerShell 7." -ForegroundColor Green

# .NET SDK 9
Write-Host ".NET SDK 10"
Write-Host "----------------------------------------"
winget install Microsoft.DotNet.SDK.10 --exact --no-upgrade --silent
Write-Host "DONE: .NET SDK 10." -ForegroundColor Green

# Python 3.12
Write-Host "Python 3.12"
Write-Host "----------------------------------------"
winget install Python.Python.3.12 --exact --no-upgrade --silent
Write-Host "DONE: Python 3.12." -ForegroundColor Green

# Node.js LTS
Write-Host "Node.js LTS"
Write-Host "----------------------------------------"
winget install OpenJS.NodeJS.LTS --exact --no-upgrade --silent
Write-Host "DONE: Node.js LTS." -ForegroundColor Green

# PHP 8.4
Write-Host "PHP 8.4"
Write-Host "----------------------------------------"
winget install PHP.PHP.8.4 --exact --no-upgrade --silent
Write-Host "DONE: PHP 8.4." -ForegroundColor Green

# Docker Desktop
Write-Host "Docker Desktop"
Write-Host "----------------------------------------"
winget install Docker.DockerDesktop --exact --no-upgrade --silent
Write-Host "DONE: Docker Desktop." -ForegroundColor Green

# Visual Studio Code
Write-Host "Visual Studio Code"
Write-Host "----------------------------------------"
winget install Microsoft.VisualStudioCode --exact --no-upgrade --silent
git config --global core.editor "code --wait"
Write-Host "DONE: VS Code has been installed and configured as git editor." -ForegroundColor Green

Write-Host "`nSetup complete!" -ForegroundColor Green
