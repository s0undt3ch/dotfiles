# dotfiles

Personal dotfiles, packages and services, all driven by [mise](https://mise.jdx.dev): its
[dotfiles](https://mise.jdx.dev/dotfiles/) and [bootstrap](https://mise.jdx.dev/bootstrap.html)
features. Arch Linux is the primary target; macOS is supported through per-OS config files and Tera
templates.

## Bootstrap a new machine

The checkout must live at `~/projects/me/dotfiles`: the global mise config points its dotfile
sources there. On Arch, install `yay` first (`install.sh` tells you how if it's missing).

```bash
git clone git@github.com:s0undt3ch/dotfiles.git ~/projects/me/dotfiles
cd ~/projects/me/dotfiles
./install.sh            # add --work on a work machine, --dry-run to preview
```

`install.sh` installs mise if needed, then runs `mise bootstrap`, which links `~/.config/mise` to
`files/.config/mise` in this repo and applies everything: packages, dotfiles, services, tools and
the `bootstrap` task.

## Everyday use

- Preview: `mise dot diff`, `mise bootstrap --dry-run`
- Apply dotfiles: `mise dot apply`
- Apply everything: `mise bootstrap`
- Edit a managed file: change it under `files/` in this repo, then apply

> Do not hand-edit files under `~` (e.g. `~/.config/...`). They are copies; the next apply
> overwrites local edits. Always edit the source in this repo.

### Repo layout

| Path                                   | What it holds                                                                 |
|----------------------------------------|-------------------------------------------------------------------------------|
| `files/`                               | Dotfile sources under their real names (`files/.config/foo` → `~/.config/foo`) |
| `*.tera`                               | Tera templates, rendered by `mode = "template"` entries                       |
| `files/.config/mise/config.toml`       | Global tools, settings, vars and the `bootstrap` task                         |
| `files/.config/mise/config.macos.toml` | macOS-only tools, Homebrew packages and launchd agents                        |
| `files/.config/mise/config.linux.toml` | Linux-only pacman/AUR packages, system services and systemd units             |
| `files/.config/mise/config.work.toml`  | Work-profile vars                                                             |
| `files/.config/mise/conf.d/dotfiles.toml` | The `[dotfiles]` entries                                                   |
| `files/.config/mise/tasks/`            | One-off setup tasks run by `mise bootstrap`                                   |

`miserc.toml` sets `auto_env = true`, so mise loads the `config.<os>.toml` file for the machine
it runs on. A work machine also has a gitignored `files/.config/mise/miserc.local.toml` with
`env = ["work"]`, which loads `config.work.toml` and selects the `profile = "work"` dotfiles.

## Managing packages

Packages are declared, not installed by hand: add `"brew:<name>" = {}` (or `brew-cask:`) to
`config.macos.toml`, or `"pacman:<name>" = {}` / `"aur:<name>" = {}` to `config.linux.toml`, then
run `mise bootstrap --only packages`.

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

Some host configuration lives outside mise (root-owned system files that `mise bootstrap` does not
manage). Redo these by hand on a new machine:

- [Fingerprint auth on Arch](docs/fingerprint-auth-arch.md) — `fprintd` + PAM for `sudo`, TTY login,
  polkit, and the KDE lock screen.
