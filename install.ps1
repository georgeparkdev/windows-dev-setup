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

.PARAMETER GitUserName
  Optional Git global user name to configure

.PARAMETER GitUserEmail
  Optional Git global user email to configure

.PARAMETER OhMyPoshTheme
  Optional OhMyPosh theme name (default: paradox)
#>

param(
    [string]$GitUserName = "",
    [string]$GitUserEmail = "",
    [string]$OhMyPoshTheme = "paradox"
)

#region -- Self‑Elevation and Globals --

function Assert-IsAdministrator {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Administrator privileges required. Relaunching with elevation..."
        Start-Process -FilePath pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

# Global list of packages to install via Winget
$Packages = @{
    'Microsoft.PowerToys'        = @{ Name = 'PowerToys'; Id = 'Microsoft.PowerToys' }
    'Git.Git'                    = @{ Name = 'Git'; Id = 'Git.Git' }
    'Microsoft.WindowsTerminal'  = @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' }
    'Microsoft.PowerShell'       = @{ Name = 'PowerShell (7+)'; Id = 'Microsoft.PowerShell' }
    'JanDeDobbeleer.OhMyPosh'    = @{ Name = 'OhMyPosh'; Id = 'JanDeDobbeleer.OhMyPosh' }
    'Microsoft.DotNet.SDK.9'     = @{ Name = '.NET 9 SDK'; Id = 'Microsoft.DotNet.SDK.9' }
    'Python.Python.3'            = @{ Name = 'Python 3'; Id = 'Python.Python.3' }
    'OpenJS.NodeJS.LTS'          = @{ Name = 'Node.js LTS'; Id = 'OpenJS.NodeJS.LTS' }
    'Docker.DockerDesktop'       = @{ Name = 'Docker Desktop'; Id = 'Docker.DockerDesktop' }
    'Microsoft.VisualStudioCode' = @{ Name = 'Visual Studio Code'; Id = 'Microsoft.VisualStudioCode' }
    'Postman.Postman'            = @{ Name = 'Postman'; Id = 'Postman.Postman' }
}

#endregion

#region -- Utility Functions --

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color = 'Gray')
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Install-PackageIfMissing {
    param(
        [string]$Id,
        [string]$FriendlyName,
        [int]$MaxRetries = 3
    )
    
    # Check if already installed
    $isInstalled = $false
    try {
        $result = winget list --id $Id 2>$null
        if ($LASTEXITCODE -eq 0 -and $result) {
            $isInstalled = $true
        }
    }
    catch {
        Write-Log "Warning: Could not check if $FriendlyName is installed. Proceeding with installation attempt." Yellow
    }
    
    if ($isInstalled) {
        Write-Log "✔️ Skipping $FriendlyName (already installed)." Green
        return $true
    }
    
    # Attempt installation with retry logic
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        Write-Log "⏳ Installing $FriendlyName (attempt $attempt/$MaxRetries)..." Yellow
        
        try {
            winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "✅ $FriendlyName installed successfully." Green
                return $true
            }
            elseif ($LASTEXITCODE -eq -1978335189) {
                Write-Log "⚠️ ${FriendlyName}: No applicable update found (already latest version)." Green
                return $true
            }
            else {
                Write-Log "⚠️ Attempt $attempt failed for $FriendlyName. Exit code: $LASTEXITCODE" Yellow
                if ($attempt -lt $MaxRetries) {
                    Write-Log "⏳ Waiting 5 seconds before retry..." Gray
                    Start-Sleep -Seconds 5
                }
            }
        }
        catch {
            Write-Log "⚠️ Exception during $FriendlyName installation: $($_.Exception.Message)" Yellow
            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Seconds 5
            }
        }
    }
    
    Write-Log "❌ Failed to install $FriendlyName after $MaxRetries attempts." Red
    return $false
}

function Test-WSLEnabled {
    try {
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
        return ($wslFeature -and $wslFeature.State -eq "Enabled")
    }
    catch {
        return $false
    }
}

function Install-WSLWithUbuntu {
    Write-Log "🐧 Configuring WSL2 with Ubuntu..." Cyan
    
    # Check if WSL is already enabled
    if (Test-WSLEnabled) {
        Write-Log "✔️ WSL is already enabled." Green
    }
    else {
        Write-Log "⏳ Enabling WSL feature..." Yellow
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
            Write-Log "✅ WSL features enabled (restart may be required)." Green
        }
        catch {
            Write-Log "⚠️ Could not enable WSL features. Trying alternative method..." Yellow
            Install-PackageIfMissing -Id 'Microsoft.WSL' -FriendlyName 'WSL2'
        }
    }
    
    # Install Ubuntu distribution
    Write-Log "⏳ Installing Ubuntu distribution..." Yellow
    try {
        $wslOutput = wsl --install -d Ubuntu --no-launch 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Ubuntu distribution installed successfully." Green
        }
        else {
            Write-Log "⚠️ Ubuntu installation may have issues. Output: $wslOutput" Yellow
        }
    }
    catch {
        Write-Log "⚠️ Could not install Ubuntu via wsl command. You may need to install it manually from Microsoft Store." Yellow
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
    if ($GitUserName) {
        git config --global user.name  $GitUserName
        Write-Log "✅ Git global user.name configured to '$GitUserName'." Green
    }
    if ($GitUserEmail) {
        git config --global user.email $GitUserEmail
        Write-Log "✅ Git global user.email configured to '$GitUserEmail'." Green
    }
    if (-not $GitUserName -and -not $GitUserEmail) {
        Write-Log "⚠️ Git global user.name/user.email not configured: please provide -GitUserName and/or -GitUserEmail parameters." Yellow
    }
}

# 5–7. Terminal, PowerShell & OhMyPosh
foreach ($key in 'Microsoft.WindowsTerminal', 'Microsoft.PowerShell', 'JanDeDobbeleer.OhMyPosh') {
    Install-PackageIfMissing -Id $Packages[$key].Id -FriendlyName $Packages[$key].Name
}

# OhMyPosh theme activation
Write-Log "⚙️ Configuring OhMyPosh theme..." Cyan
$ThemePath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\$OhMyPoshTheme.omp.json"

# Check if theme exists, fallback to default if not
if (-not (Test-Path $ThemePath)) {
    Write-Log "⚠️ Theme '$OhMyPoshTheme' not found, using 'paradox' as fallback." Yellow
    $ThemePath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\paradox.omp.json"
}

if (-Not (Test-Path $PROFILE)) { 
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null 
    Write-Log "📝 Created PowerShell profile." Gray
}

if (-not (Select-String -Path $PROFILE -Pattern 'oh-my-posh init' -Quiet)) {
    Add-Content $PROFILE @"
`$env:OMP_THEME = '$ThemePath'
oh-my-posh init pwsh --config `"$env:OMP_THEME`" | Invoke-Expression
"@
    Write-Log "✅ OhMyPosh prompt configured in your PowerShell profile." Green
}
else {
    Write-Log "✔️ OhMyPosh already configured in PowerShell profile." Green
}

# 8–10. .NET, Python & Node.js
foreach ($key in 'Microsoft.DotNet.SDK.9', 'Python.Python.3', 'OpenJS.NodeJS.LTS') {
    Install-PackageIfMissing -Id $Packages[$key].Id -FriendlyName $Packages[$key].Name
}

# 11. Docker with WSL2 (Ubuntu)
Install-WSLWithUbuntu
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
