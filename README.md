# Windows Dev Setup

This script was made for personal use to quickly set up a Windows dev environment. It’s clean, fast, and idempotent—great for fresh installs or resetting tools. Others are welcome to use or modify it if it fits their workflow.

---

## What it installs

- Git + config
- PowerToys
- Windows Terminal
- PowerShell 7
- .NET SDK 9
- Python 3.12 (+ pip packages)
- Node.js LTS (+ global packages)
- PHP 8.4
- Docker Desktop (with WSL2 setup)
- Visual Studio Code (set as Git editor)
- Ollama

---

## How to run it

1. Open PowerShell **as Administrator**
2. Run:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope Process -Force
   .\WinDevSetup.ps1
   ```

   You can also pass your Git name and email:

   ```powershell
   .\WinDevSetup.ps1 -GitUserName "Your Name" -GitUserEmail "you@example.com"
   ```

---

## Notes

- Needs Windows with `winget` installed
- Logs saved to your temp folder
- Safe to rerun—skips already-installed tools
- Automatically updates your PATH and configures Git

---
