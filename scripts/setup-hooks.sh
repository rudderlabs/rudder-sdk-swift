#!/bin/bash

# ──────────────────────────────────────────────────────────────
# setup-hooks.sh
# One-time setup to activate the project's local git hooks.
#
# Run this after cloning the repo:
#   sh scripts/setup-hooks.sh
# ──────────────────────────────────────────────────────────────

HOOK_DIR="scripts/git-hooks"

# Check that we're in the repo root
if [ ! -d "$HOOK_DIR" ]; then
    echo "Error: Could not find '$HOOK_DIR'."
    echo "Please run this script from the repository root directory."
    exit 1
fi

# Detect the existing global hooksPath (Gitleaks, etc.)
GLOBAL_HOOKS_PATH=$(git config --global core.hooksPath 2>/dev/null || true)

# Set the LOCAL core.hooksPath for this repo only.
# IMPORTANT: This overrides the global core.hooksPath for this repo.
# Each hook script chains back to the global hooks to keep Gitleaks working.
git config --local core.hooksPath "$HOOK_DIR"

# Make sure all hook scripts are executable
chmod +x "$HOOK_DIR/commit-msg"
chmod +x "$HOOK_DIR/pre-commit"
chmod +x "$HOOK_DIR/pre-push"

echo ""
echo "Git hooks installed successfully."
echo ""
echo "  Local hooks directory: $HOOK_DIR"
echo "  Hooks activated:"
echo "    - commit-msg  : Validates conventional commit message format"
echo "    - pre-commit  : Runs SwiftLint on staged Swift source files"
echo "    - pre-push    : Validates branch name, builds, and runs tests"
echo ""

if [ -n "$GLOBAL_HOOKS_PATH" ]; then
    echo "  Global hooks detected: $GLOBAL_HOOKS_PATH"
    echo "  Global hooks (Gitleaks) will be chained automatically."
    echo ""

    # Verify each global hook exists and is executable
    MISSING=0
    for hook in commit-msg pre-commit pre-push; do
        if [ ! -x "$GLOBAL_HOOKS_PATH/$hook" ]; then
            echo "  [WARNING] Global hook not found or not executable: $GLOBAL_HOOKS_PATH/$hook"
            MISSING=1
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        echo "  All global hooks verified."
    fi
else
    echo "  No global hooks detected. Only local hooks will run."
fi

echo ""
echo "Done. You can verify with: git config --local core.hooksPath"
