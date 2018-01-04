# Start X at login
if status --is-login
    if test -z "$DISPLAY" -a $XDG_VTNR -lt 2
        # If this is not an SSH seesion and the TTY number is less than 2, then startx
        exec startx -- -keeptty
    end
end
