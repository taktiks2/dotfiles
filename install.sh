#!/bin/bash
# tmuxの設定
mkdir -p ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s ~/dotfiles/.tmux.conf ~/
tmux source ~/.tmux.conf

# neovim
ln -s ~/dotfiles/nvim ~/.config/

# homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# brew install tree-sitter
# brew install ripgrep
# brew install --cask visual-studio-code
# brew install --cask iterm2
# brew install --cask google-chrome
# brew install --cask docker
# gem install cocoapods
