# Print a new line after any command
# https://stackoverflow.com/a/70644608
function postexec_newline --on-event fish_postexec
   echo
end
