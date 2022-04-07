# Alias for dotfiles git repo
alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'

function cpwd() {
        pwd | tr -d '\r\n' | clip
}

# Make shit legible
PROMPT_DIRTRIM=2

# 'import' scripts
alias flac-exchange='python ~/Scripts/flac-exchange.py'
