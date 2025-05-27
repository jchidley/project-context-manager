#!/usr/bin/env bash
# test_helper.bash - Helper functions for BATS tests

# Set up test environment
export TEST_DIR="${BATS_TEST_TMPDIR}"
export PC_DIR="${TEST_DIR}/.project-contexts"
export HOME="${TEST_DIR}"

# Source the common library
source "${BATS_TEST_DIRNAME}/../lib/common.sh"

# Test fixtures
readonly TEST_CONTEXT="test-project"
readonly TEST_CONTEXT2="another-project"

# Setup function to create clean test environment
setup_test_env() {
    # Clean test directory (be careful with hidden files)
    if [[ -d "${TEST_DIR}" ]]; then
        find "${TEST_DIR}" -mindepth 1 -maxdepth 1 -name ".*" -exec rm -rf {} + 2>/dev/null || true
        rm -rf "${TEST_DIR:?}"/* 2>/dev/null || true
    fi
    
    # Initialize PC structure
    init_pc_structure
    
    # Create test git repo if needed
    if [[ "${1:-}" == "with_git" ]]; then
        git init "${TEST_DIR}/repo" >/dev/null 2>&1
        cd "${TEST_DIR}/repo" || return 1
        git config user.email "test@example.com"
        git config user.name "Test User"
        echo "test" > test.txt
        git add test.txt
        git commit -m "Initial commit" >/dev/null 2>&1
    fi
    
    # Set DEBUG mode if requested
    [[ "${BATS_DEBUG:-}" == "1" ]] && export DEBUG=1
}

# Teardown function
teardown_test_env() {
    # Clean up test directory
    cd "${BATS_TEST_DIRNAME}" || return
    rm -rf "${TEST_DIR:?}"/*
    rm -rf "${TEST_DIR:?}"/.*
}

# Assert functions
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected success but got status: $status"
        echo "Output: ${output}"
        return 1
    fi
}

assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected failure but got success"
        echo "Output: ${output}"
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    if [[ ! "$output" =~ $expected ]]; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_output_not_contains() {
    local not_expected="$1"
    if [[ "$output" =~ $not_expected ]]; then
        echo "Expected output NOT to contain: $not_expected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Expected file to exist: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "Expected file NOT to exist: $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Expected directory to exist: $dir"
        return 1
    fi
}

assert_dir_not_exists() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        echo "Expected directory NOT to exist: $dir"
        return 1
    fi
}

assert_symlink_target() {
    local link="$1"
    local expected_target="$2"
    
    if [[ ! -L "$link" ]]; then
        echo "Expected symlink to exist: $link"
        return 1
    fi
    
    local actual_target=$(readlink "$link")
    if [[ "$actual_target" != "$expected_target" ]]; then
        echo "Expected symlink target: $expected_target"
        echo "Actual symlink target: $actual_target"
        return 1
    fi
}

# Create a test file with content
create_test_file() {
    local file="$1"
    local content="${2:-Test content}"
    echo "$content" > "$file"
}

# Create a test context with files
create_test_context() {
    local context="$1"
    local context_dir="${PC_DIR}/${context}"
    
    mkdir -p "$context_dir"
    create_test_file "${context_dir}/HANDOFF.md" "# Handoff for $context"
    create_test_file "${context_dir}/TODO.md" "- [ ] Test todo"
    create_test_file "${context_dir}/PROJECT_WISDOM.md" "# Wisdom for $context"
}

# Run command and capture output/status
run_with_status() {
    output=$("$@" 2>&1)
    status=$?
}