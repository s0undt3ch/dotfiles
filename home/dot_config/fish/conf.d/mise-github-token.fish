# Provide a GitHub token to mise and Homebrew so they can resolve
# releases/formulae from private repos (e.g. PaddleHQ/pdl, PaddleHQ taps)
# via the github backend. Falls back silently if `gh` is not installed or
# not authenticated.
if not set -q GITHUB_TOKEN
    if type -q gh
        set -l token (gh auth token 2>/dev/null)
        if test -n "$token"
            set -gx GITHUB_TOKEN $token
        end
    end
end

if set -q GITHUB_TOKEN; and not set -q HOMEBREW_GITHUB_API_TOKEN
    set -gx HOMEBREW_GITHUB_API_TOKEN $GITHUB_TOKEN
end
