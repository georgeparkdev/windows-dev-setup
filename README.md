# Windows Dev Setup

A PowerShell script that installs essential development tools for Windows.

## What's Installed

- PowerToys - Windows utilities
- Git
- Windows Terminal
- PowerShell 7
- .NET SDK 10
- Python 3.12
- Node.js
- PHP 8.4
- Docker Desktop
- Visual Studio Code
- Windows Explorer settings - Show hidden files and file extensions

## Usage

1. Launch PowerShell as Administrator

2. Run the script:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
.\install.ps1
```

## Parameters

- GitUserName (string) - Default: "George Park" - Sets global Git user name
- GitUserEmail (string) - Default: "georgepark.dev@outlook.com" - Sets global Git email

Example with custom Git settings:

```powershell
.\install.ps1 -GitUserName "Your Name" -GitUserEmail "you@example.com"
```

## Notes

- Requires Windows with winget installed
- Applications are installed via winget

## Author

George Park  
georgepark.dev@outlook.com
