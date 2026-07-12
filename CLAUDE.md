# CLAUDE.md

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Arch Linux is the
primary target; macOS is supported via templating. Edits go to the **source**
in this repo, then `chezmoi apply` writes them to `$HOME`.

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
- Tool versions are pinned to exact versions in `mise.toml` so Renovate can bump
  them — don't set them back to `"latest"`.

## chezmoi layout

- Source root is **`home/`** (`.chezmoiroot`). A path like `~/.config/fish/config.fish`
  lives at `home/dot_config/fish/config.fish.tmpl` in the repo.
- Naming: `dot_` → `.`, `executable_` → +x, `private_` → 0600, `.tmpl` → templated,
  `run_onchange_*` → scripts re-run when their content hash changes.
- **Edit the source, not the target.** After editing, `chezmoi apply` (or
  `chezmoi apply ~/.config/<path>` for one file). `chezmoi apply --dry-run --verbose`
  to preview. Never hand-edit `~/.config/...` — chezmoi will overwrite it.
- OS gating in templates: `{{ if eq .chezmoi.os "darwin" }}...{{ end }}`
  (and `.chezmoiignore` gates whole files, e.g. macOS-only `Library`).

## Packages (declarative, don't install ad-hoc)

- Managed by [metapac](https://github.com/ripytide/metapac): edit
  `home/dot_config/metapac/groups/arch.toml` (Linux/yay) or `brew.toml` (macOS).
- `chezmoi apply` triggers `run_onchange_after_metapac-sync.sh.tmpl` →
  `metapac sync`. Don't `yay -S` / `brew install` directly; add to the group file.

## Conventions & gotchas

- Formatting config: `.editorconfig` (`[*.sh]` drives shfmt indent), `.taplo.toml`
  (TOML), `.stylua.toml` (Lua). `.shellcheckrc` disables intentional-idiom checks.
- `typos.toml` allowlists false positives; the hook runs `typos --write-changes`
  (auto-fixes), so add new false positives there rather than letting it rewrite code.
- On Arch the Zed editor binary is **`zeditor`** (the `zed` name collides with the
  ZFS Event Daemon); a fish abbr maps `zed` → `zeditor`.
