#!/usr/bin/env bats
# simple.bats - Simple tests that don't require complex setup

load test_helper

@test "simple: validate_context_name works correctly" {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    
    # Valid names
    validate_context_name "test-project" && echo "pass1"
    validate_context_name "my_project" && echo "pass2"
    validate_context_name "project123" && echo "pass3"
    
    # Invalid names
    ! validate_context_name "" && echo "fail1"
    ! validate_context_name "has spaces" && echo "fail2"
    ! validate_context_name ".active" && echo "fail3"
}

@test "simple: color codes are defined" {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    
    [[ -n "$RED" ]]
    [[ -n "$GREEN" ]]
    [[ -n "$YELLOW" ]]
    [[ -n "$BLUE" ]]
    [[ -n "$NC" ]]
}

@test "simple: timestamp functions work" {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    
    timestamp=$(get_timestamp)
    [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]
    
    date=$(get_date)
    [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "simple: escape_regex escapes correctly" {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    
    result=$(escape_regex "test.*[0-9]+")
    [[ "$result" == "test\.\*\[0-9]\+" ]]
    
    result=$(escape_regex "normal text")
    [[ "$result" == "normal text" ]]
}

@test "simple: command_exists detects commands" {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    
    command_exists bash
    command_exists ls
    ! command_exists nonexistent_command_xyz
}

@test "simple: format_size formats correctly" {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    
    [[ "$(format_size 512)" == "512B" ]]
    [[ "$(format_size 2048)" == "2KB" ]]
    [[ "$(format_size 2097152)" == "2MB" ]]
}