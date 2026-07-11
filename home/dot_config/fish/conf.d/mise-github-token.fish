# Provide a GitHub token to mise so it can resolve releases from private
# repos (e.g. PaddleHQ/pdl) via the github backend. Falls back silently if
# `gh` is not installed or not authenticated.
if not set -q GITHUB_TOKEN
    if type -q gh
        set -l token (gh auth token 2>/dev/null)
        if test -n "$token"
            set -gx GITHUB_TOKEN $token
        end
    end
end
