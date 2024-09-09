RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
PURPLE="\[\033[0;35m\]"
CYAN="\[\033[0;36m\]"
WHITE="\[\033[0;37m\]"
BOLD="\[\033[1m\]"
RESET="\[\033[0m\]"

# Function to parse the current git branch
function parse_git_branch() {
    BRANCH=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    if [ -n "$BRANCH" ]; then
        STAT=$(parse_git_dirty)
        echo "[${BRANCH}${STAT}]"
    fi
}

# Function to parse git status for changes
function parse_git_dirty() {
    status=$(git status 2>&1)
    dirty=$(echo "$status" | grep "modified:" &>/dev/null; echo $?)
    untracked=$(echo "$status" | grep "Untracked files" &>/dev/null; echo $?)
    ahead=$(echo "$status" | grep "Your branch is ahead of" &>/dev/null; echo $?)
    newfile=$(echo "$status" | grep "new file:" &>/dev/null; echo $?)
    renamed=$(echo "$status" | grep "renamed:" &>/dev/null; echo $?)
    deleted=$(echo "$status" | grep "deleted:" &>/dev/null; echo $?)

    bits=""
    [ $renamed -eq 0 ] && bits=">${bits}"
    [ $ahead -eq 0 ] && bits="*${bits}"
    [ $newfile -eq 0 ] && bits="+${bits}"
    [ $untracked -eq 0 ] && bits="?${bits}"
    [ $deleted -eq 0 ] && bits="x${bits}"
    [ $dirty -eq 0 ] && bits="!${bits}"

    echo "$bits"
}

# Export the prompt
export PS1="${BOLD}${BLUE}[\u@\h]${RESET} ${BOLD}${GREEN}\w${RESET} ${PURPLE}\$(parse_git_branch)${RESET} \n${BOLD}${WHITE}\\$ ⮞ ${RESET}"
