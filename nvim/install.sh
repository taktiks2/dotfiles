#!/bin/bash
sudo apt remove neovim -y
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install neovim

mkdir -p ~/.config/nvim
ln -s ~/dotfiles/nvim ~/.config
