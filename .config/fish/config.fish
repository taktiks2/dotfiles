set -g theme_color_scheme dracula
set -g theme_display_git yes
set -g theme_display_git_default_branch yes
set -g theme_display_node yes
set -g theme_display_date no
set -g theme_powerline_fonts yes
set -g theme_nerd_fonts yes
set -g theme_newline_cursor yes
set -g theme_newline_prompt '> '

set -x VIRTUAL_ENV_DISABLE_PROMPT 1
set -x LANG en_US.UTF-8
set PATH /opt/homebrew/bin $PATH
set PATH $HOME/Library/Android/sdk/cmdline-tools $PATH
set PATH $HOME/Library/Android/sdk/emulator $PATH
set PATH $HOME/Library/Android/sdk/tools $PATH
set PATH $HOME/Library/Android/sdk/tools/bin $PATH
set PATH $HOME/Library/Android/sdk/platform-tools $PATH
set PATH $HOME/bin $PATH
set PATH $HOME/.nodebrew/current/bin $PATH
set PATH /opt/homebrew/opt/mysql@8.0/bin $PATH
set DYLD_LIBRARY_PATH /opt/homebrew/opt/mysql@8.0/lib $DYLD_LIBRARY_PATH
set -x ANDROID_SDK_ROOT $HOME/Library/Android/sdk
set -x JAVA_HOME /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# atac
set -x ATAC_MAIN_DIR $HOME/.config/atac
set -x ATAC_THEME $HOME/.config/atac/settings/theme.toml
set -x ATAC_KEY_BINDINGS $HOME/.config/atac/settings/key.toml

# git delta & gh dash
set -x GH_PAGER delta

# nodebrew
set -x PATH $HOME/.nodebrew/current/bin $PATH

# rust tools
set PATH $HOME/.cargo/bin $PATH

# rbenv
set -gx PATH '/Users/taktiks2/.rbenv/shims' $PATH
set -gx RBENV_SHELL fish
command rbenv rehash 2>/dev/null
function rbenv
    set command $argv[1]
    set -e argv[1]

    switch "$command"
        case rehash shell
            rbenv "sh-$command" $argv | source
        case '*'
            command rbenv "$command" $argv
    end
end

alias agents="agents.fish"
alias vim="nvim"
alias vi="nvim"
alias v="nvim"
alias gd="gh dash"
alias lg="lazygit"
alias ls="lsd"
alias la="lsd -a"
alias ll="lsd -al"
alias sls="sbcl --load ~/.local/share/nvim/lazy/nvlime/lisp/start-nvlime.lisp"

# ~/.config/fish/config.fish に追加するシンプルな2文字 tmux コマンド

# ===========================================
# 基本設定
# ===========================================

# セッション名（必要に応じて変更）
set -g SESSION multagent

# ===========================================
# メインコマンド（2文字）
# ===========================================

# ta "command" - 全ペイン（Total/All）
function ta
    if test (count $argv) -eq 0
        # 引数なし = ENTERキーのみ送信
        for i in (seq 1 16)
            tmux send-keys -t "$SESSION:1.$i" C-m
        end
        echo "✅ 全ペインにENTERを送信しました"
    else
        # 引数あり = コマンド + ENTER送信
        for i in (seq 1 16)
            tmux send-keys -t "$SESSION:1.$i" "$argv" C-m
        end
        echo "✅ 全ペインで実行: $argv"
    end
end

# tb "command" - ボスペイン（Boss）
function tb
    if test (count $argv) -eq 0
        # 引数なし = ENTERキーのみ送信
        for i in 1 5 9 13
            tmux send-keys -t "$SESSION:1.$i" C-m
        end
        echo "✅ ボスペインにENTERを送信しました"
    else
        # 引数あり = コマンド + ENTER送信
        for i in 1 5 9 13
            tmux send-keys -t "$SESSION:1.$i" "$argv" C-m
        end
        echo "✅ ボスペインで実行: $argv"
    end
end

