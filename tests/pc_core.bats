#!/usr/bin/env bats
# pc_core.bats - Tests for core pc functionality

load test_helper

# Mock pc script that sources common.sh
setup() {
    setup_test_env
    
    # Create a minimal pc script for testing
    cat > "${TEST_DIR}/pc_test" << 'EOF'
#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

cmd_init() {
    local context="${1:-}"
    if [[ -z "$context" ]]; then
        error "Context name required"
        return 1
    fi
    
    validate_context_name "$context" || return 1
    
    local context_dir
    context_dir=$(get_context_dir "$context") || return 1
    
    if [[ -d "$context_dir" ]]; then
        error "Context already exists: $context"
        return 1
    fi
    
    ensure_dir "$context_dir" || return 1
    set_current_context "$context" || return 1
    
    # Create default files
    cat > "${context_dir}/HANDOFF.md" << HANDOFF
# Project: $context
Updated: $(get_timestamp)

## Current State
Status: New project initialized

## Essential Context
- Project initialized with pc

## Next Step
Define project goals and initial tasks

## If Blocked
Review project requirements
HANDOFF

    cat > "${context_dir}/TODO.md" << TODO
# TODO - $context

Last updated: $(get_timestamp)

## To Do

- [ ] Define project goals
- [ ] Set up development environment
- [ ] Create initial project structure
TODO

    touch "${context_dir}/PROJECT_WISDOM.md"
    
    success "Initialized context: $context"
    add_to_history "init" "$context"
}

cmd_switch() {
    local context="${1:-}"
    if [[ -z "$context" ]]; then
        error "Context name required"
        return 1
    fi
    
    validate_context_name "$context" || return 1
    
    local context_dir="${PC_DIR}/${context}"
    if [[ ! -d "$context_dir" ]]; then
        error "Context does not exist: $context"
        return 1
    fi
    
    # Check git status
    check_git_status || return 1
    
    set_current_context "$context" || return 1
    success "Switched to context: $context"
    add_to_history "switch" "$context"
}

cmd_status() {
    local current
    current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        info "No active context"
        return 0
    fi
    
    echo -e "${BOLD}Active context:${NC} ${GREEN}$current${NC}"
    
    local context_dir
    context_dir=$(get_context_dir) || return 1
    
    if [[ -f "${context_dir}/HANDOFF.md" ]]; then
        echo -e "\n${BOLD}Current state:${NC}"
        grep -A2 "^## Current State" "${context_dir}/HANDOFF.md" | tail -n +2 | sed 's/^/  /'
    fi
    
    if [[ -f "${context_dir}/TODO.md" ]]; then
        echo -e "\n${BOLD}Active todos:${NC}"
        grep "^- \[ \]" "${context_dir}/TODO.md" | head -5 | sed 's/^/  /'
        local remaining=$(grep -c "^- \[ \]" "${context_dir}/TODO.md" || echo 0)
        if [[ $remaining -gt 5 ]]; then
            echo "  ... and $((remaining - 5)) more"
        fi
    fi
}

cmd_list() {
    if [[ ! -d "$PC_DIR" ]]; then
        info "No contexts found"
        return 0
    fi
    
    local current
    current=$(get_current_context)
    
    echo -e "${BOLD}Available contexts:${NC}"
    for dir in "$PC_DIR"/*; do
        if [[ -d "$dir" ]] && [[ "$(basename "$dir")" != ".*" ]]; then
            local name=$(basename "$dir")
            if [[ "$name" == "$current" ]]; then
                echo -e "  ${GREEN}* $name${NC} (active)"
            else
                echo "    $name"
            fi
        fi
    done
}

# Main command dispatcher
main() {
    local cmd="${1:-status}"
    shift || true
    
    case "$cmd" in
        init|new)
            cmd_init "$@"
            ;;
        switch|sw)
            cmd_switch "$@"
            ;;
        status|st)
            cmd_status "$@"
            ;;
        list|ls)
            cmd_list "$@"
            ;;
        *)
            error "Unknown command: $cmd"
            return 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_error_handling
    init_pc_structure
    main "$@"
fi
EOF
    
    chmod +x "${TEST_DIR}/pc_test"
    
    # Override lib path for test
    export PC_TEST="${TEST_DIR}/pc_test"
}

teardown() {
    teardown_test_env
}

# Helper to run pc command
run_pc() {
    run "$PC_TEST" "$@"
}

@test "pc: init creates new context" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    assert_output_contains "Initialized context: $TEST_CONTEXT"
    
    # Check directory structure
    assert_dir_exists "${PC_DIR}/${TEST_CONTEXT}"
    assert_file_exists "${PC_DIR}/${TEST_CONTEXT}/HANDOFF.md"
    assert_file_exists "${PC_DIR}/${TEST_CONTEXT}/TODO.md"
    assert_file_exists "${PC_DIR}/${TEST_CONTEXT}/PROJECT_WISDOM.md"
    
    # Check active context
    run get_current_context
    assert_success
    [[ "$output" == "$TEST_CONTEXT" ]]
}

@test "pc: init fails with invalid context name" {
    run_pc init "invalid name with spaces"
    assert_failure
    assert_output_contains "letters, numbers"
    
    run_pc init ""
    assert_failure
    assert_output_contains "required"
}

@test "pc: init fails if context already exists" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    run_pc init "$TEST_CONTEXT"
    assert_failure
    assert_output_contains "already exists"
}

@test "pc: switch changes active context" {
    # Create two contexts
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    run_pc init "$TEST_CONTEXT2"
    assert_success
    
    # Switch back to first
    run_pc switch "$TEST_CONTEXT"
    assert_success
    assert_output_contains "Switched to context: $TEST_CONTEXT"
    
    # Verify active context
    run get_current_context
    assert_success
    [[ "$output" == "$TEST_CONTEXT" ]]
}

@test "pc: switch fails for non-existent context" {
    run_pc switch "nonexistent"
    assert_failure
    assert_output_contains "does not exist"
}

@test "pc: status shows active context" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    run_pc status
    assert_success
    assert_output_contains "Active context: $TEST_CONTEXT"
    assert_output_contains "Current state:"
    assert_output_contains "Active todos:"
}

@test "pc: status shows no active context" {
    run_pc status
    assert_success
    assert_output_contains "No active context"
}

@test "pc: list shows all contexts" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    run_pc init "$TEST_CONTEXT2"
    assert_success
    
    run_pc list
    assert_success
    assert_output_contains "$TEST_CONTEXT"
    assert_output_contains "$TEST_CONTEXT2 (active)"
}

@test "pc: list handles no contexts" {
    run_pc list
    assert_success
    assert_output_contains "No contexts found"
}

@test "pc: creates history entries" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    assert_file_exists "$HISTORY_FILE"
    grep -q "init $TEST_CONTEXT" "$HISTORY_FILE"
    
    run_pc switch "$TEST_CONTEXT"
    grep -q "switch $TEST_CONTEXT" "$HISTORY_FILE"
}

@test "pc: HANDOFF.md contains expected sections" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    local handoff="${PC_DIR}/${TEST_CONTEXT}/HANDOFF.md"
    
    # Check required sections
    grep -q "^# Project: $TEST_CONTEXT" "$handoff"
    grep -q "^## Current State" "$handoff"
    grep -q "^## Essential Context" "$handoff"
    grep -q "^## Next Step" "$handoff"
    grep -q "^## If Blocked" "$handoff"
}

@test "pc: TODO.md contains initial tasks" {
    run_pc init "$TEST_CONTEXT"
    assert_success
    
    local todo="${PC_DIR}/${TEST_CONTEXT}/TODO.md"
    
    # Check format and initial tasks
    grep -q "^# TODO - $TEST_CONTEXT" "$todo"
    grep -q "^- \[ \] Define project goals" "$todo"
    grep -q "^- \[ \] Set up development environment" "$todo"
}