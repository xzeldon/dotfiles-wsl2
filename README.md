# WSL2 Arch Linux Development Environment

My minimal setup for Arch Linux development environment optimized for WSL2, designed for daily workflow. This setup combines essential tools and configurations to create a powerful yet minimalist development workspace.

###### Mirror on my [<img src="https://git.zeldon.ru/assets/img/logo.svg" align="center" width="25" height="25"/> Git](https://git.zeldon.ru/zeldon/dotfiles-wsl2)

## Features

<img src="./.meta/screenshots/wall.png" alt="Rice Showcase" align="right" width="580px">

### Core Components

- **OS:** [Arch Linux](https://archlinux.org) on WSL2
- **Terminal:** [WezTerm](https://github.com/wezterm/wezterm)
- **Shell:** [Fish](https://github.com/fish-shell/fish-shell)
- **Multiplexer:** [Tmux](https://github.com/tmux/tmux)
- **Prompt:** [Starship](https://github.com/starship/starship)

### Additional Tools

- **Package Manager:** [paru](https://github.com/Morganamilo/paru)
- **Editor:** [Neovim](https://github.com/neovim/neovim)
- **System Info:** [fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **File Listing:** [exa](https://github.com/ogham/exa)
- **System Monitor:** [htop](https://github.com/htop-dev/htop)

## Installation

### Software Requirements

- Windows 10 version 2004 (build 19041) or higher / Windows 11
- Windows Subsystem for Linux (WSL2) component enabled _*(WSL1 is **not** supported)*_
- Virtual Machine Platform feature enabled
- Windows Terminal (optional but recommended for initial setup)
- Git for Windows

> Note: WSL2 is configured to use up to 16GB of RAM in this setup (can be adjusted in [.wslconfig](./windows/.wslconfig))

### 1. Windows Host Setup

```powershell
# Install WezTerm (or download directly: https://wezterm.org/install/windows.html)
winget install wezterm

# Clone repository
git clone https://github.com/xzeldon/dotfiles-wsl2
cd dotfiles-wsl2

# Copy Windows configs (THIS WILL OVERWRITE FILES IF THEY EXIST!)
Copy-Item -Path ".\windows\*" -Destination $HOME -Force -Recurse
```

### 2. Arch Linux WSL Setup

1. Download the [latest Arch Linux WSL image](https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/releases/permalink/latest) (you need `.wsl` file)

2. Import to WSL2:

```powershell
wsl --import NAME INSTALL_PATH IMAGE_PATH
```

Where:

- `NAME`: Your preferred WSL distribution name (e.g., "Arch")
- `INSTALL_PATH`: Where to store the WSL2 virtual disk (e.g., "D:\wsl\Arch")
- `IMAGE_PATH`: Path to the downloaded Arch Linux image (e.g., "D:\Downloads\archlinux-latest.wsl")

Example:

```powershell
wsl --import Arch D:\wsl\Arch "D:\Downloads\archlinux-latest.wsl"
```

### 3. System Configuration

#### Automatic Setup Script (Recommended)

The repository includes an automated setup script that performs all the configuration steps described in the manual setup.

```powershell
# Run the setup script with default values (Distribution: "Arch", Username: "user")
.\Install.ps1

# Or specify your own distribution name and username
.\Install.ps1 -DistroName "YourDistroName" -Username "yourusername"
```

#### ⚠️ Important Notes About Automatic Setup

- **Error Handling**: The script does not comprehensively handle all possible errors. If something goes wrong (e.g., incorrect password confirmation, package installation failures), the script will continue execution regardless.
- **Network Requirements**: A stable internet connection is required. Using VPNs or proxies is not recommended due to WSL networking limitations.
- **User Interaction**: You will need to enter passwords for the root and user accounts during script execution.

After the script completes:

1. Start your WSL distribution: `wsl -d YourDistroName`
2. Open tmux and install plugins by pressing `Ctrl+Space` followed by `Shift+I`
3. Edit [tmux.conf](./wsl/.config/tmux/tmux.conf) to specify which disk will be displayed in the status bar.
4. The recommended way to use this WSL setup is through WezTerm. After all configurations are complete, launch WezTerm and you should see tmux running with 3 panes automatically.

#### Manual Setup

> ⚠️ Note: Throughout this guide, we'll use:
>
> - Distribution name: `Arch` (if you choose a different name, update it in WezTerm config under `default_domain = "WSL:Arch"`)
> - Username: `user` (if you want a different username, update relevant configs like `./wsl/etc/wsl.conf`)

If you prefer a manual setup or need more control over the installation process, follow these steps:

1. **Initial System Setup**

   ```bash
   # Run first-time setup
   /usr/lib/wsl/first-setup.sh

   # Update system
   pacman -Syu

   # Install dependencies
   pacman -S sudo git vim neovim openssh wget binutils less debugedit fakeroot \
             fastfetch starship exa fish tmux htop python base-devel go dos2unix
   ```

2. **User Configuration**

   ```bash
   # Set root user password
   passwd

   # Configure locale
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen

   # Create user
   useradd -m user

   # Set user password
   passwd user

   # Configure sudo
   echo "user ALL=(ALL) ALL" >> /etc/sudoers.d/user
   ```

3. **WSL Configuration**

   ```bash
   # On Windows (PowerShell):
   # Assuming:
   # - You're in the repository root directory
   # - Your WSL distribution is named "Arch" (from section 2.2)
   # Copy WSL configuration file from host to guest
   cp .\wsl\etc\wsl.conf \\wsl.localhost\Arch\etc\wsl.conf

   # In WSL (Arch Linux):
   # Convert line endings from Windows (CRLF) to Unix (LF) format
   dos2unix /etc/wsl.conf

   # On Windows (PowerShell):
   # Restart WSL to apply changes
   wsl --shutdown
   ```

4. **AUR Helper and SSH Bridge Setup**

   ```bash
   # Install AUR helper
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   makepkg -si

   # Install agent for ssh bridge
   # (see: https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL#Bridge_the_ssh-agent_service_from_Windows)
   paru -S wsl2-ssh-agent

   # Create .ssh directory (this does not exist by default, but is required for wsl2-ssh-agent)
   mkdir ~/.ssh
   ```

5. **Copy Configuration Files**

   ```powershell
   # From Windows PowerShell:
   # Assuming you're in the repo directory, `Arch` is your WSL distribution name and username is `user`
   Copy-Item -Path .\wsl\* -Destination \\wsl.localhost\Arch\home\user -Recurse -Force -Exclude "etc"
   ```

6. **Tmux Setup**

   ```bash
   # Install Tmux Plugin Manager
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

   # Start tmux and install plugins
   tmux # Then press Ctrl+Space, Shift+I
   ```

## Configuration

### File Structure

```
├── windows/                # Windows-side configs
│   ├── .wezterm.lua       # WezTerm configuration
│   └── .wslconfig         # WSL global settings
└── wsl/                   # Linux-side configs
    ├── .config/
    │   ├── fish/         # Fish shell configuration
    │   ├── tmux/         # Tmux configuration
    │   └── starship.toml # Prompt configuration
    └── etc/
        └── wsl.conf      # WSL distribution settings
```

### Key Bindings

#### Tmux

| Binding        | Action                       |
| -------------- | ---------------------------- |
| `Ctrl + Space` | Tmux prefix                  |
| `Prefix + I`   | Install Tmux plugins         |
| `Prefix + c`   | Create new pane              |
| `Prefix + %`   | Create new pane vertically   |
| `Prefix + "`   | Create new pane horizontally |
| `Prefix + x`   | Kill current pane            |

#### WezTerm

| Binding                            | Action                  |
| ---------------------------------- | ----------------------- |
| `Ctrl + Shift + Q`                 | Close WezTerm window    |
| `Ctrl + Shift + M`                 | Minimize WezTerm window |
| `Ctrl + Shift + Left Mouse Button` | Drag to move mode       |

> Tip: use `fish_add_path /some/path/bin` to add directories to $PATH. See: https://fishshell.com/docs/current/cmds/fish_add_path.html

## License

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
