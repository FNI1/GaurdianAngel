#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
HOOK_PATH="$SCRIPT_DIR/../.githooks/pre-commit"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/guardianangel-test.XXXXXX")
trap 'rm -rf -- "$TEST_ROOT"' EXIT HUP INT TERM

REPOSITORY="$TEST_ROOT/repository"
mkdir -p "$REPOSITORY"
git -C "$REPOSITORY" init -q
git -C "$REPOSITORY" config user.name "GuardianAngel Test"
git -C "$REPOSITORY" config user.email "guardianangel@example.invalid"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_clean() {
    local output
    if ! output=$(cd "$REPOSITORY" && "$HOOK_PATH" 2>&1); then
        printf '%s\n' "$output" >&2
        fail "clean staged content was blocked"
    fi
}

assert_blocked_without_echoing() {
    local label=$1
    local filename=$2
    local value=$3
    local output

    printf 'credential=%s\n' "$value" >"$REPOSITORY/$filename"
    git -C "$REPOSITORY" add -- "$filename"

    if output=$(cd "$REPOSITORY" && "$HOOK_PATH" 2>&1); then
        fail "$label was not blocked"
    fi

    if [[ "$output" == *"$value"* ]]; then
        fail "$label was echoed in scanner output"
    fi

    git -C "$REPOSITORY" reset -q -- "$filename"
    rm -f -- "$REPOSITORY/$filename"
}

printf 'const message = "safe";\n' >"$REPOSITORY/clean.js"
git -C "$REPOSITORY" add clean.js
assert_clean
git -C "$REPOSITORY" commit -qm "clean baseline"

if ! output=$(cd "$REPOSITORY" && GUARDIANANGEL_SCAN_ALL=1 "$HOOK_PATH" 2>&1); then
    printf '%s\n' "$output" >&2
    fail "clean full-repository scan was blocked"
fi

# Values are assembled at runtime so this test file never contains a complete
# credential-shaped fixture that could trigger another scanner.
assert_blocked_without_echoing "OpenAI" "openai.env" "sk-proj-$(printf 'A%.0s' {1..32})"
assert_blocked_without_echoing "GitHub" "github.env" "ghp_$(printf 'B%.0s' {1..36})"
assert_blocked_without_echoing "GitHub fine-grained" "github-fine.env" "github_pat_$(printf 'C%.0s' {1..40})"
assert_blocked_without_echoing "Slack" "slack.env" "xoxb-1234-$(printf 'D%.0s' {1..24})"
assert_blocked_without_echoing "Google" "google.env" "AIza$(printf 'E%.0s' {1..35})"
assert_blocked_without_echoing "Square" "square.env" "sq0atp-$(printf 'F%.0s' {1..32})"
assert_blocked_without_echoing "Shopify" "shopify.env" "shpat_$(printf '1%.0s' {1..32})"
assert_blocked_without_echoing "filename with spaces" "config with spaces.env" "sk-$(printf 'G%.0s' {1..32})"

# Confirm that the hook reads the staged blob, not a subsequently cleaned
# working-tree copy.
STAGED_ONLY="sk-$(printf 'H%.0s' {1..32})"
printf 'credential=%s\n' "$STAGED_ONLY" >"$REPOSITORY/staged-only.env"
git -C "$REPOSITORY" add staged-only.env
printf 'credential=clean\n' >"$REPOSITORY/staged-only.env"
if output=$(cd "$REPOSITORY" && "$HOOK_PATH" 2>&1); then
    fail "staged-only credential was not blocked"
fi
if [[ "$output" == *"$STAGED_ONLY"* ]]; then
    fail "staged-only credential was echoed in scanner output"
fi

echo "PASS: GuardianAngel pre-commit tests completed successfully."
