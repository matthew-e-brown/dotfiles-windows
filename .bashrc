# Alias for dotfiles git repo
alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'

function cpwd() {
        pwd | tr -d '\r\n' | clip
}

# Make shit legible
PROMPT_DIRTRIM=2

# 'import' scripts
alias flac-exchange='python ~/Scripts/flac-exchange.py'


# https://github.com/docker-archive/toolbox/issues/673
function docker() {
	(export MSYS_NO_PATHCONV=1; "docker.exe" "$@")
}

function docker-compose() {
	(export MSYS_NO_PATHCONV=1; "docker-compose.exe" "$@")
}

