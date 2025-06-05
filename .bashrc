# shellcheck shell=bash

# Aliases and functions
# -----------------------------------------------------------------------------

# Dotfiles repo
alias dots='git --git-dir=$HOME/.dots/ --work-tree=$HOME'

# pwd wrapper that uses cygpath to print things nicely
alias pwd='__pwd'

__pwd() {
	local OPTIND OPTARG OPT
	local help=n help_fd=1
	local pwd_opts=L # Same as pwd's default
	local cyg_opts=m # Default mode is --mixed
	local cyg_long=n

	while getopts ":wmuLPlh" OPT; do
		case "$OPT" in
			w|m|u) cyg_opts=$OPT ;;
			L|P) pwd_opts=$OPT ;;
			l) cyg_long=y ;;
			h) help=y ;;
			?) help=y; help_fd=2; echo "pwd: unknown option -${OPTARG}" 1>&2 ;;
			*) help=y; help_fd=2 ;;
		esac
	done

	if [ $help = y ]; then
		cat <<-EOF 1>&$help_fd
		Usage: pwd [-LPwmu]
			Print the name of the current working directory.

		Options:
			-L        (default) Print path with symbolic links.
			-P        Print path without any symbolic links.
			-m        (default) Like --windows, but with forward slashes (C:/Users/...)
			-w        Use Windows formatting (C:\\Users\\...)
			-u        Use Unix formatting (/c/Users/...)
			-l        Use "long names" when printing Windows paths (ignored for -u).
		EOF
		test $help_fd = 1
		return $?
	fi

	# cyg_long is ignored unless using mixed/windows mode
	if [ $cyg_opts = w ] || [ $cyg_opts = m ] && [ $cyg_long = y ]; then
		cyg_opts="${cyg_opts}l"
	fi

	cygpath "-${cyg_opts}" "$(\pwd "-${pwd_opts}")"
	return $?
}

# Copies the absolute path to the current working directory to the clipboard.
cpwd() {
	local path
	path="$(pwd "$@")"
	path="${path%\n}" # Trim trailing newline
	path="${path%\r}" # Trim trailing CR if present
	echo -n "\"$path\"" | clip.exe # clip.exe is a Windows built-in (lives in System32)
	return $?
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
