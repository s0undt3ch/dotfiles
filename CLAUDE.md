# CLAUDE.md

Personal dotfiles, packages and services managed with mise's `[dotfiles]` and
`[bootstrap.*]` features (mise >= 2026.10.24). Arch Linux is the primary target;
macOS is supported via per-OS config files and Tera templates. Edits go to the
**source** in this repo, then `mise dot apply` / `mise bootstrap` write them to `$HOME`.

## Committing (read this first)

- The runner is **`prek`** (not `pre-commit`), pinned in `mise.toml`. Run hooks
  manually with `prek run -av` (`-a` all files, `-v` verbose).
- The hooks call their tools (gitleaks, shellcheck, shfmt, taplo, typos, yamlfmt)
  from **mise's PATH**. With mise activated in the shell (the normal setup) both
  `git commit` and `prek` just work. In a shell where mise is **not** activated
  (e.g. an agent / non-login shell), the tools aren't on PATH — prefix the command
  with `mise exec --`, e.g. `mise exec -- git commit ...` or `mise exec -- prek run -av`.
- Formatter hooks (shfmt, taplo, yamlfmt) **modify files then report failure** on
  the run that changed them. Re-stage and commit again — it passes once formatted.
- Work commits **directly on `main`** (personal repo, no PR flow). Push only when asked.

## Bumping mise tool versions

- "Update mise tools" means **`files/.config/mise/config.toml`** plus the
  platform files `config.macos.toml` and `config.linux-arm64.toml` (the user's
  global tools). Renovate bumps both these and the repo-root `mise.toml`.
- Never write `"latest"` in any mise file. Resolve the real version with
  `mise latest <tool>` (e.g. `mise latest node`, `mise latest "aqua:quarylabs/sqruff"`)
  and pin that exact string.
- llmtrim and qdrant appear once per platform file (different asset picks).
  Bump every copy to the same version.
- Then **ask** whether to run `mise install`. Don't run it unprompted.

## mise layout

- `~/.config/mise` is a symlink to **`files/.config/mise`** in this repo, so the
  global config follows the checked-out branch.
- `files/` holds dotfile sources under their real names: `~/.config/fish/config.fish`
  comes from `files/.config/fish/config.fish.tera`. Entries live in
  `conf.d/dotfiles.toml`. Default mode is `copy`; `.tera` files use
  `mode = "template"` with an explicit `source = "~/projects/me/dotfiles/files/..."`.
- Every `[dotfiles]` entry needs an explicit `mode` (or `permissions` only): an
  entry with just `exclude`/`variants` is parsed as an edit and ignored.
- OS-specific config goes in `config.macos.toml` / `config.linux.toml`
  (`auto_env = true` in `miserc.toml` loads them). `conf.d/` loads every file
  regardless of suffix, so it can't hold per-OS config. In templates use
  `{% if os() == "macos" %}`.
- Work profile: work machines set `env = ["work"]` in the gitignored
  `files/.config/mise/miserc.local.toml`. Templates test
  `vars.work | default(value=false)`; work-only dotfiles use
  `variants = [{ profile = "work" }]`.
- Task `sources` don't expand `~`: write `{{env.HOME}}/...`.
- **Edit the source, not the target.** Preview with `mise dot diff` /
  `mise bootstrap --dry-run`, then **ask** before `mise dot apply` or
  `mise bootstrap`. Never hand-edit `~/.config/...`.
- Nothing is tracked or autosaved: `history.enabled = false`; never use
  `mode = "track"`, `mise dot track` or the `history-watch` service.
- Services are mise launchd agents / systemd units named `dev.mise.<name>`.
  The root `com.pedro.mempalace-wake` daemon stays a task (mise does user agents only).

## Packages (declarative, don't install ad-hoc)

- `[bootstrap.packages]` in `config.macos.toml` (`brew:` / `brew-cask:`) and
  `config.linux.toml` (`pacman:` / `aur:` via yay), with `{}` as the value.
- `mise bootstrap --only packages` installs anything missing. Don't
  `yay -S` / `brew install` directly; add the line.
- pacman and aur don't prune: removing a line doesn't uninstall the package.

## Conventions & gotchas

- Formatting config: `.editorconfig` (`[*.sh]` drives shfmt indent), `.taplo.toml`
  (TOML), `.stylua.toml` (Lua). `.shellcheckrc` disables intentional-idiom checks.
- `typos.toml` allowlists false positives; the hook runs `typos --write-changes`
  (auto-fixes), so add new false positives there rather than letting it rewrite code.
- On Arch the Zed editor binary is **`zeditor`** (the `zed` name collides with the
  ZFS Event Daemon); a fish abbr maps `zed` → `zeditor`.
