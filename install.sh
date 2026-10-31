#!/bin/sh
# Bootstrap this machine from this dotfiles repo with mise.
#
#   ./install.sh                  # install mise (if needed), then mise bootstrap
#   ./install.sh --work           # same, and turn on the work profile
#   ./install.sh --dry-run        # show what would change, don't apply
#
# The checkout must live at ~/projects/me/dotfiles: the global mise config
# (files/.config/mise, linked to ~/.config/mise) points its dotfile sources there.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR="${HOME}/projects/me/dotfiles"
BIN_DIR="${HOME}/.local/bin"

DRY_RUN=
WORK=0
for arg in "$@"; do
    case "${arg}" in
    --dry-run) DRY_RUN=--dry-run ;;
    --work) WORK=1 ;;
    *)
        echo "unknown argument: ${arg}" >&2
        exit 2
        ;;
    esac
done

if [ "${SCRIPT_DIR}" != "${REPO_DIR}" ]; then
    echo "Clone this repo to ${REPO_DIR} and run install.sh from there." >&2
    exit 1
fi

if [ "$(uname)" = "Linux" ] && ! command -v yay >/dev/null 2>&1; then
    echo "yay (AUR helper) is needed for the aur: packages. Install it first:" >&2
    echo "  sudo pacman -S --needed git base-devel" >&2
    echo "  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && (cd /tmp/yay-bin && makepkg -si)" >&2
    exit 1
fi

MISE=$(command -v mise 2>/dev/null || true)
[ -z "${MISE}" ] && [ -x "${BIN_DIR}/mise" ] && MISE="${BIN_DIR}/mise"

if [ -z "${MISE}" ]; then
    echo "==> mise not found; installing..."
    if command -v pacman >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm mise || true
    elif command -v brew >/dev/null 2>&1; then
        brew install mise || true
    fi
    MISE=$(command -v mise 2>/dev/null || true)
    if [ -z "${MISE}" ]; then
        echo "==> Falling back to the official installer (-> ${BIN_DIR})"
        curl -fsSL https://mise.run | MISE_INSTALL_PATH="${BIN_DIR}/mise" sh
        MISE="${BIN_DIR}/mise"
    fi
fi

echo "==> Using $("${MISE}" --version)"

# miserc.local.toml is gitignored and only read once ~/.config/mise is linked,
# so the first run also needs -E work.
if [ "${WORK}" -eq 1 ]; then
    if [ -z "${DRY_RUN}" ]; then
        printf 'env = ["work"]\n' >"${REPO_DIR}/files/.config/mise/miserc.local.toml"
    fi
    set -- -E work
else
    set --
fi

# mise links ~/.config/mise to the repo and refuses a non-empty directory there.
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/mise"
if [ -d "${CONFIG_DIR}" ] && [ ! -L "${CONFIG_DIR}" ] && [ -n "$(ls -A "${CONFIG_DIR}")" ]; then
    BACKUP="${CONFIG_DIR}.pre-mise-$(date +%Y%m%d%H%M%S)"
    if [ -n "${DRY_RUN}" ]; then
        echo "==> would move ${CONFIG_DIR} to ${BACKUP}"
    else
        echo "==> moving ${CONFIG_DIR} to ${BACKUP}"
        mv "${CONFIG_DIR}" "${BACKUP}"
    fi
fi

ORIGIN=$(git -C "${REPO_DIR}" remote get-url origin)
# shellcheck disable=SC2086 # DRY_RUN is empty or one flag
exec "${MISE}" "$@" bootstrap ${DRY_RUN} \
    --from "${ORIGIN}" \
    --from-dir "${REPO_DIR}" \
    --config-dir files/.config/mise
