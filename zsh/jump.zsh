# ---------------------------------------------------------------------------
# j / jh - fuzzy jump to a directory, or find a file inside one
# ---------------------------------------------------------------------------
#   j  [query]   Ctrl-G   start from the project list: every top-level dir
#                         under $JUMP_ROOTS plus every git worktree, each
#                         labeled with its branch -- the only way to tell
#                         `agent-a0f1e707...` from `agent-a1869b0c...`.
#   jh [query]   Alt-G    start from the current directory instead.
#
# In the picker:
#   Tab      descend into the highlighted directory
#   Ctrl-F   switch to files (of the highlighted dir, or the current file's dir)
#   Ctrl-D   switch back to directories
#   Ctrl-U   back out to the project list
#   Ctrl-Y   copy the path, picker stays open
#   Ctrl-O   xdg-open
#   Alt-O    choose what to open it with
#   Enter    cd (directory) / open in $EDITOR (file)
#
# Directories you visit are ranked higher next time (frecency: visit count
# decayed by age), recorded by jump-track from a chpwd hook.
#
# Candidates come from ~/.local/scripts/jump-list, because fzf's `reload`
# spawns a plain shell that cannot see zsh functions.

export JUMP_ROOTS="$HOME/Work $HOME/personal $HOME/Projects"

# _jump_pick <prompt> <query> <command...>
_jump_pick() {
    local prompt=$1 query=$2; shift 2
    local out key line target

    out=$("$@" |
        fzf +m --height 60% --reverse \
            --delimiter='\t' --with-nth=1 \
            --prompt="$prompt" --query="$query" \
            --expect=ctrl-o,alt-o \
            --header='tab: into dir   ^f: files   ^d: dirs   ^u: projects   ^y: copy   ^o: open' \
            --bind='tab:reload(jump-list sub {2})+transform-prompt(jump-list label dir {2})+clear-query+first' \
            --bind='ctrl-f:reload(jump-list files {2})+transform-prompt(jump-list label file {2})+clear-query+first' \
            --bind='ctrl-d:reload(jump-list sub "$(jump-list root {2})")+transform-prompt(jump-list label proj {2})+clear-query+first' \
            --bind='ctrl-u:reload(jump-list roots)+change-prompt(jump> )+clear-query+first' \
            --bind='ctrl-y:execute-silent(jump-copy {2})+transform-header(printf "copied  %s" {2})' \
            --preview='jump-preview {2}' \
            --preview-window='right:45%:border-left')

    [[ -n "$out" ]] || return 0
    key=${out%%$'\n'*}                  # --expect prints the key first, may be empty
    line=${out#*$'\n'}
    target=${line##*$'\t'}
    [[ -e "$target" ]] || { print -u2 "jump: no such path: $target"; return 1 }

    case "$key" in
        ctrl-o) setsid xdg-open -- "$target" >/dev/null 2>&1 & ;;
        alt-o)  jump-open "$target" ;;
        *)      if [[ -d "$target" ]]; then cd "$target"
                else ${EDITOR:-nvim} "$target"
                fi ;;
    esac
}

# Jump starting from the project / worktree list.
j() {
    _jump_pick 'jump> ' "${1:-}" jump-list roots
}

# Jump starting from the current directory.
jh() {
    _jump_pick "${PWD:t}/ " "${1:-}" jump-list sub "$PWD"
}

# Remember where you go, so the picker floats your usual places to the top.
# Hooked to chpwd rather than to `j` itself, so a plain `cd` counts too.
autoload -Uz add-zsh-hook
_jump_track() { jump-track "$PWD" }
add-zsh-hook chpwd _jump_track

_jump_widget()      { j  < /dev/tty; zle reset-prompt }
_jump_here_widget() { jh < /dev/tty; zle reset-prompt }
zle -N _jump_widget
zle -N _jump_here_widget
bindkey '^g'  _jump_widget        # Ctrl-G: from the project list
bindkey '^[g' _jump_here_widget   # Alt-G:  from the current directory
