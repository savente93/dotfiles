# Zsh config
export ZSH=$HOME/.zsh

# history config
export HISTFILE=$ZSH/.zsh_history
HIST_STAMPS="yyyy/mm/dd"
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# load plugins, well... okay plugin
source ~/.zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

## enable zsh native features
# enable git tab completion
autoload -Uz compinit && compinit

# enable prefix history search on arrow up
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search

# case insensitive tab completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# Env virables
export EDITOR=hx
export GPG_TTY=$(tty)
export VIRTUAL_ENV_DISABLE_PROMPT=1
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..|ta)"

# Functions
# open file for new blog idea
function new_post() {
	# turn title into a slug
	INPUT=$1
	INPUT_SAFE="${INPUT// /-}"
	INPUT_SAFE="${INPUT_SAFE//[^a-zA-Z0-9\-]/}"
	INPUT_SAFE=$(echo $INPUT_SAFE | tr A-Z a-z | sd '\--' '-')

	DIR="$(realpath $(fd unpublished | head -n 1))"
	FILE_PATH=$DIR/$INPUT_SAFE/index.md

	# are we at the correct root?
	if [[ -z "$DIR" ]]; then
		echo "could not find unpublished content folder. Are you in the correct root?"
		return 1
	fi

	# does the file exist?
	if [[ -f $FILE_PATH ]]; then
		echo "File already exists. exiting..."
		return 1
	fi

	mkdir -p $DIR/$INPUT_SAFE

	# start with front matter
	echo "+++
title=\"${INPUT}\"
date=$(date --iso)
draft=true
[taxonomies]
tags=[\"wip\"]
+++
    " >>$FILE_PATH

	# open up to write down ideas
	hx $FILE_PATH

	# commit new idea
	git add $DIR/$INPUT_SAFE
	git commit -m "add post idea: $INPUT"

}

# create new branch from main instead of current one
function gcb() {
	if [[ -z $2 ]]; then
		git checkout -b $1 main
	else
		# in case user provided more arguments than just branch name
		git checkout -b $1 main $2
	fi

}

# set upstream of current branch to branch of the same name in origin
function gbu() {
	git branch -u origin/$(git rev-parse --abbrev-ref HEAD)
}

#
function gci() {
	if [[ -z $1 ]]; then
		# if no extra argument open up last commit message in editor
		git commit -e -F $(git rev-parse --git-dir)/COMMIT_EDITMSG
	else
		# else pass all other commands to git to function as usual
		git commit "$@"
	fi

}

# Aliasses, typing is for chumps
alias up='topgrade -y --skip-notify --no-retry -c'
alias hx='helix'

## files
alias ls='eza'
alias la='eza -lah'
alias lt='eza --tree -L 2'
alias ltt='eza --tree -L 3'

## git
alias gad='git add -p'
alias gst='git status'
alias gdm='git diff main'
alias gmm='git merge main'
alias gco='git checkout'
alias glo="git log --graph --decorate --pretty=oneline --abbrev-commit"
alias gbr="git branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:blue)(%(committerdate:short)) [%(authorname)]'"
alias gbd="git branch -D"
alias gfp="git fetch --all --prune"

## apt
alias acs='apt-cache search'
alias sai='sudo apt install'

## work
alias ipy="ipython"
alias pt="pixi run -e full-py39 test-lf"
alias ptt="pixi run -e full-py39 test"
alias pe="pixi run -e full-py39 hx ."
alias pi="pixi run -e full-py39 ipython"


# tool enviroment inits
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(pixi completion --shell zsh)"

source ~/.wezterm.sh


if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval "$(ssh-agent -s)" > /dev/null
fi

ssh-add -l > /dev/null                        # check for keys
if [ $? -ne 0 ] ; then
	ssh-add 2>&1 > /dev/null
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/sam/.mamba/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
	eval "$__conda_setup"
else
	if [ -f "/home/sam/.mamba/etc/profile.d/conda.sh" ]; then
		. "/home/sam/.mamba/etc/profile.d/conda.sh"
	else
		export PATH="/home/sam/.mamba/bin:$PATH"
	fi
fi
unset __conda_setup

if [ -f "/home/sam/.mamba/etc/profile.d/mamba.sh" ]; then
	. "/home/sam/.mamba/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<
