# Alias for dotfiles git repo
alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'

function cpwd() {
	pwd | tr -d '\r\n' | clip
}

# 'import' scripts
alias flac-exchange='python ~/Scripts/flac-exchange.py'

# https://github.com/docker-archive/toolbox/issues/673
function docker() {
	(export MSYS_NO_PATHCONV=1; "docker.exe" "$@")
}

function docker-compose() {
	(export MSYS_NO_PATHCONV=1; "docker-compose.exe" "$@")
}


# set these once here so we don't have to run `tput setaf` on every command
__PROMPT_BEFORE_GIT="[\[$(tput setaf 2)\]\u@\h \[$(tput setaf 3)\]\w\[$(tput sgr0)\]]\[$(tput setaf 6)\]"
__PROMPT_AFTER_GIT=" \[$(tput setaf 13)\]$\[$(tput sgr0)\] "

PROMPT_DIRTRIM=2
PROMPT_COMMAND='__git_ps1 "$__PROMPT_BEFORE_GIT" "$__PROMPT_AFTER_GIT" " (%s)"'


# -- These kind of slow down the prompt on my laptop in battery mode, so I'll leave them off for now --
# GIT_PS1_SHOWUNTRACKEDFILES=yes		# enable showing untracked in dirty state
# GIT_PS1_SHOWDIRTYSTATE=yes			# * for modified, + for staged, % for untracked
# GIT_PS1_SHOWUPSTREAM=auto			# < for behind, > for ahead, = for even
