param (
    [Parameter(Mandatory=$false)]
    [string]$DistroName = "Arch",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "user"
)

Write-Host "===== WSL2 Arch Linux Setup Script =====" -ForegroundColor Cyan
Write-Host "Distribution: $DistroName" -ForegroundColor Yellow
Write-Host "Username: $Username" -ForegroundColor Yellow
Write-Host ""

# Check if the specified distro exists
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

# Function to replace placeholder values in configuration files
function Update-ConfigFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [hashtable]$Replacements
    )
    
    if (-not (Test-Path $SourcePath)) {
        Write-Warning "Source file not found: $SourcePath"
        return
    }
    
    $content = Get-Content -Path $SourcePath -Raw
    
    foreach ($key in $Replacements.Keys) {
        $content = $content -replace $key, $Replacements[$key]
    }
    
    Set-Content -Path $DestinationPath -Value $content -Force
    Write-Host "Updated configuration in: $DestinationPath" -ForegroundColor Green
}

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
$wslConfReplacements = @{
    "default=user" = "default=$Username"
}
$tempWslConf = Join-Path $env:TEMP "wsl.conf"
Update-ConfigFile -SourcePath "$RepoPath\wsl\etc\wsl.conf" -DestinationPath $tempWslConf -Replacements $wslConfReplacements
Copy-Item -Path $tempWslConf -Destination "\\wsl$\$DistroName\etc\wsl.conf" -Force
wsl -d $DistroName -u root bash -c "dos2unix /etc/wsl.conf"

Write-Host "Step 3: AUR helper and SSH bridge setup..." -ForegroundColor Green
# Clone and install paru
wsl -d $DistroName -u $Username bash -c "cd /tmp && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm"

# Install wsl2-ssh-agent
wsl -d $DistroName -u $Username bash -c "paru -S --noconfirm wsl2-ssh-agent"

# Create .ssh directory
wsl -d $DistroName -u $Username bash -c "mkdir -p ~/.ssh"

Write-Host "Step 4: Copying and updating configuration files..." -ForegroundColor Green

# Create temp directory for modified configs
$tempConfigDir = Join-Path $env:TEMP "wsl-configs"
if (Test-Path $tempConfigDir) {
    Remove-Item -Path $tempConfigDir -Recurse -Force
}
New-Item -Path $tempConfigDir -ItemType Directory -Force | Out-Null

# Process and copy WezTerm config if it exists
$weztermSourcePath = "$RepoPath\windows\.wezterm.lua"
if (Test-Path $weztermSourcePath) {
    $weztermDestPath = Join-Path $tempConfigDir ".wezterm.lua"
    $weztermReplacements = @{
        'default_domain = "WSL:Arch"' = "default_domain = `"WSL:$DistroName`""
    }
    Update-ConfigFile -SourcePath $weztermSourcePath -DestinationPath $weztermDestPath -Replacements $weztermReplacements
    Copy-Item -Path $weztermDestPath -Destination "$HOME\.wezterm.lua" -Force
}

# Process and copy all other configuration files from the repository to WSL
# First copy to temp directory with replacements
Get-ChildItem -Path "$RepoPath\wsl" -Exclude "etc" -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring("$RepoPath\wsl".Length)
    $destPath = Join-Path $tempConfigDir $relativePath
    $destDir = Split-Path -Parent $destPath
    
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }
    
    # Check and replace content if needed based on file type/path
    $content = Get-Content -Path $_.FullName -Raw -ErrorAction SilentlyContinue
    $needsReplacement = $false
    
    # Check if content contains references to default user or distro name
    if ($content -match "user" -or $content -match "Arch") {
        $needsReplacement = $true
        # Replace username in configuration files
        $content = $content -replace "\buser\b", $Username
        # Replace distro name in configuration files
        $content = $content -replace "\bArch\b", $DistroName
    }
    
    if ($needsReplacement) {
        Set-Content -Path $destPath -Value $content -Force
        Write-Host "Updated configuration in: $relativePath" -ForegroundColor Green
    } else {
        Copy-Item -Path $_.FullName -Destination $destPath -Force
    }
}

# Now copy everything to WSL
Write-Host "Copying updated configuration files to WSL..." -ForegroundColor Yellow
Get-ChildItem -Path $tempConfigDir | ForEach-Object {
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
Write-Host "Edit tmux.conf (~/.config/tmux/tmux.conf) to specify which disk will be displayed in the status bar." -ForegroundColor Green
Write-Host "The recommended way to use this WSL setup is through WezTerm. After all configurations are complete, launch WezTerm and you should see tmux running with 3 panes automatically." -ForegroundColor Green