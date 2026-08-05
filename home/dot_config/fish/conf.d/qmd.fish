# qmd bundles better-sqlite3 12.10.0, which predates better-sqlite3's move to
# N-API (13.0.0) and crashes intermittently under our pinned node's (24) newer
# V8 internals — see the qmd comment in mise/config.toml. Force qmd to run
# under node 22 instead, whose ABI it was actually built against. A PATH-based
# script in ~/.local/bin can't win this: mise puts npm:@tobilu/qmd's own bin
# dir ahead of ~/.local/bin, so only a fish function shadows it reliably.
function qmd --wraps qmd --description "Run qmd under node 22 (better-sqlite3 ABI compat)"
    mise exec node@22 -- qmd $argv
end
