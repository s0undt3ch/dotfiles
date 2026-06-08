if status is-interactive
    set -x GITHUB_TOKEN (gh auth token)
    set -x GITHUB_ACCESS_TOKEN $GITHUB_TOKEN
    set -x HOMEBREW_GITHUB_API_TOKEN $GITHUB_TOKEN
end
