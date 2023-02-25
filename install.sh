#!/bin/bash
# tmuxの設定
mkdir -p ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/dotfiles/.tmux.conf ~/
tmux source ~/.tmux.conf

# neovim
ln -s ~/dotfiles/nvim ~/.config/
