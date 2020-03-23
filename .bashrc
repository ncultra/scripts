# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias dise="disown.sh emacs $@ "
alias disn="disown.sh emacs --no-desktop $@ "
alias hgrep="history | grep -i $1 "
alias pgrep="ps aux | grep -i $1 "
alias ffind="find ./ -name $1 "
alias sgrep="grep -rn $1 "
alias sigrep="grep -rin $1 "
alias igrep="ifconfig -a | grep -w inet "
alias rmbu="find ./ -name '*.~*~' -delete"

alias gl="git log --graph --decorate --pretty=oneline --abbrev-commit "

#export TARGET=x86_64-elf
