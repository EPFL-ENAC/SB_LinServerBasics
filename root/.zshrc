# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/root/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  command-not-found
  git
  pip
  python
  npm
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# Bancal Samuel
setopt PRINT_EXIT_VALUE
export LESS="-XRF"


alias ll='ls -alFh'
alias s='cd ..'
alias h='history | less'
alias ssh='ssh -Y'
alias rnd='< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;'
alias gcz='git cz'
alias gcza='git cz -a'
alias glg='git lg'
alias gml='git meld'
#alias gljson='git log --pretty=format:\'{%n  "commit": "%H",%n  "parents": "%p",%n  "author_name": "%an",%n  "author_email": "%ae",%n  "date": "%ci",%n  "subject:"  "%s",%n  "body": "%b",%n  "files": [ COMMIT_HASH_%H  ]%n},\''

alias dtnow='date +%F_%T | sed "s/://g"'

export EDITOR=vim
export LC_ALL=en_US.UTF-8

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

mkcd ()
{
  mkdir -p -- "$1" &&
  cd -- "$1"
}

# https://stackoverflow.com/a/1920585/446302
prettyjson_s() {
    echo "$1" | python -m json.tool
}

prettyjson_f() {
    python -m json.tool "$1"
}

prettyjson_w() {
    curl "$1" | python -m json.tool
}

# Download file from lin-server-basics repo and save it at the right place.
getfrom-lin-server-basics() {
    https_source="https://raw.githubusercontent.com/EPFL-ENAC/SB_LinServerBasics/master/"
    filename=$1
    owner=$2
    mod=$3
    echo "Getting ${filename} from ${https_source}" 1>&2
    wget -q ${https_source}${filename} -O ${filename}
    chown ${owner} ${filename}
    chmod ${mod} ${filename}

    ls -l ${filename}
}

# Don't share history between different terminals
unsetopt share_history
