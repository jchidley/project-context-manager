#!/bin/bash
# Bash completion for pc (Project Context Manager)

_pc_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    local commands="switch status list save restore todo stash diff log help"
    
    # Todo subcommands
    local todo_commands="add list complete"
    
    # Stash subcommands
    local stash_commands="save pop list"
    
    # Get list of contexts
    local contexts=""
    if [[ -d "$HOME/.project-contexts" ]]; then
        contexts=$(find "$HOME/.project-contexts" -maxdepth 1 -type d -not -path "$HOME/.project-contexts" -not -name ".*" -exec basename {} \; 2>/dev/null)
    fi
    
    case "${prev}" in
        pc)
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return 0
            ;;
        switch|sw|diff)
            COMPREPLY=( $(compgen -W "${contexts}" -- ${cur}) )
            return 0
            ;;
        todo)
            COMPREPLY=( $(compgen -W "${todo_commands}" -- ${cur}) )
            return 0
            ;;
        stash)
            COMPREPLY=( $(compgen -W "${stash_commands}" -- ${cur}) )
            return 0
            ;;
        complete|done)
            # For todo complete, we could potentially list current todos
            # but that would require parsing TODO.md
            return 0
            ;;
        *)
            # Handle command aliases
            case "${COMP_WORDS[1]}" in
                sw)
                    COMPREPLY=( $(compgen -W "${contexts}" -- ${cur}) )
                    ;;
                st)
                    # status takes no arguments
                    ;;
                ls)
                    # list takes no arguments
                    ;;
                todo)
                    if [[ ${COMP_CWORD} -eq 3 ]]; then
                        case "${COMP_WORDS[2]}" in
                            list|ls|l)
                                COMPREPLY=( $(compgen -W "all todo done in-progress" -- ${cur}) )
                                ;;
                        esac
                    fi
                    ;;
            esac
            ;;
    esac
}

complete -F _pc_completions pc