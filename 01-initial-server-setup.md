# Initial Server Setup

Essential steps for setting up a new server with proper security and user management.

## Create SSH User

```bash
sudo adduser username
sudo usermod -aG sudo username
su username
cd ~ && mkdir .ssh && cd ~/.ssh && sudo nano authorized_keys
```

## Disable Root Login

Edit SSH configuration for security:

```bash
sudo nano /etc/ssh/sshd_config

# Update these options:
```

Add these settings to the SSH config:
```
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
```

Reload SSH service:
```bash
sudo systemctl reload ssh
```

## Install ZSH & Oh My ZSH

```bash
sudo apt install zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

nano ~/.oh-my-zsh/themes/robbyrussell.zsh-theme
```

Customize the prompt:
```bash
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg_bold[cyan]%}yasinuddowla: %{$fg[cyan]%}%c%{$reset_color%}"
```

Apply changes:
```bash
source ~/.zshrc
```

## Install Essential Tools

```bash
sudo apt install zip unzip
```

## Next Steps

Continue with [Ubuntu System Management](./02-ubuntu-system.md) for system updates and configuration.
