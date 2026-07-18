# Fingerprint auth on Arch Linux

Setup notes for `fprintd` / `libfprint` fingerprint authentication on Arch Linux.

> **Not chezmoi-tracked.** Everything here lives under `/etc/pam.d/` (root-owned system config), so
> `chezmoi apply` does **not** manage or restore it. Redo these steps by hand after a reinstall or a
> new laptop.

## Reference hardware

Originally set up on:

- **Laptop**: Lenovo ThinkPad P16v Gen 1 (`21FECTO1WW`)
- **Sensor**: Synaptics, USB ID `06cb:0126` (match-on-chip, "press" type)
- **Stack**: `fprintd` + `libfprint`, KDE Plasma 6 (Wayland), console/TTY login (no display manager)

Other Synaptics/Goodix ThinkPad sensors work the same way as long as `libfprint` supports the USB
ID. If enrollment fails, check the [libfprint supported devices][libfprint-devices] list against your
`lsusb` output.

## 1. Install and enroll

```bash
# add `fprintd` to home/dot_config/metapac/groups/arch.toml, then:
chezmoi apply          # runs `metapac sync`

fprintd-enroll         # enroll a finger (repeat the swipe/press until complete)
fprintd-list "$USER"   # verify the enrolled finger(s)
```

## 2. Wire up PAM

Each auth point is a separate PAM service. Add `pam_fprintd.so` as `sufficient` **above** the
existing `include` line so a fingerprint match short-circuits, and a miss/timeout falls through to
the password.

> **Keep a root shell open while testing** (`sudo -s` in a spare terminal). A broken PAM auth stack
> can lock you out of `sudo` and login. Every command below writes a `.bak` (or creates a new file)
> so you can roll back.

### sudo

```bash
sudo sed -i.bak '1a auth      sufficient  pam_fprintd.so' /etc/pam.d/sudo
```

### TTY / console login

The console login prompt uses `system-local-login`:

```bash
sudo sed -i.bak '1a auth      sufficient  pam_fprintd.so' /etc/pam.d/system-local-login
```

### polkit (GUI "authentication required" dialogs)

Arch ships polkit's PAM config as a vendor file at `/usr/lib/pam.d/polkit-1`. Shadow it with an
`/etc/pam.d/polkit-1` override (which takes precedence) that adds fingerprint on top:

```bash
sudo cp /usr/lib/pam.d/polkit-1 /etc/pam.d/polkit-1
sudo sed -i '1a auth      sufficient  pam_fprintd.so' /etc/pam.d/polkit-1
```

> **Caveat**: because `/etc` now shadows the vendor file, a future `polkit` update that changes its
> PAM defaults won't reach this copy (no `.pacnew` for vendor files). polkit's PAM stack rarely
> changes, so this is low-risk — just re-diff against `/usr/lib/pam.d/polkit-1` after major updates.

### KDE lock screen — nothing to do

Plasma 6's `kscreenlocker` has native fingerprint support: it ships `/usr/lib/pam.d/kde-fingerprint`
(which uses `pam_fprintd.so`) and the greeter runs it in parallel with the password path. No file to
create — just lock and swipe.

## 3. Verify

```bash
sudo -k; sudo true     # prompts for a finger, falls back to password
pkexec true            # polkit dialog accepts a finger
loginctl lock-session  # lock screen, then unlock with a swipe
```

Log out to a TTY and log back in with a swipe to confirm console login. Once `sudo` still
authenticates (finger **or** password), the stack is sound and you can close the root shell.

## Summary

| Auth point         | PAM service / file               | Action                                      |
|--------------------|----------------------------------|---------------------------------------------|
| `sudo`             | `/etc/pam.d/sudo`                | add `pam_fprintd.so`                         |
| TTY / console login| `/etc/pam.d/system-local-login`  | add `pam_fprintd.so`                         |
| polkit dialogs     | `/etc/pam.d/polkit-1`            | `/etc` override of vendor file + `pam_fprintd.so` |
| KDE lock screen    | `/usr/lib/pam.d/kde-fingerprint` | none — native in Plasma 6                    |

## Rollback

```bash
sudo mv /etc/pam.d/sudo.bak /etc/pam.d/sudo
sudo mv /etc/pam.d/system-local-login.bak /etc/pam.d/system-local-login
sudo rm /etc/pam.d/polkit-1   # reverts to the vendor file in /usr/lib/pam.d/
```

[libfprint-devices]: https://fprint.freedesktop.org/supported-devices.html
