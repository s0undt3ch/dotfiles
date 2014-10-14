-- vim: sts=4 ts=4 et

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local vicious = require("vicious")
vicious.contrib = require("vicious.contrib")
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}


-- Define special keys as variables
MOD_SUPER = 'Mod4'
MOD_ALT = 'Mod1'
SUPER_KEY = 'Mod4'
SHIFT_KEY = 'Shift'
CONTROL_KEY = 'Control'
ALT_KEY = 'Alt'

-- Enable hostname discovery
local socket = require("socket")
hostname = socket.dns.gethostname()

-- Autorun apps
function run_once(prg)
    print(prg)
    awful.util.spawn_with_shell("ps -u $USER -o command | egrep -q '^" .. prg .. "$' || (" .. prg .. ")")
end

-- Wibox separator and space
--separator = widget({ type = "textbox", align = "left"})
--separator.text = ' || '
separator = wibox.widget.textbox()
separator:set_text(' // ')
space = wibox.widget.textbox()
space:set_text(' ')

if hostname == 'arched' then
    do
        local cmds = {
            'setxkbmap -model pc101 -layout pt,us',
            'xscreensaver -no-splash',
            'xcompmgr',
            'xrdb -merge ~/.Xresources',
            'nm-applet',
            'feh --bg-max ~/Downloads/KDE/linux-arch.png'
        }

        for _,i in pairs(cmds) do
            run_once(i)
        end
    end
    batname = 'BAT0'
else
    batname = nil
end


-- batwidget = wibox.widget.textbox()
--
-- if batname == nil then
-- else
--    vicious.register(batwidget, vicious.widgets.bat, "Bat: $1$2% ($3)", 5, batname)
-- end
--
-- require("obvious.cpu")
-- require("obvious.mem")
require("obvious.battery")

-- Date/time widget
datewidget = wibox.widget.textbox()
vicious.register(datewidget, vicious.widgets.date, "%a, %d %b %Y, %H:%M:%S ", 1)


-- Memory widget
memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem, "Mem: $1%", 13)

-- PulseAudio widget
pulsewidget = wibox.widget.textbox()
vicious.register(pulsewidget, vicious.contrib.pulse, "Vol: $1%", 2)


-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
theme_name = os.getenv("AWESOME_THEME") or 'arch'
beautiful.init("/usr/share/awesome/themes/" .. theme_name .. "/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "termite"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Applications Menu
require('freedesktop.utils')
freedesktop.utils.terminal = terminal
freedesktop.utils.icon_theme = 'gnome'
require('freedesktop.menu')

menu_items = freedesktop.menu.new()


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome", freedesktop.utils.lookup_icon({ icon = 'help' }) },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

table.insert(menu_items, { "awesome", myawesomemenu, beautiful.awesome_icon })
table.insert(menu_items, { "open terminal", terminal, freedesktop.utils.lookup_icon({icon = 'terminal'}) })
mymainmenu = awful.menu({ items = menu_items, width = 150 })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- desktop icons
-- require('freedesktop.desktop')
-- for s = 1, screen.count() do
--     freedesktop.desktop.add_applications_icon({screen = s, showlabels = true})
--     freedesktop.desktop.add_dirs_and_files_icon({screen = s, showlabels = true})
-- end
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ MOD_SUPER }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ MOD_SUPER }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then
        right_layout:add(wibox.widget.systray())
    end
    right_layout:add(separator)
    right_layout:add(obvious.battery())
    right_layout:add(space)
    -- right_layout:add(obvious.mem())
    -- right_layout:add(obvious.cpu())
    right_layout:add(space)
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ MOD_SUPER,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ MOD_SUPER,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ MOD_SUPER,           }, "Escape", awful.tag.history.restore),

    awful.key({ MOD_SUPER,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ MOD_SUPER,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ MOD_SUPER,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ MOD_SUPER, SHFIT_KEY   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ MOD_SUPER, SHFIT_KEY   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ MOD_SUPER, CONTROL_KEY }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ MOD_SUPER, CONTROL_KEY }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ MOD_SUPER,           }, "u", awful.client.urgent.jumpto),
    awful.key({ MOD_SUPER,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise() end
        end),

    -- Standard program
    awful.key({ MOD_SUPER,              }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ MOD_SUPER, CONTROL_KEY  }, "r", awesome.restart),
    awful.key({ MOD_SUPER, SHFIT_KEY    }, "q", awesome.quit),

    awful.key({ MOD_SUPER,              }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ MOD_SUPER,              }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ MOD_SUPER, SHFIT_KEY    }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ MOD_SUPER, SHFIT_KEY    }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ MOD_SUPER, CONTROL_KEY  }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ MOD_SUPER, CONTROL_KEY  }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ MOD_SUPER,              }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ MOD_SUPER, SHFIT_KEY    }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ MOD_SUPER, CONTROL_KEY  }, "n", awful.client.restore),

    -- Prompt
    awful.key({ MOD_ALT                 }, "F2",    function () mypromptbox[mouse.screen]:run() end),

    awful.key({ MOD_SUPER }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- PulseAudio Volume
    -- awful.key({         }, "XF86AudioMute", function () awful.util.spawn('amixer -c 0 -q set Master toggle') end),
    -- awful.key({         }, "XF86AudioLowerVolume", function () awful.util.spawn('amixer -c 0 -q set Master 2dB-') end),
    -- awful.key({         }, "XF86AudioRaiseVolume", function () awful.util.spawn('amixer -c 0 -q set Master 2dB+') end),

   -- PulseAudio Volume
   awful.key({         }, "XF86AudioMute", function () awful.util.spawn('pulseaudio-ctl mute') end),
   awful.key({         }, "XF86AudioLowerVolume", function () awful.util.spawn('pulseaudio-ctl down') end),
   awful.key({         }, "XF86AudioRaiseVolume", function () awful.util.spawn('pulseaudio-ctl up') end),

    -- Keyboard Backlight
    awful.key({         }, "XF86KbdBrightnessUp",   function () awful.util.spawn("sudo asus-kbd-backlight up") end),
    awful.key({         }, "XF86KbdBrightnessDown", function () awful.util.spawn("sudo asus-kbd-backlight down") end),

    -- Screen Brightness
    awful.key({         }, "XF86MonBrightnessUp",   function () awful.util.spawn("xbacklight -inc 5") end),
    awful.key({         }, "XF86MonBrightnessDown", function () awful.util.spawn("xbacklight -dec 5") end),

    -- Lock workstation
    awful.key({ CONTROL_KEY, "Mod1" }, "l",     function () awful.util.spawn("xscreensaver-command -lock") end )
)

clientkeys = awful.util.table.join(
    awful.key({ MOD_SUPER,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ MOD_SUPER, SHFIT_KEY   }, "c",      function (c) c:kill()                         end),
    awful.key({ MOD_SUPER, CONTROL_KEY }, "space",  awful.client.floating.toggle                     ),
    awful.key({ MOD_SUPER, CONTROL_KEY }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ MOD_SUPER,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ MOD_SUPER,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ MOD_SUPER,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ MOD_SUPER,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ MOD_SUPER }, "F" .. i,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ MOD_SUPER, CONTROL_KEY }, "F" .. i,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ MOD_SUPER, SHFIT_KEY }, "F" .. i,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ MOD_SUPER, CONTROL_KEY, SHFIT_KEY }, "F" .. i,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ MOD_SUPER }, 1, awful.mouse.client.move),
    awful.button({ MOD_SUPER }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
