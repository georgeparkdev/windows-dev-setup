# ⚙️ Windows Dev Setup

A fast, idempotent PowerShell script to provision a full-featured Windows development environment. Ideal for fresh installs or reinitializing tooling without manual overhead.

---

## 📦 What’s Installed

| Tool / Stack            | Description                                    |
|-------------------------|------------------------------------------------|
| Git                    | Installed via winget, global username/email set |
| PowerToys              | Windows utilities for enhanced UX              |
| Windows Terminal       | Modern terminal for multi-shell usage          |
| PowerShell 7           | Latest cross-platform shell                    |
| .NET SDK 9             | Microsoft’s latest software development kit    |
| Python 3.12            | Includes `pip`, `virtualenv`, `pylint`         |
| Node.js LTS            | Includes `typescript`, `eslint`, `yarn`       |
| PHP 8.4                | CLI + path persistence, version check          |
| Docker Desktop         | Configures WSL2 support if needed              |
| Visual Studio Code     | Configured as default Git editor               |
| Ollama                 | Pulls Ollama if enabled                        |

---

## 🚀 Usage

### 1. Launch PowerShell as **Administrator**

### 2. Run the script

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
.\install.ps1
````

---

## 🧾 Parameters

| Parameter            | Type     | Default                        | Description                                      |
| -------------------- | -------- | ------------------------------ | ------------------------------------------------ |
| `GitUserName`        | `string` | `"George Park"`                | Sets the global Git user name                    |
| `GitUserEmail`       | `string` | `"georgepark.dev@outlook.com"` | Sets the global Git email                        |
| `InstallDeepSeekCoderV2` | `switch` | `$false`                       | Pulls DeepSeek-Coder-V2 model via Ollama |

### Example with all parameters:

```powershell
.\WinDevSetup.ps1 -GitUserName "Your Name" -GitUserEmail "you@example.com" -InstallDeepSeekCoderV2
```

---

## 🧠 Notes

* ✅ Safe to rerun — skips already-installed packages.
* ✅ Auto-configures `$PATH`, Git editor, and shell defaults.
* 🪵 Logs stored at: `%TEMP%\WinDevSetup_<timestamp>.log`
* 💡 Requires Windows with [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) installed.

---

## 🧠 Optional: Ollama Model Setup

To install **DeepSeek-Coder-V2 (16B)** via [Ollama](https://ollama.com):

```powershell
.\WinDevSetup.ps1 -InstallDeepSeekCoderV2
```

Combined with Git config:

```powershell
.\WinDevSetup.ps1 -GitUserName "Your Name" -GitUserEmail "you@example.com" -InstallDeepSeekCoderV2
```

---

## 📬 Author

**George Park**
[georgepark.dev@outlook.com](mailto:georgepark.dev@outlook.com)

---
