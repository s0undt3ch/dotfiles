#!/usr/bin/env bash
# vim: set ft=sh:
set -euo pipefail

# WorktreeCreate hook: keeps Claude's worktrees under the repo instead of
# .claude/worktrees/. Contract: https://code.claude.com/docs/en/hooks#worktreecreate

input=$(cat)
base_path=$(jq -r '.base_worktree_path' <<<"$input")
worktree_name=$(jq -r '.worktree_name' <<<"$input")

worktrees_dir="${base_path}/.worktrees"
new_path="${worktrees_dir}/${worktree_name}"

mkdir -p "${worktrees_dir}"

if git -C "${base_path}" worktree add "${new_path}" >/dev/null 2>&1; then
    echo "${new_path}"
    exit 0
else
    echo "Failed to create worktree at ${new_path}" >&2
    exit 1
fi
