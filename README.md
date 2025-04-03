# Windows-ISO-Debloater

![Stars](https://img.shields.io/github/stars/itsNileshHere/Windows-ISO-Debloater?style=for-the-badge)
[![Version](https://img.shields.io/github/v/release/itsNileshHere/Windows-ISO-Debloater?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/itsNileshHere/Windows-ISO-Debloater/releases/latest)

</div>

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
Set-ExecutionPolicy -Scope Process Unrestricted -Force
iwr -useb https://itsnileshhere.github.io/Windows-ISO-Debloater/download.ps1 | iex
```

### Option 2: Manual Download and Execution

1. Download the latest release from [here](https://github.com/itsNileshHere/Windows-ISO-Debloater/releases/latest)
2. Extract the downloaded package
3. Right-click on the script and select "Run with PowerShell" (as Administrator)

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

The script uses `oscdimg.exe` to generate the new ISO file. This tool is:

1. **Automatically downloaded** from Microsoft's servers during script execution
2. **Used to create** a bootable ISO with the modified Windows installation files

For those who prefer to use their own copy of oscdimg.exe:

1. Download the "Windows ADK" from [Microsoft's official site](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
2. During installation, select only the "Deployment Tools" component
3. Navigate to: `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg`
4. Copy `oscdimg.exe` alongside the script

### IMAPI2FS ISO Generation Method (Experimental)

An alternative, ISO generation method using the [IMAPI2FS interface](https://learn.microsoft.com/en-us/windows/win32/api/_imapi/) is also available:

1. **Native Windows COM Objects**: Uses native Windows components without requiring external dependencies
2. **No oscdimg.exe Required**: Creates bootable ISOs directly through Windows COM interfaces
3. **Potentially More Compatible**: May work in environments where oscdimg has issues

To use this method:
1. Run the [`isoDebloaterScript_IMAPI2FS.ps1`](https://github.com/itsNileshHere/Windows-ISO-Debloater/blob/main/isoDebloaterScript_IMAPI2FS.ps1) script instead of the main script
2. Follow the same process as with the regular method
3. The ISO will be generated using the IMAPI2FS interfaces

⚠️ **Note**: This method is still considered experimental and may not work in all environments.

## 📊 What Gets Removed?

The script can remove various components based on preferences, including:

- **Pre-installed Bloats**: Candy Crush, Disney+, Spotify, TikTok, etc.
- **Microsoft Apps**: OneDrive, Skype, Teams, Office installers, Edge (optional)
- **System Components**: Windows Media Player, Windows Fax and Scan, etc.
- **Features**: Telemetry services, unnecessary language packs, etc.

## 🌟 Credits

- [tiny11builder](https://github.com/ntdevlabs/tiny11builder) for inspiration and approach
- [Winaero](https://winaero.com/) for registry optimization techniques
- Microsoft for providing oscdimg.exe and Windows ADK tools

## ⚠️ Disclaimer

This script modifies critical system files within the Windows ISO. While extensively tested, it's provided "as is" without warranties. The author is not liable for any damages that might occur from its use.

- **Use at own risk**
- **Always back up important data** before installing a modified Windows version

## 📜 License

This project is licensed under the [GPL-3.0 License](https://github.com/itsNileshHere/Windows-ISO-Debloater/blob/main/LICENSE).
