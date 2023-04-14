set -g theme_color_scheme dracula
set -g theme_display_git yes
set -g theme_display_git_default_branch yes
set -g theme_display_node yes
set -g theme_display_date no
set -g theme_powerline_fonts yes
set -g theme_nerd_fonts yes
set -g theme_newline_cursor yes
set -g theme_newline_prompt '> '

set -x LANG en_US.UTF-8
set PATH /opt/homebrew/bin $PATH
set PATH $HOME/Library/Android/sdk/cmdline-tools $PATH
set PATH $HOME/Library/Android/sdk/emulator $PATH
set PATH $HOME/Library/Android/sdk/tools $PATH
set PATH $HOME/Library/Android/sdk/tools/bin $PATH
set PATH $HOME/Library/Android/sdk/platform-tools $PATH
set PATH $HOME/bin $PATH
set PATH $HOME/.nodebrew/current/bin $PATH
set -x ANDROID_SDK_ROOT $HOME/Library/Android/sdk
set -x JAVA_HOME /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
set -gx PATH '/Users/t-osoegawa/.rbenv/shims' $PATH
set -gx RBENV_SHELL fish
command rbenv rehash 2>/dev/null
function rbenv
  set command $argv[1]
  set -e argv[1]

  switch "$command"
  case rehash shell
    rbenv "sh-$command" $argv|source
  case '*'
    command rbenv "$command" $argv
  end
end

alias vim="nvim"

source /Users/taktiks2/.docker/init-fish.sh || true # Added by Docker Desktop
