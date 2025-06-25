# Windows-ISO-Debloater

![Stars](https://img.shields.io/github/stars/itsNileshHere/Windows-ISO-Debloater?style=for-the-badge)
[![Version](https://img.shields.io/github/v/release/itsNileshHere/Windows-ISO-Debloater?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/itsNileshHere/Windows-ISO-Debloater/releases/latest)
[![Total Downloads](https://img.shields.io/github/downloads/itsNileshHere/Windows-ISO-Debloater/total?label=Total%20Downloads&style=for-the-badge)](https://github.com/itsNileshHere/Windows-ISO-Debloater/releases/latest)

## 📋 Overview

An easy-to-use and customizable PowerShell script designed to optimize and debloat Windows ISO by removing unnecessary apps & components. Helps to create lightweight, clean ISOs for streamlined installations. Ideal for improved system performance and full control over Windows installation customization.

### Key Benefits:
- **Performance Boost**: Creates lightweight Windows installations
- **Clean Start**: Removes pre-installed bloatware before installation
- **Customizable**: Provides full control over what gets removed from the ISO
- **Privacy-Focused**: Removes components that may collect telemetry data
- **Smaller ISO Size**: Reduces the overall size of installation media

## 🧪 Tested Versions

The script has been thoroughly tested with:

- **Windows 10**: Version 22H2 (Build 19045.3757)
- **Windows 11**: Version 24H2 (Build 26100.1742)

⚠️ **Note**: The script should work with other Windows 10/11 versions as well.

## 🚀 Quick Installation

### Option 1: PowerShell Command (Recommended)

Launch PowerShell as **Administrator** and execute:

```powershell
irm "https://itsnileshhere.github.io/Windows-ISO-Debloater/download.ps1" | iex
```

### Option 2: Manual Download and Execution

Download the latest `isoDebloater.ps1` from [here](https://github.com/itsNileshHere/Windows-ISO-Debloater/releases/latest)

#### Command Line Arguments

```powershell
# SYNTAX
.\isoDebloaterScript.ps1 [OPTIONS]

# REQUIRED PARAMETERS FOR AUTOMATED MODE
-noPrompt                   # Run without prompts (requires -isoPath, -winEdition, -outputISO)
-isoPath "path\to\iso"      # Path to Windows ISO file
-winEdition "Name"          # Name of Windows image to process (e.g., "Windows 11 Pro")
-outputISO "Name"           # Output ISO filename (without extension)

# CUSTOMIZATION PARAMETERS (All accept "yes" or "no") [Optional]
-AppxRemove "yes"           # Remove Microsoft Store apps [Default: yes]
-CapabilitiesRemove "yes"   # Remove optional Windows features [Default: yes]
-OnedriveRemove "yes"       # Remove OneDrive completely [Default: yes]
-EDGERemove "yes"           # Remove Microsoft Edge browser [Default: yes]
-TPMBypass "no"             # Bypass TPM & hardware checks [Default: no]
-UserFoldersEnable "yes"    # Enable user folders in Explorer [Default: yes]
-ESDConvert "no"            # Compress ISO using ESD compression [Default: no]
-useOscdimg "yes"           # Use oscdimg.exe for ISO creation [Default: yes]

# EXAMPLES
# Basic usage with interactive prompts:
.\isoDebloaterScript.ps1

# Fully automated with no prompts:
.\isoDebloaterScript.ps1 -noPrompt -isoPath "C:\path\to\windows.iso" -winEdition "Windows 11 Pro" -outputISO "Win11Debloat.iso"

# Customize specific options:
.\isoDebloaterScript.ps1 -isoPath "C:\path\to\windows.iso" -EDGERemove no -TPMBypass yes

# Create minimal Windows installation:
.\isoDebloaterScript.ps1 -AppxRemove yes -CapabilitiesRemove yes -OnedriveRemove yes -EDGERemove yes -ESDConvert yes
```

## 📝 Step-by-Step Usage Guide

1. After launching the script, a prompt will appear to select a Windows ISO file.
2. The script will mount the ISO and analyze its contents.
3. Options to customize which components to remove will be presented.
4. The script will process the ISO according to the selections.
5. A debloated ISO will be generated in the **same directory as the script**.

## 🛠️ Advanced Customization

### Packages & Features Management

Components to be removed can be customized by editing the script:

- **AppX Packages**: Modify the `$appxPatternsToRemove` array to include/exclude Microsoft Store apps
- **Windows Capabilities**: Edit the `$capabilitiesToRemove` array to manage optional Windows features
- **Windows Packages**: Adjust the `$windowsPackagesToRemove` array to control core Windows components

### Registry Tweaks

The script includes numerous registry optimizations to:
- Improve system performance
- Enhance privacy settings
- Disable telemetry and data collection
- Remove unnecessary UI elements

## ⚙️ Technical Details

### ISO Generation Tool

The script utilizes `oscdimg.exe`, a Microsoft tool for creating bootable ISO images. During execution, the script automatically downloads `oscdimg.exe` directly from Microsoft's servers and uses it to generate the modified ISO.

For those who prefer to use their own copy of oscdimg.exe:

1. Download the "Windows ADK" from [Microsoft's official site](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
2. During installation, select only the "Deployment Tools" component
3. Navigate to: `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg`
4. Check if `oscdimg.exe` is installed properly

### ISO Generation Methods

The script supports two methods for creating the final ISO file:

#### 1. Oscdimg Method (Default)

By default, the script uses `oscdimg.exe`, to create bootable ISO images
- Downloads automatically if not present
- Creates highly compatible ISO files
- Recommended for most users

To use this method (default):
```powershell
.\isoDebloaterScript.ps1 -useOscdimg yes
```

#### 2. IMAPI2FS Method (Alternative)

An alternative ISO generation method using the [IMAPI2FS interface](https://learn.microsoft.com/en-us/windows/win32/api/_imapi/)
- Uses native Windows COM objects without external dependencies
- Creates bootable ISOs directly through Windows COM interfaces
- May work in environments where oscdimg has issues

To use this method:
```powershell
.\isoDebloaterScript.ps1 -useOscdimg no
```

⚠️ **Note**: The IMAPI2FS method is still considered experimental and may not work in all environments.

## 📊 What Gets Removed?

The script can remove various components based on preferences, including:

- **Pre-installed Bloats**: Candy Crush, Disney+, Spotify, TikTok, etc.
- **Microsoft Apps**: OneDrive, Skype, Teams, Office installers, Edge (optional)
- **System Components**: Windows Media Player, Windows Fax and Scan, etc.
- **Features**: Telemetry services, unnecessary language packs, etc.

## ⭐ Support

If you find this project helpful, consider giving it a ⭐ on GitHub!

## 🌟 Credits

- [tiny11builder](https://github.com/ntdevlabs/tiny11builder) for inspiration and approach
- [Winaero](https://winaero.com/) for registry optimization techniques
- Microsoft for Windows ADK tools

## ⚠️ Disclaimer

This script modifies critical system files within the Windows ISO. While extensively tested, it's provided "as is" without warranties. The author is not liable for any damages that might occur from its use.

- **Use at own risk**
- **Always back up important data** before installing a modified Windows version

## 📜 License

This project is licensed under the [GPL-3.0 License](https://github.com/itsNileshHere/Windows-ISO-Debloater/blob/main/LICENSE).
