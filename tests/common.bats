#!/usr/bin/env bats
# common.bats - Tests for common library functions

load test_helper

@test "common: color definitions are set" {
    [[ -n "$RED" ]]
    [[ -n "$GREEN" ]]
    [[ -n "$YELLOW" ]]
    [[ -n "$BLUE" ]]
    [[ -n "$NC" ]]
}

@test "common: error function outputs to stderr" {
    # error function writes to stderr and returns 0
    output=$(error "Test error message" 2>&1)
    assert_output_contains "Error: Test error message"
}

@test "common: validate_context_name accepts valid names" {
    run validate_context_name "valid-name"
    assert_success
    
    run validate_context_name "project123"
    assert_success
    
    run validate_context_name "my.project"
    assert_success
    
    run validate_context_name "test_project"
    assert_success
}

@test "common: validate_context_name rejects invalid names" {
    run validate_context_name ""
    assert_failure
    assert_output_contains "empty"
    
    run validate_context_name "invalid name"
    assert_failure
    assert_output_contains "letters, numbers"
    
    run validate_context_name "invalid/name"
    assert_failure
    
    run validate_context_name ".active"
    assert_failure
    assert_output_contains "Reserved"
}

@test "common: ensure_dir creates directory" {
    local test_dir="${TEST_DIR}/new_directory"
    
    assert_dir_not_exists "$test_dir"
    run ensure_dir "$test_dir"
    assert_success
    assert_dir_exists "$test_dir"
}

@test "common: ensure_dir handles existing directory" {
    local test_dir="${TEST_DIR}/existing_directory"
    mkdir -p "$test_dir"
    
    run ensure_dir "$test_dir"
    assert_success
}

@test "common: get_timestamp returns formatted timestamp" {
    run get_timestamp
    assert_success
    
    # Check format: YYYY-MM-DD HH:MM:SS
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]
}

@test "common: get_date returns formatted date" {
    run get_date
    assert_success
    
    # Check format: YYYY-MM-DD
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "common: safe_copy copies file successfully" {
    setup_test_env
    
    local src="${TEST_DIR}/source.txt"
    local dst="${TEST_DIR}/dest.txt"
    
    create_test_file "$src" "Source content"
    
    run safe_copy "$src" "$dst"
    assert_success
    assert_file_exists "$dst"
    
    # Verify content
    [[ "$(cat "$dst")" == "Source content" ]]
}

@test "common: safe_copy creates backup when overwriting" {
    setup_test_env
    
    local src="${TEST_DIR}/source.txt"
    local dst="${TEST_DIR}/dest.txt"
    
    create_test_file "$src" "New content"
    create_test_file "$dst" "Old content"
    
    run safe_copy "$src" "$dst"
    assert_success
    
    # Check backup was created
    local backup_files=$(ls "${dst}".backup.* 2>/dev/null | wc -l)
    [[ "$backup_files" -eq 1 ]]
    
    # Verify new content
    [[ "$(cat "$dst")" == "New content" ]]
}

@test "common: safe_copy fails on missing source" {
    setup_test_env
    
    run safe_copy "/nonexistent/file" "${TEST_DIR}/dest.txt"
    assert_failure
    assert_output_contains "does not exist"
}

@test "common: check_file returns success for existing readable file" {
    setup_test_env
    
    local test_file="${TEST_DIR}/test.txt"
    create_test_file "$test_file"
    
    run check_file "$test_file"
    assert_success
}

@test "common: check_file returns failure for missing file" {
    setup_test_env
    
    run check_file "${TEST_DIR}/nonexistent.txt"
    assert_failure
}

@test "common: escape_regex escapes special characters" {
    run escape_regex "test.*[0-9]+"
    assert_success
    # The escaped output should have backslashes before special chars
    [[ "$output" == "test\.\*\[0-9]\+" ]]
    
    run escape_regex "normal text"
    assert_success
    [[ "$output" == "normal text" ]]
}

@test "common: get_current_context returns empty when no active context" {
    setup_test_env
    
    run get_current_context
    assert_success
    [[ -z "$output" ]]
}

@test "common: set_current_context creates symlink" {
    setup_test_env
    
    run set_current_context "$TEST_CONTEXT"
    assert_success
    
    assert_symlink_target "$ACTIVE_LINK" "${PC_DIR}/${TEST_CONTEXT}"
    
    # Verify get_current_context returns the set context
    run get_current_context
    assert_success
    [[ "$output" == "$TEST_CONTEXT" ]]
}

@test "common: get_context_dir returns correct directory" {
    setup_test_env
    set_current_context "$TEST_CONTEXT"
    
    run get_context_dir
    assert_success
    [[ "$output" == "${PC_DIR}/${TEST_CONTEXT}" ]]
    
    run get_context_dir "specific-context"
    assert_success
    [[ "$output" == "${PC_DIR}/specific-context" ]]
}

@test "common: add_to_history appends to history file" {
    setup_test_env
    
    run add_to_history "test action" "with details"
    assert_success
    
    assert_file_exists "$HISTORY_FILE"
    grep -q "test action with details" "$HISTORY_FILE"
}

@test "common: create_backup creates tar.gz archive" {
    setup_test_env
    create_test_context "$TEST_CONTEXT"
    
    run create_backup "$TEST_CONTEXT"
    assert_success
    
    # Check backup exists
    local backup_count=$(find "$BACKUP_DIR" -name "${TEST_CONTEXT}_*.tar.gz" -type f | wc -l)
    [[ "$backup_count" -eq 1 ]]
}

@test "common: init_pc_structure creates all required directories" {
    setup_test_env
    
    # Remove directories first
    rm -rf "$PC_DIR"
    
    run init_pc_structure
    assert_success
    
    assert_dir_exists "$PC_DIR"
    assert_dir_exists "$STASH_DIR"
    assert_dir_exists "$BACKUP_DIR"
    assert_file_exists "$HISTORY_FILE"
}

@test "common: command_exists detects available commands" {
    run command_exists "bash"
    assert_success
    
    run command_exists "nonexistent_command_xyz"
    assert_failure
}

@test "common: format_size formats bytes correctly" {
    run format_size 512
    assert_success
    [[ "$output" == "512B" ]]
    
    run format_size 2048
    assert_success
    [[ "$output" == "2KB" ]]
    
    run format_size 2097152
    assert_success
    [[ "$output" == "2MB" ]]
}