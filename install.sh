#!/bin/bash
# tmuxの設定
# mkdir -p ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/dotfiles/.tmux.conf ~/
tmux source ~/.tmux.conf

# .config
ln -s ~/dotfiles/.config ~/ 

# homebrew
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
