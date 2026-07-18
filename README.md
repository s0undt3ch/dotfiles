# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Arch Linux is the primary target;
macOS is supported through chezmoi templating. Packages are installed declaratively with
[metapac](https://github.com/ripytide/metapac), and development tooling is pinned with
[mise](https://mise.jdx.dev).

## Bootstrap a new machine

The `install.sh` script installs chezmoi (via `pacman`/`brew`, or the standalone installer as a
fallback), points it at this repo, and applies everything:

```bash
git clone https://github.com/s0undt3ch/dotfiles.git
cd dotfiles
./install.sh          # add --dry-run to preview with `chezmoi diff` first
```

On first apply, chezmoi also runs the `run_onchange_` scripts that install packages via metapac and
dev tools via mise.

## Everyday use

- Preview what would change: `chezmoi diff`
- Apply changes to `$HOME`: `chezmoi apply` (add `--dry-run --verbose` to preview)
- Edit a managed file: change the **source** under `home/` in this repo, then `chezmoi apply`

> Do not hand-edit files under `~` (e.g. `~/.config/...`). chezmoi owns them and `apply` will
> overwrite local edits. Always edit the source in this repo.

### Repo layout

The chezmoi source root is `home/` (set in `.chezmoiroot`), so `home/dot_config/foo` maps to
`~/.config/foo`. chezmoi's filename conventions:

| Prefix / suffix   | Meaning                                              |
|-------------------|------------------------------------------------------|
| `dot_`            | Leading `.` in the target (`dot_config` → `.config`) |
| `executable_`     | File is made executable                              |
| `private_`        | File is created with `0600` permissions              |
| `.tmpl`           | File is rendered as a Go template                    |
| `run_onchange_*`  | Script re-run whenever its content hash changes      |

OS-specific behaviour is gated in templates with `{{ if eq .chezmoi.os "darwin" }}...{{ end }}`, and
whole files can be excluded per-OS via `.chezmoiignore`.

## Managing packages

Packages are declared, not installed by hand. Edit the relevant metapac group file:

- Arch (Linux, via `yay`): `home/dot_config/metapac/groups/arch.toml`
- macOS (via Homebrew): `home/dot_config/metapac/groups/brew.toml`

On the next `chezmoi apply`, the `run_onchange_after_metapac-sync` script runs `metapac sync` to
install anything missing. The backend is chosen automatically per OS.

## Development tooling

Dev tools are pinned to exact versions in `mise.toml` (the single source of truth). Install them
with:

```bash
mise install
```

This provides `prek` (the pre-commit runner) and the binaries the hooks call: `gitleaks`,
`shellcheck`, `shfmt`, `taplo`, `typos`, and `yamlfmt`. [Renovate](renovate.json5) opens grouped PRs
to bump these pins and the pre-commit hook revisions.

### Pre-commit hooks

Hooks are configured in `.pre-commit-config.yaml` using
[s0undt3ch/pre-commit-hooks](https://github.com/s0undt3ch/pre-commit-hooks), which run the
mise-installed tools straight from `PATH` (no second version pin to drift from `mise.toml`).

Run them manually, or install the git hook:

```bash
prek run -av      # run against everything (-a all files, -v verbose)
prek install      # install the git commit hook
```

The hooks resolve their tools from mise's `PATH`, so with mise activated in your shell they just
work. If you run from a shell where mise is **not** activated, prefix the command with `mise exec --`
so the tools are found:

```bash
mise exec -- git commit -m "..."
mise exec -- prek run -av
```

Supporting config: `typos.toml` (spell-check allowlist), `.shellcheckrc` (disabled idiom checks),
`.taplo.toml` (TOML formatting), `.stylua.toml` (Lua formatting), and `.editorconfig`.

## Manual host setup

Some host configuration lives outside chezmoi (root-owned system files that `chezmoi apply` does not
manage). Redo these by hand on a new machine:

- [Fingerprint auth on Arch](docs/fingerprint-auth-arch.md) — `fprintd` + PAM for `sudo`, TTY login,
  polkit, and the KDE lock screen.
