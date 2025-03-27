param (
    [Parameter(Mandatory=$true)]
    [string]$DistroName = "Arch",
    
    [Parameter(Mandatory=$true)]
    [string]$Username = "user"
)

Write-Host "===== WSL2 Arch Linux Setup Script =====" -ForegroundColor Cyan
Write-Host "Distribution: $DistroName" -ForegroundColor Yellow
Write-Host "Username: $Username" -ForegroundColor Yellow
Write-Host ""

# Check if the specified distro exists - improved detection
$wslDistros = (wsl --list) -replace "`0", "" | ForEach-Object { $_.Trim() }
$distroExists = $false
foreach ($line in $wslDistros) {
    if ($line -match $DistroName) {
        $distroExists = $true
        break
    }
}

if (-not $distroExists) {
    Write-Error "Distribution '$DistroName' not found. Please check the name or import it first."
    exit 1
}

# Path to current repository
$RepoPath = Get-Location

Write-Host "Step 1: Initial Setup..." -ForegroundColor Green
wsl -d $DistroName -u root bash -c "/usr/lib/wsl/first-setup.sh"
wsl -d $DistroName -u root bash -c "pacman -Syu --noconfirm"
wsl -d $DistroName -u root bash -c "pacman -S --noconfirm sudo git vim neovim openssh wget binutils less debugedit fakeroot fastfetch starship exa fish tmux htop python base-devel go dos2unix"

Write-Host "Step 2: User Configuration..." -ForegroundColor Green

# Set root password
Write-Host "Setting root password..." -ForegroundColor Yellow
wsl -d $DistroName -u root bash -c "passwd"

# Configure locale
Write-Host "Configuring locale..." -ForegroundColor Yellow
wsl -d $DistroName -u root bash -c "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen"

# Create user if doesn't exist
Write-Host "Setting up user $Username..." -ForegroundColor Yellow
wsl -d $DistroName -u root bash -c "id -u $Username >/dev/null 2>&1 || useradd -m $Username"

# Set user password
Write-Host "Setting password for $Username..." -ForegroundColor Yellow
wsl -d $DistroName -u root bash -c "passwd $Username"

# Configure sudo
Write-Host "Configuring sudo access..." -ForegroundColor Yellow
wsl -d $DistroName -u root bash -c "echo '$Username ALL=(ALL) ALL' > /etc/sudoers.d/$Username"

# Configure WSL default user
Write-Host "Configuring WSL default user..." -ForegroundColor Yellow
Copy-Item -Path "$RepoPath\wsl\etc\wsl.conf" -Destination "\\wsl$\$DistroName\etc\wsl.conf" -Force
wsl -d $DistroName -u root bash -c "dos2unix /etc/wsl.conf"

Write-Host "Step 3: AUR helper and SSH bridge setup..." -ForegroundColor Green
# Clone and install paru
wsl -d $DistroName -u $Username bash -c "cd /tmp && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm"

# Install wsl2-ssh-agent
wsl -d $DistroName -u $Username bash -c "paru -S --noconfirm wsl2-ssh-agent"

# Create .ssh directory
wsl -d $DistroName -u $Username bash -c "mkdir -p ~/.ssh"

Write-Host "Step 4: Copying configuration files..." -ForegroundColor Green
# Copy all configuration files from the repository to WSL
Get-ChildItem -Path "$RepoPath\wsl" -Exclude "etc" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "\\wsl$\$DistroName\home\$Username" -Recurse -Force
}

# Convert line endings for all copied files
Write-Host "Converting line endings for configuration files..." -ForegroundColor Yellow
wsl -d $DistroName -u $Username bash -c "find ~/ -type f -not -path '*/\.git/*' -exec dos2unix {} \; 2>/dev/null || true"

# Fix permissions for configuration files
Write-Host "Setting correct permissions for configuration files..." -ForegroundColor Yellow
$chownCmd = "chown -R " + $Username + ":" + $Username + " /home/" + $Username + "/"
wsl -d $DistroName -u root bash -c $chownCmd
wsl -d $DistroName -u root bash -c "chmod -R 755 /home/$Username/.config/"
wsl -d $DistroName -u root bash -c "chmod 700 /home/$Username/.ssh/ 2>/dev/null || true"

Write-Host "Step 5: Tmux configuration..." -ForegroundColor Green
# Install Tmux Plugin Manager
wsl -d $DistroName -u $Username bash -c "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"

Write-Host "Restarting WSL to apply changes..." -ForegroundColor Yellow
wsl --shutdown

Write-Host "===== Setup Complete! =====" -ForegroundColor Cyan
Write-Host "You can now launch your WSL instance with: wsl -d $DistroName" -ForegroundColor Green
Write-Host "Remember to install Tmux plugins by pressing Ctrl+Space, Shift+I when in Tmux" -ForegroundColor Green