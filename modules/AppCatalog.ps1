# AppCatalog.ps1
# Curated catalog of popular WinGet applications grouped by category.
# Inspired by the "Install" tab in ChrisTitusTech/winutil and memstechtips/Winhance.
# Used by the GUI to let the user tick apps that are auto-installed on first boot
# (via the WinGet first-boot script injected by PostInstallInjector.ps1).

function Get-AppCatalog {
    <#
    .SYNOPSIS
        Returns a curated catalog of WinGet apps grouped by category.
        Each entry: @{ Id = "<winget id>"; Name = "<display name>" }
    #>
    return [ordered]@{
        "Browsers" = @(
            @{ Id = "Google.Chrome";            Name = "Google Chrome" }
            @{ Id = "Mozilla.Firefox";          Name = "Mozilla Firefox" }
            @{ Id = "Brave.Brave";              Name = "Brave" }
            @{ Id = "TheBrowserCompany.Arc";    Name = "Arc" }
        )
        "Communication" = @(
            @{ Id = "Discord.Discord";          Name = "Discord" }
            @{ Id = "Telegram.TelegramDesktop"; Name = "Telegram" }
            @{ Id = "Zoom.Zoom";                Name = "Zoom" }
        )
        "Development" = @(
            @{ Id = "Microsoft.VisualStudioCode"; Name = "VS Code" }
            @{ Id = "Git.Git";                    Name = "Git" }
            @{ Id = "Python.Python.3.12";         Name = "Python 3.12" }
            @{ Id = "OpenJS.NodeJS";              Name = "Node.js" }
            @{ Id = "Microsoft.PowerShell";       Name = "PowerShell 7" }
            @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" }
        )
        "Media" = @(
            @{ Id = "VideoLAN.VLC";             Name = "VLC" }
            @{ Id = "Spotify.Spotify";          Name = "Spotify" }
            @{ Id = "OBSProject.OBSStudio";     Name = "OBS Studio" }
            @{ Id = "GIMP.GIMP";                Name = "GIMP" }
        )
        "Utilities" = @(
            @{ Id = "7zip.7zip";                Name = "7-Zip" }
            @{ Id = "Notepad++.Notepad++";      Name = "Notepad++" }
            @{ Id = "voidtools.Everything";     Name = "Everything" }
            @{ Id = "REALiX.HWiNFO";            Name = "HWiNFO" }
            @{ Id = "CPUID.CPU-Z";              Name = "CPU-Z" }
            @{ Id = "Microsoft.PowerToys";      Name = "PowerToys" }
        )
        "Gaming" = @(
            @{ Id = "Valve.Steam";              Name = "Steam" }
            @{ Id = "EpicGames.EpicGamesLauncher"; Name = "Epic Games" }
            @{ Id = "Discord.Discord";          Name = "Discord" }
        )
        "Documents" = @(
            @{ Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Acrobat Reader" }
            @{ Id = "LibreOffice.LibreOffice";  Name = "LibreOffice" }
        )
    }
}
