# files/dirs
alias la='ls -lha'
alias l='ls -lh'
alias where='find . -name'

# git
alias gd='git diff'
alias gs='git status'
alias gb='git branch'
alias gbd='git branch -D'
alias push_new_branch='git push -u origin $(git rev-parse --abbrev-ref HEAD)'

# keybindings
set -o vi
