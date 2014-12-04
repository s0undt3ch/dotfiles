-- vim: ts=4 sts=4 et

local awful      = require("awful")

local initapps = {}

function initapps.run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

-- | Autostart | --

-- os.execute("pkill compton")
-- os.execute("setxkbmap -layout 'us,ua' -variant 'winkeys' -option 'grp:caps_toggle,grp_led:caps,compose:menu' &")
-- run_once("parcellite")
-- run_once("kbdd")
-- run_once("compton")
local cmds = {
    'setxkbmap -model pc101 -layout pt',
    'xscreensaver -no-splash',
    'xcompmgr',
    'xrdb -merge ~/.Xresources',
    'nm-applet',
    'numlockx on',
    'redshift -l 38.9079180:-9.0514060',
    'keepass'
}

function initapps.init()
    for _,i in pairs(cmds) do
        initapps.run_once(i)
    end
end

return initapps

