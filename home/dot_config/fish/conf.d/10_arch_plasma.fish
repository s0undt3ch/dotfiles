# Arch/Linux: start Plasma (Wayland) automatically when logging in on TTY1.
# Ported from the previous zsh setup. Inert on non-Linux.
if test (uname) = Linux
    if status is-login; and test -z "$DISPLAY"; and test (tty) = /dev/tty1
        set -gx MOZ_ENABLE_WAYLAND 1
        exec /usr/bin/startplasma-wayland
    end
end
