# Locale
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

# Editor
export EDITOR="nvim"

alias subl='"/mnt/c/Program Files/Sublime Text/subl.exe"'
alias cls="clear"
alias p="sudo pacman"
alias vim="nvim"

if type -q exa
  alias ll="exa -l -g --icons"
  alias lla="ll -a"
  alias lt="ll --tree --level=2 -a"
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Configure ssh-agent for WSL, see: https://github.com/mame/wsl2-ssh-agent
set -x SSH_AUTH_SOCK /home/user/.ssh/wsl2-ssh-agent.sock

starship init fish | source
