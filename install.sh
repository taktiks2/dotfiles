# vimの設定ファイルを$HOMEにシンボリックリンクとして追加
# cd ~
# ln -s ~/dotfiles/.vim .
# ln -s ~/dotfiles/.vimrc .
# ln -s ~/dotfiles/.gitconfig .
# ln -s ~/dotfiles/.sqliterc .

# conda仮想環境自動推移　ymlファイルがあるところで勝手に推移する
# conda env export > environment.ymlを実行してymlファイルを作成すること
# echo "source ~/dotfiles/conda-auto-env/conda_auto_env.sh" >> ~/.bashrc

# tmuxの設定
# mkdir -p ~/.tmux/plugins/tpm
# git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# ln -s ~/dotfiles/.tmux.conf .
# tmux source ~/.tmux.conf

# Fernにアイコンを表示するためのフォントを配置
# Debianでは動作確認済 Archでは上手く行かなかった
# mkdir -p ~/.local/share/fonts
# cd .local/share/
# ln -s ~/dotfiles/fonts/ .

# Braceyのためのvim-plugを導入するためのコマンド
# curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# ddc.vimのためにdenoをインストールする
curl -fsSL https://deno.land/install.sh | sh
cd /usr/bin/
ln -s ~/.deno/bin/deno .
