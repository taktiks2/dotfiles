### My dotfiles

config.ymlはlazygit用、`/Users/{UserName}/Library/Application Support/lazygit`にコピーすること
deltaと連携するために必要

tmuxを開いたら`<Prefix> + I`してプラグインをインストールすると

```bash
# neovimのプラグイン用
brew install tree-sitter
brew install ripgrep
# fish
brew install fish
brew install fisher
fisher install oh-my-fish/theme-bobthefish
# alacritty
brew install --cask --no-quarantine alacritty
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
# その他
brew install --cask visual-studio-code
brew install --cask google-chrome
brew install --cask docker
brew install neovim
brew install lazygit
brew inntall git-delta
gem install cocoapods
```
