# Path ordering. This file is named with a leading `00_` so it runs before
# `halostatue_fish_mise.fish`, which means mise's `activate fish` prepends
# its tool install dirs *after* these — so mise tools take priority over
# brew, mysql-client, and ~/.local/bin.
#
# We can't rely on `brew --prefix` here because the brew conf.d file
# (`halostatue_fish_brew.fish`) hasn't put brew on PATH yet. Hardcode the
# Apple Silicon prefix; this dotfiles repo targets macOS.

set -l brew_prefix /opt/homebrew

fish_add_path --prepend --path --move $brew_prefix/opt/mysql-client@8.4/bin
fish_add_path --prepend --path --move $brew_prefix/bin
fish_add_path --prepend --path --move $HOME/.local/bin

# Final order (lowest priority → highest):
#   system PATH > mysql-client > Homebrew > ~/.local/bin > mise tool installs
