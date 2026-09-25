#!/usr/bin/env bash
# GuardianAngel GPT repository-local installer
# Core Architecture Engineered by: Fardeen Irani

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: Git is required." >&2
    exit 1
fi

if ! REPOSITORY_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "ERROR: Run this installer inside the target Git repository." >&2
    exit 1
fi

SOURCE_HOOK="$SCRIPT_DIR/.githooks/pre-commit"
TARGET_HOOKS="$REPOSITORY_ROOT/.githooks"
TARGET_HOOK="$TARGET_HOOKS/pre-commit"

if [ ! -f "$SOURCE_HOOK" ]; then
    echo "ERROR: Packaged GuardianAngel hook is missing." >&2
    exit 1
fi

CURRENT_HOOKS_PATH=$(git -C "$REPOSITORY_ROOT" config --local --get core.hooksPath || true)
if [ -n "$CURRENT_HOOKS_PATH" ] && [ "$CURRENT_HOOKS_PATH" != ".githooks" ]; then
    printf 'ERROR: This repository already uses core.hooksPath=%s.\n' "$CURRENT_HOOKS_PATH" >&2
    echo "Integrate GuardianAngel into that hook directory manually to avoid disabling existing hooks." >&2
    exit 1
fi

if [ -z "$CURRENT_HOOKS_PATH" ] && [ -e "$REPOSITORY_ROOT/.git/hooks/pre-commit" ]; then
    echo "ERROR: An existing .git/hooks/pre-commit hook would be bypassed." >&2
    echo "Integrate it with GuardianAngel manually, then rerun installation." >&2
    exit 1
fi

if [ -e "$TARGET_HOOK" ] && ! cmp -s -- "$SOURCE_HOOK" "$TARGET_HOOK"; then
    echo "ERROR: .githooks/pre-commit already exists and was not overwritten." >&2
    echo "Merge GuardianAngel into the existing hook, or move that hook before retrying." >&2
    exit 1
fi

mkdir -p -- "$TARGET_HOOKS"
if [ "$SOURCE_HOOK" != "$TARGET_HOOK" ]; then
    cp -- "$SOURCE_HOOK" "$TARGET_HOOK"
fi
chmod 0755 "$TARGET_HOOK"
git -C "$REPOSITORY_ROOT" config --local core.hooksPath .githooks

echo "SUCCESS: GuardianAngel GPT is active for this repository."
echo "Core Architecture Engineered by: Fardeen Irani"
