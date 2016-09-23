# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
# SB
alias s='cd ..'
alias h='history | less'
alias ssh='ssh -Y'

export EDITOR=vim
export LC_ALL=en_US.UTF-8

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# SB
# Saves a copy of a given file
# ex :
# saveBack filename
# will create filename.01 (or 02 or ... if already exist)
function saveBack {
    BaseName="$1"
    # look if file exists (if not : return)
    if [[ ! -e $BaseName ]]; then
        return;
    fi
    # find the next name $BaseName.01 etc that does not exist yet
    i=1
    Suffix=0$i
    Lastsuffix="00"
    while [[ -e "$BaseName".$Suffix ]] ; do
        Lastsuffix=$Suffix
        i=$(( $i + 1 ))
        if [[ $i -lt 10 ]]; then
            Suffix=0$i
        else
            Suffix=$i
        fi
    done
    # save a backup if there is no existing backup or if
    # the last one is the same as the current one
    if [[ "$Lastsuffix" = "00" ]] ; then
        cp -p "$BaseName" "$BaseName".$Suffix
    elif cmp -s "$BaseName" "$BaseName".$Lastsuffix ; then
        :
    else
        cp -p "$BaseName" "$BaseName".$Suffix
    fi
}

# Stores a password in env variable ${PASS}
pww () 
{
    echo -n "Password in \$PASS: ";
    stty -echo;
      read PASS;
    stty echo;
    echo;
    export PASS
}

# Kill -TERM (which is nice killing) processes matching string
# ex :
# kill_procs firefox
function kill_procs {
    proc_name=$1
    if [[ "$proc_name" = "" ]]; then
        echo "usage : kill_procs proc_name";
        return;
    fi
    procs_pid=$(ps aux | grep $proc_name | grep -v grep | awk '{ print $2 }')
    nb_procs=$(echo $procs_pid | wc -w)
    if [[ ${nb_procs} -ne "0" ]]; then
        echo "killing ${nb_procs} procs."
        kill -TERM ${procs_pid}
    else
        echo "Nothing to do.";
    fi
}

# Run a command and check it's return code
# ex :
# r 0 sudo apt-get update
# r 1 cat /doesnt_exist_file
function r {
    status_expected=$1
    echo "___ RUN ___" 1>&2
    echo "${@:2}" 1>&2
    "${@:2}"
    status=$?
    if [ $status -ne $status_expected ]; then
        echo "___ ERROR, it returned $status ___" 1>&2
        echo 1 >> ${script_log}.errors_count
    else
        echo "___ OK, it returned $status ___" 1>&2
    fi
    echo 1>&2
    return $status
}

# Display a simple title level 1
function title1 {
    string=$*
    length=$(echo ${#string} + 10 | bc)
    echo "---> $@ <---"
    printf %${length}s |tr " " "="
    echo -e "\n"
}

# Display a simple title level 2
function title2 {
    string=$*
    length=$(echo ${#string} + 10 | bc)
    echo "---> $@ <---"
    printf %${length}s |tr " " "-"
    echo -e "\n"
}

# Display a simple title level 3
function title3 {
    echo "### ---> $@ <---"
    echo
}
