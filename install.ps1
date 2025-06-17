<#
.SYNOPSIS
  Enterprise-grade environment bootstrapper for Windows 11 developer workstations.

.DESCRIPTION
  - Elevates to Administrator
  - Shows hidden files & file extensions
  - Installs (or skips if present) Powertoys, Git, Windows Terminal, PowerShell, OhMyPosh,
    .NET SDK, Python, Node.js, Docker with WSL2+Ubuntu, VS Code, and Postman.
  - Configures OhMyPosh prompt and Windows Terminal font.
  - Idempotent: will not re-install existing components.
#>

#region -- Self‑Elevation and Globals --

function Assert-IsAdministrator {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Administrator privileges required. Relaunching with elevation..."
        Start-Process -FilePath pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

# Global list of packages to install via Winget
$Packages = @{
    'Microsoft.PowerToys'         = @{ Name = 'PowerToys';            Id = 'Microsoft.PowerToys'            }
    'Git.Git'                     = @{ Name = 'Git';                  Id = 'Git.Git'                        }
    'Microsoft.WindowsTerminal'   = @{ Name = 'Windows Terminal';     Id = 'Microsoft.WindowsTerminal'     }
    'Microsoft.PowerShell'        = @{ Name = 'PowerShell (7+)';      Id = 'Microsoft.PowerShell'          }
    'JanDeDobbeleer.OhMyPosh'     = @{ Name = 'OhMyPosh';             Id = 'JanDeDobbeleer.OhMyPosh'       }
    'Microsoft.DotNet.SDK.8'      = @{ Name = '.NET 8 SDK';           Id = 'Microsoft.DotNet.SDK.8'        }
    'Python.Python.3'             = @{ Name = 'Python 3';             Id = 'Python.Python.3'               }
    'OpenJS.NodeJS.LTS'           = @{ Name = 'Node.js LTS';          Id = 'OpenJS.NodeJS.LTS'             }
    'Docker.DockerDesktop'        = @{ Name = 'Docker Desktop';       Id = 'Docker.DockerDesktop'          }
    'Microsoft.VisualStudioCode'  = @{ Name = 'Visual Studio Code';   Id = 'Microsoft.VisualStudioCode'    }
    'Postman.Postman'             = @{ Name = 'Postman';              Id = 'Postman.Postman'               }
}

#endregion

#region -- Utility Functions --

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
}

function Install-PackageIfMissing {
    param(
        [string]$Id,
        [string]$FriendlyName
    )
    if (winget list --id $Id 2>$null) {
        Write-Log "✔️ Skipping $FriendlyName (already installed)." Green
    }
    else {
        Write-Log "⏳ Installing $FriendlyName..." Yellow
        winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ $FriendlyName installed successfully." Green
        }
        else {
            Write-Log "❌ Failed to install $FriendlyName. Exit code: $LASTEXITCODE" Red
        }
    }
}

#endregion

#region -- Begin Provisioning --

Assert-IsAdministrator
Write-Log "`n=== Starting Windows 11 Developer Bootstrap: $(Get-Date -Format u) ===`n" Cyan

# 1. PowerToys
Install-PackageIfMissing -Id $Packages['Microsoft.PowerToys'].Id -FriendlyName $Packages['Microsoft.PowerToys'].Name

# 2 & 3. Explorer settings: show hidden files & known file extensions
Write-Log "`nConfiguring Explorer settings..." Cyan
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden      -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0
Write-Log "✅ Explorer configured to show hidden files and file extensions." Green

# 4. Git + global config
Install-PackageIfMissing -Id $Packages['Git.Git'].Id -FriendlyName $Packages['Git.Git'].Name
if (Get-Command git -ErrorAction SilentlyContinue) {
    git config --global user.name  "Your Name"
    git config --global user.email "you@example.com"
    Write-Log "✅ Git global user.name/user.email configured." Green
}

# 5–7. Terminal, PowerShell & OhMyPosh
foreach ($key in 'Microsoft.WindowsTerminal','Microsoft.PowerShell','JanDeDobbeleer.OhMyPosh') {
    Install-PackageIfMissing -Id $Packages[$key].Id -FriendlyName $Packages[$key].Name
}

# OhMyPosh theme activation
$ThemePath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\paradox.omp.json"
if (-Not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
if (-not (Select-String -Path $PROFILE -Pattern 'oh-my-posh init')) {
    Add-Content $PROFILE @"
`$env:OMP_THEME = '$ThemePath'
oh-my-posh init pwsh --config `"$env:OMP_THEME`" | Invoke-Expression
"@
    Write-Log "✅ OhMyPosh prompt configured in your PowerShell profile." Green
}

# 8–10. .NET, Python & Node.js
foreach ($key in 'Microsoft.DotNet.SDK.8','Python.Python.3','OpenJS.NodeJS.LTS') {
    Install-PackageIfMissing -Id $Packages[$key].Id -FriendlyName $Packages[$key].Name
}

# 11. Docker with WSL2 (Ubuntu)
Install-PackageIfMissing -Id 'Microsoft.WSL'           -FriendlyName 'WSL2'
wsl --install -d Ubuntu --quiet
Install-PackageIfMissing -Id 'Docker.DockerDesktop'    -FriendlyName 'Docker Desktop'

# 12. VS Code + Git editor
Install-PackageIfMissing -Id 'Microsoft.VisualStudioCode' -FriendlyName 'Visual Studio Code'
if (Get-Command code -ErrorAction SilentlyContinue) {
    git config --global core.editor "code --wait"
    Write-Log "✅ VS Code set as Git editor." Green
}

# 13. Postman
Install-PackageIfMissing -Id 'Postman.Postman' -FriendlyName 'Postman'

Write-Log "`n=== Bootstrap Complete! Enjoy your future‑proof dev environment. ===`n" Cyan
#endregion
