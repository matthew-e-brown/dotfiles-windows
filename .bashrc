# shellcheck shell=bash

# Aliases and functions
# -----------------------------------------------------------------------------

alias ll='ls -lah'

# Dotfiles repo
alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'

# pwd wrapper that uses cygpath to print things nicely
alias pwd='__pwd'
alias cpwd='__pwd -C'

__pwd() {
	local OPTIND OPTARG OPT
	local help=no help_fd=1
	local copy=no
	local pwd_opts=L # (L option is pwd's default)
	local cyg_opts=m
	local cyg_long=no
	local path

	while getopts ":wmuLPlhC" OPT; do
		case "$OPT" in
			w|m|u) cyg_opts=$OPT ;;
			L|P) pwd_opts=$OPT ;;
			l) cyg_long=yes ;;
			C) copy=yes ;;
			h) help=yes ;;
			?) help=yes; help_fd=2; echo "pwd: unknown option -${OPTARG}" 1>&2 ;;
			*) help=yes; help_fd=2 ;;
		esac
	done

	if [ $help = yes ]; then
		cat <<-EOF 1>&$help_fd
		Usage: pwd [-LPwmu]
		    Print the name of the current working directory.

		Options:
		    -L    (default) Print path with symbolic links.
		    -P    Print path without any symbolic links.
		    -m    (default) Like --windows, but with forward slashes (C:/Users/...)
		    -w    Use Windows formatting (C:\\Users\\...)
		    -u    Use Unix formatting (/c/Users/...)
		    -l    Use "long names" when printing Windows paths (ignored for -u).
		    -C    Copy the path to clipboard.
		EOF
		# return 0 if help_fd = 1, 1 otherwise
		test $help_fd = 1; return $?
	fi

	# cyg_long is ignored unless using mixed/windows mode
	if [ $cyg_opts = w ] || [ $cyg_opts = m ] && [ $cyg_long = yes ]; then
		cyg_opts="${cyg_opts}l"
	fi

	# NB: POSIX and Bash both state that $() trims trailing newlines.
	path="$(cygpath "-${cyg_opts}" "$(\pwd "-${pwd_opts}")")" || return $?

	if [ $copy = yes ]; then
		echo -n "\"$path\"" | clip.exe # clip.exe is a Windows built-in (lives in System32)
	else
		echo "$path"
	fi
}

# Prompt
# -----------------------------------------------------------------------------

# Set these once here, so we don't have to run `tput setaf` on every command
__PROMPT_BEFORE_GIT="[\[$(tput setaf 2)\]\u@\h \[$(tput setaf 3)\]\w\[$(tput sgr0)\]]\[$(tput setaf 6)\]"
__PROMPT_AFTER_GIT=" \[$(tput setaf 13)\]$\[$(tput sgr0)\] "

# If this is an xterm, set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
	__PROMPT_BEFORE_GIT="\[\e]0;\u@\h:\W\a\]$__PROMPT_BEFORE_GIT"
	;;
*)
	;;
esac

PROMPT_DIRTRIM=2
PROMPT_COMMAND='__git_ps1 "$__PROMPT_BEFORE_GIT" "$__PROMPT_AFTER_GIT" " (%s)"'

# -- These kind of slow down the prompt on my laptop in battery mode, so I'll leave them off for now --
# GIT_PS1_SHOWUNTRACKEDFILES=yes   # enable showing untracked in dirty state
# GIT_PS1_SHOWDIRTYSTATE=yes       # * for modified, + for staged, % for untracked
# GIT_PS1_SHOWUPSTREAM=auto        # < for behind, > for ahead, = for even


# Environment variables
# -----------------------------------------------------------------------------

export LESS='-FRQ'

# Shell integrations
# -----------------------------------------------------------------------------

# Trying out Zoxide for a while :)
eval "$(zoxide init bash --cmd cd)"
