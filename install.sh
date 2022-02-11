# vimの設定ファイルを$HOMEにシンボリックリンクとして追加
cd ~
ln -s ~/dotfiles/.vim .
ln -s ~/dotfiles/.vimrc .
ln -s ~/dotfiles/.gitconfig .

# Fernにアイコンを表示するためのフォントを配置
# Debianでは動作確認済 Archでは上手く行かなかった
mkdir -p ~/.local/share/fonts
cd .local/share/
ln -s ~/dotfiles/fonts/ .

# Braceyのためのvim-plugを導入するためのコマンド
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