# tw "command" - ワーカーペイン（Worker）
function tw
    if test (count $argv) -eq 0
        # 引数なし = ENTERキーのみ送信
        for i in 2 3 4 6 7 8 10 11 12 14 15 16
            tmux send-keys -t "$SESSION:1.$i" C-m
        end
        echo "✅ ワーカーペインにENTERを送信しました"
    else
        # 引数あり = コマンド + ENTER送信
        for i in 2 3 4 6 7 8 10 11 12 14 15 16
            tmux send-keys -t "$SESSION:1.$i" "$argv" C-m
        end
        echo "✅ ワーカーペインで実行: $argv"
    end
end

# ===========================================
# 便利な追加コマンド
# ===========================================

# tc - 全ペインでクリア（Clear）
function tc
    ta clear
end

# ts - セッション状況確認（Status）
function ts
    echo "=== TMux セッション状況 ==="
    echo "セッション名: $SESSION"
    if tmux has-session -t "$SESSION" 2>/dev/null
        echo "✅ セッション '$SESSION' は実行中"
        set pane_count (tmux list-panes -t "$SESSION" 2>/dev/null | wc -l)
        echo "📊 ペイン数: $pane_count"
    else
        echo "❌ セッション '$SESSION' が見つかりません"
    end
end

# end - セッション終了
function end
    echo "🛑 セッション '$SESSION' を終了中..."
    if tmux has-session -t "$SESSION" 2>/dev/null
        tmux kill-session -t "$SESSION"
    else
        echo "❌ セッションが見つかりません"
    end
    if not tmux has-session -t "$SESSION" 2>/dev/null
        echo "✅ セッション '$SESSION' を終了しました"
    end
end

# ===========================================
# 使用例とヘルプ
# ===========================================

# ヘルプ表示
function th
    echo "=== シンプル tmux コマンド ==="
    echo ""
    echo "基本コマンド："
    echo "  ta \"コマンド\"  - 全ペイン（16個全部）で実行"
    echo "  tb \"コマンド\"  - ボスペイン（4個）で実行"
    echo "  tw \"コマンド\"  - ワーカーペイン（12個）で実行"
    echo ""
    echo "ENTERキーのみ送信："
    echo "  ta              - 全ペインでENTER"
    echo "  tb              - ボスペインでENTER"
    echo "  tw              - ワーカーペインでENTER"
    echo ""
    echo "便利コマンド："
    echo "  tc              - 全ペインでclear"
    echo "  ts              - セッション状況確認"
    echo "  end             - セッション終了"
    echo ""
    echo "コマンド例："
    echo "  ta \"npm start\"     # 全ペインでnpm start"
    echo "  tb \"git status\"    # ボスペインでgit status"
    echo "  tw \"clear\"         # ワーカーペインでclear"
    echo "  ta \"cd /project\"   # 全ペインでディレクトリ移動"
    echo ""
    echo "ENTER使用例："
    echo "  ta \"sudo apt update\"  # コマンド入力"
    echo "  ta                     # ENTERで実行"
    echo ""
    echo "  tw \"npm init\"        # 質問が表示される"
    echo "  tw                     # デフォルト値でENTER"
    echo ""
    echo "セッション: $SESSION"
    echo "💡 ペイン構成: Boss(1,5,9,13) + Worker(2-4,6-8,10-12,14-16)"
end

# ===========================================
# よく使うパターンの例
# ===========================================

# 開発環境セットアップ例
function dev-start
    echo "🚀 開発環境を起動中..."
    ta "cd /project"
    sleep 1
    tb "npm run dev"
    tw "npm run worker"
    echo "✅ 開発環境起動完了！"
end

# 全停止
function dev-stop
    echo "🛑 開発環境を停止中..."
    ta "^C" # Ctrl+C
    sleep 1
    tc # clear
    echo "✅ 停止完了"
end

# 初回メッセージ
echo "✅ 改良版シンプル tmux コマンドが読み込まれました！"
echo "💡 使い方: th でヘルプ表示"
echo "🚀 便利機能: tc(クリア) ts(状況確認) end(セッション終了) dev-start(開発開始)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/taktiks2/google-cloud-sdk/path.fish.inc' ]
    . '/Users/taktiks2/google-cloud-sdk/path.fish.inc'
end
