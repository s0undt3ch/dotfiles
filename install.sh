#!/bin/sh
# Bootstrap this dotfiles repo with chezmoi on any OS.
#
#   ./install.sh            # install chezmoi (if needed), then init + apply
#   ./install.sh --dry-run  # show what would change, don't apply
#
# chezmoi is installed via the native package manager when available
# (pacman / brew), falling back to the official standalone installer into
# ~/.local/bin. The repo root (this directory) is used as the chezmoi source;
# .chezmoiroot then redirects the actual source into home/.
set -eu

# Directory containing this script == the chezmoi source root.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN_DIR="${HOME}/.local/bin"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

CHEZMOI=$(command -v chezmoi 2>/dev/null || true)
[ -z "${CHEZMOI}" ] && [ -x "${BIN_DIR}/chezmoi" ] && CHEZMOI="${BIN_DIR}/chezmoi"

if [ -z "${CHEZMOI}" ]; then
    echo "==> chezmoi not found; installing..."
    if command -v pacman >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm chezmoi || true
    elif command -v brew >/dev/null 2>&1; then
        brew install chezmoi || true
    fi
    CHEZMOI=$(command -v chezmoi 2>/dev/null || true)
    if [ -z "${CHEZMOI}" ]; then
        echo "==> Falling back to the official standalone installer (-> ${BIN_DIR})"
        mkdir -p "${BIN_DIR}"
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${BIN_DIR}"
        CHEZMOI="${BIN_DIR}/chezmoi"
    fi
fi

echo "==> Using $("${CHEZMOI}" --version)"

# Point plain `chezmoi` invocations at this repo for future runs.
mkdir -p "${HOME}/.config/chezmoi"
cat >"${HOME}/.config/chezmoi/chezmoi.toml" <<EOF
sourceDir = "${SCRIPT_DIR}"
EOF

if [ "${DRY_RUN}" -eq 1 ]; then
    echo "==> chezmoi diff (dry run)"
    exec "${CHEZMOI}" --source "${SCRIPT_DIR}" diff
fi

echo "==> chezmoi init --apply"
exec "${CHEZMOI}" --source "${SCRIPT_DIR}" init --apply
