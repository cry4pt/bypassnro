# Gh0st$ec's Bypass NRO

A simple script to bypass the Windows 11 Microsoft account requirement during setup (OOBE), restoring the functionality that Microsoft removed in recent builds.

## ⚠️ Important Note
This method **skips the Windows Microsoft account requirement without debloating Windows**. All Windows features and functionality remain completely intact:
- ✅ Windows Defender and security features
- ✅ All built-in apps (Settings, Store, etc.)
- ✅ Windows Update functionality
- ✅ Cortana, OneDrive, and other Microsoft services
- ✅ Full system functionality

This only automates the initial setup process - nothing is removed or disabled.

## 🖥️ System Requirements
- **Windows 11** (23H2 or newer builds where OOBE\BYPASSNRO was removed)
- **Internet connection** (required for downloading the script)
- Must be run during **OOBE** (Out-of-Box Experience / Initial Setup)

## 📋 What This Script Does
1. Creates a local administrator account with your chosen username and password
2. Skips the Microsoft account sign-in requirement
3. Hides setup screens for:
   - EULA acceptance
   - OEM registration
   - Online account prompts
   - Wireless/WiFi setup
4. Sets privacy settings to minimal telemetry (ProtectYourPC=3)
5. Skips user and machine OOBE prompts
6. Automatically reboots and completes Windows setup

**You will still be able to select:**
- Language
- Region/Country
- Keyboard layout

## 🚀 Quick Start

### Step 1: Open Command Prompt
During the Windows setup (OOBE) screen, press:
```
Shift + F10
```
This opens an Administrator Command Prompt.

### Step 2: Run the Script
Copy and paste these commands:
```batch
curl -L https://raw.githubusercontent.com/cry4pt/bypassnro/refs/heads/main/bypass.cmd -o skip.cmd
skip.cmd
```

### Step 3: Follow the Prompts
1. Enter your desired username (letters, numbers, hyphens, underscores only)
2. Enter a password (minimum 8 characters)
3. Confirm your password
4. Press any key to confirm and start the process

### Step 4: Wait for Reboot
The system will automatically:
- Download and configure the necessary files
- Run Windows Sysprep
- Reboot and complete setup with your local account

## 🔧 Alternative Method (Manual Download)

If you want to review the script before running it:

```batch
curl -L https://raw.githubusercontent.com/cry4pt/bypassnro/refs/heads/main/bypass.cmd -o skip.cmd
notepad skip.cmd
```

Review the contents, then if satisfied:
```batch
skip.cmd
```

## 🛠️ Troubleshooting

### Shift + F10 doesn't work
- Try **Fn + Shift + F10** (on some laptops)
- Try **Shift + Fn + F10** (alternative combination)
- Ensure you're pressing it during the OOBE screen (region/language selection)

### "curl is not recognized" error
- Your Windows installation may not have curl available
- Try using the Windows PE environment or ensure you're on a recent Windows 11 build

### No internet connection
- Connect via Ethernet cable (recommended during OOBE)
- If WiFi only: You may need to complete WiFi setup first, then run the script
- Alternative: Download the script on another device and transfer via USB

### Script fails to download
- Check your internet connection
- Verify the GitHub URL is accessible
- Try again - temporary network issues may occur

### Sysprep fails to run
- Ensure you're running from OOBE, not a fully installed Windows
- The script requires administrator privileges (automatic when run from OOBE)
- Check that `C:\Windows\System32\Sysprep\Sysprep.exe` exists

## 🔒 Security & Privacy

### Password Security
- Passwords are handled using PowerShell's SecureString during input
- Temporary password file is immediately deleted after use
- Minimum 8-character requirement enforced

### What Gets Modified
- Creates `C:\Windows\Panther\unattend.xml` with your configuration
- Backs up existing unattend.xml if present
- No system files are modified or removed

### Privacy Settings
The script sets `ProtectYourPC=3`, which means:
- **Minimal** diagnostic data sent to Microsoft
- Location services disabled by default
- Personalized ads disabled
- Most privacy-protective default settings

You can change these settings after installation in Windows Settings > Privacy.

## 📝 Technical Details

### Files Modified
- `C:\Windows\Panther\unattend.xml` - Windows unattended setup configuration

### What Happens Behind the Scenes
1. Downloads unattend.xml template from GitHub
2. Modifies XML to insert your username and password
3. Configures OOBE skip settings
4. Runs Sysprep with the custom unattend.xml
5. System reboots and applies configuration
6. Boots directly to desktop with your local account

### OOBE Settings Applied
- `HideEULAPage` - Skips EULA acceptance
- `HideOnlineAccountScreens` - Skips Microsoft account prompts
- `HideWirelessSetupInOOBE` - Skips WiFi setup
- `HideOEMRegistrationScreen` - Skips OEM registration
- `SkipUserOOBE` - Skips user preference setup
- `SkipMachineOOBE` - Skips machine configuration setup
- `ProtectYourPC=3` - Minimal telemetry settings

## ⚖️ Legal & Disclaimer

This script automates the Windows setup process using official Microsoft unattend.xml functionality. It does not:
- Crack or bypass Windows activation
- Violate Windows license terms
- Modify system files improperly
- Install unauthorized software

**Use at your own risk.** Always ensure you have proper Windows licensing.

## 🤝 Contributing

Found an issue or have an improvement? Feel free to:
- Open an issue
- Submit a pull request
- Fork and modify for your needs

## 📚 Additional Resources

- [Microsoft Unattend.xml Documentation](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [Windows OOBE Documentation](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/customize-oobe)

## ✨ Credits

Original concept inspired by various OOBE bypass methods from the community.

---

**Made with ❤️ by Gh0st$ec**
