-- vim: sts=4 ts=4 et
--
local gears      = require("gears")
local awful      = require("awful")
awful.rules      = require("awful.rules")
                   require("awful.autofocus")
local wibox      = require("wibox")
local beautiful  = require("beautiful")
local vicious    = require("vicious")
local naughty    = require("naughty")
local lain       = require("lain")
local cyclefocus = require('cyclefocus')

-- | Theme | --

local theme_name = "pro-dark"
local theme_icons = os.getenv("HOME") .. "/.config/awesome/themes/" .. theme_name .. "/icons/"
local my_icons = os.getenv("HOME") .. "/.config/awesome/icons/"

beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/" .. theme_name .. "/theme.lua")
theme.taglist_bg_empty          = "png:" .. theme_icons .. "/panel/taglist_2/empty.png"
theme.taglist_bg_occupied       = "png:" .. theme_icons .. "/panel/taglist_2/occupied.png"
theme.taglist_bg_urgent         = "png:" .. theme_icons .. "/panel/taglist_2/urgent.png"
theme.taglist_bg_focus          = "png:" .. theme_icons .. "/panel/taglist_2/focus.png"
theme.tasklist_disable_icon     = false
beautiful.widget_cpu            = my_icons .. "cpu.png"
beautiful.widget_mem            = my_icons .. "mem.png"
beautiful.widget_fs             = my_icons .. "hdd.png"
beautiful.widget_ac             = my_icons .. "ac.png"
beautiful.widget_battery_empty  = my_icons .. "battery_empty.png"
beautiful.widget_battery_low    = my_icons .. "battery_low.png"
beautiful.widget_battery        = my_icons .. "battery.png"
beautiful.widget_vol_mute       = my_icons .. "vol_mute.png"
beautiful.widget_vol_no         = my_icons .. "vol_no.png"
beautiful.widget_vol_low        = my_icons .. "vol_low.png"
beautiful.widget_vol            = my_icons .. "vol.png"


-- | Error handling | --

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end

-- | Fix's | --

-- Disable cursor animation:

local oldspawn = awful.util.spawn
awful.util.spawn = function (s)
    oldspawn(s, false)
end

-- Java GUI's fix:

awful.util.spawn_with_shell("wmname LG3D")

-- | Variable definitions | --

local home   = os.getenv("HOME")
local exec   = function (s) oldspawn(s, false) end
local shexec = awful.util.spawn_with_shell

modkey        = "Mod4"
altkey        = "Mod1"
terminal      = "termite"
tmux          = "termite -e tmux"
ncmpcpp       = "urxvt -geometry 254x60+80+60 -e ncmpcpp"
newsbeuter    = "urxvt -g 210x50+50+50 -e newsbeuter"
browser       = "firefox"
filemanager   = "nautilus --no-desktop"

-- | Table of layouts | --

local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top
}

-- | Wallpaper | --

if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.tiled(beautiful.wallpaper, s)
        -- gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end

-- | Tags | --

tags = {}
for s = 1, screen.count() do
    tags[s] = awful.tag({ "  ", "  ", "  ", "  ", "  " }, s, layouts[1])
end

-- | Menu | --

menu_main = {
  { "hibernate", "pm-hibernate"  },
  { "poweroff",  "poweroff"      },
  { "restart",   awesome.restart },
  { "reboot",    "reboot"        },
  { "quit",      awesome.quit    }
}

mainmenu = awful.menu({ items = {
    { " awesome",       menu_main   },
    { " file manager",  filemanager },
    { " terminal",      terminal    }
  }
})

-- | Markup | --

markup = lain.util.markup

space3 = markup.font("Terminus 3", " ")
space2 = markup.font("Terminus 2", " ")
vspace1 = '<span font="Terminus 3"> </span>'
vspace2 = '<span font="Terminus 3">  </span>'
clockgf = beautiful.clockgf

-- | Widgets | --

spr = wibox.widget.imagebox()
spr:set_image(beautiful.spr)
spr4px = wibox.widget.imagebox()
spr4px:set_image(beautiful.spr4px)
spr5px = wibox.widget.imagebox()
spr5px:set_image(beautiful.spr5px)

widget_display = wibox.widget.imagebox()
widget_display:set_image(beautiful.widget_display)
widget_display_r = wibox.widget.imagebox()
widget_display_r:set_image(beautiful.widget_display_r)
widget_display_l = wibox.widget.imagebox()
widget_display_l:set_image(beautiful.widget_display_l)
widget_display_c = wibox.widget.imagebox()
widget_display_c:set_image(beautiful.widget_display_c)

--[[
-- | MPD | --

prev_icon = wibox.widget.imagebox()
prev_icon:set_image(beautiful.mpd_prev)
next_icon = wibox.widget.imagebox()
next_icon:set_image(beautiful.mpd_nex)
stop_icon = wibox.widget.imagebox()
stop_icon:set_image(beautiful.mpd_stop)
pause_icon = wibox.widget.imagebox()
pause_icon:set_image(beautiful.mpd_pause)
play_pause_icon = wibox.widget.imagebox()
play_pause_icon:set_image(beautiful.mpd_play)
mpd_sepl = wibox.widget.imagebox()
mpd_sepl:set_image(beautiful.mpd_sepl)
mpd_sepr = wibox.widget.imagebox()
mpd_sepr:set_image(beautiful.mpd_sepr)

mpdwidget = lain.widgets.mpd({
    settings = function ()
        if mpd_now.state == "play" then
            mpd_now.artist = mpd_now.artist:upper():gsub("&.-;", string.lower)
            mpd_now.title = mpd_now.title:upper():gsub("&.-;", string.lower)
            widget:set_markup(markup.font("Tamsyn 3", " ")
                              .. markup.font("Tamsyn 7",
                              mpd_now.artist
                              .. " - " ..
                              mpd_now.title
                              .. markup.font("Tamsyn 2", " ")))
            play_pause_icon:set_image(beautiful.mpd_pause)
            mpd_sepl:set_image(beautiful.mpd_sepl)
            mpd_sepr:set_image(beautiful.mpd_sepr)
        elseif mpd_now.state == "pause" then
            widget:set_markup(markup.font("Tamsyn 4", "") ..
                              markup.font("Tamsyn 7", "MPD PAUSED") ..
                              markup.font("Tamsyn 10", ""))
            play_pause_icon:set_image(beautiful.mpd_play)
            mpd_sepl:set_image(beautiful.mpd_sepl)
            mpd_sepr:set_image(beautiful.mpd_sepr)
        else
            widget:set_markup("")
            play_pause_icon:set_image(beautiful.mpd_play)
            mpd_sepl:set_image(nil)
            mpd_sepr:set_image(nil)
        end
    end
})

musicwidget = wibox.widget.background()
musicwidget:set_widget(mpdwidget)
musicwidget:set_bgimage(beautiful.widget_display)
musicwidget:buttons(awful.util.table.join(awful.button({ }, 1,
function () awful.util.spawn_with_shell(ncmpcpp) end)))
prev_icon:buttons(awful.util.table.join(awful.button({}, 1,
function ()
    awful.util.spawn_with_shell("mpc prev || ncmpcpp prev")
    mpdwidget.update()
end)))
next_icon:buttons(awful.util.table.join(awful.button({}, 1,
function ()
    awful.util.spawn_with_shell("mpc next || ncmpcpp next")
    mpdwidget.update()
end)))
stop_icon:buttons(awful.util.table.join(awful.button({}, 1,
function ()
    play_pause_icon:set_image(beautiful.play)
    awful.util.spawn_with_shell("mpc stop || ncmpcpp stop")
    mpdwidget.update()
end)))
play_pause_icon:buttons(awful.util.table.join(awful.button({}, 1,
function ()
    awful.util.spawn_with_shell("mpc toggle || ncmpcpp toggle")
    mpdwidget.update()
end)))
]]--


--[[
-- | Mail | --

mail_widget = wibox.widget.textbox()
vicious.register(mail_widget, vicious.widgets.gmail, vspace1 .. "${count}" .. vspace1, 1200)

widget_mail = wibox.widget.imagebox()
widget_mail:set_image(beautiful.widget_mail)
mailwidget = wibox.widget.background()
mailwidget:set_widget(mail_widget)
mailwidget:set_bgimage(beautiful.widget_display)

]]--

-- | CPU / TMP | --

cpu_widget = lain.widgets.cpu({
    settings = function()
        widget:set_markup(space3 .. cpu_now.usage .. "%" .. markup.font("Tamsyn 4", " "))
    end
})

widget_cpu = wibox.widget.imagebox()
widget_cpu:set_image(beautiful.widget_cpu)
cpuwidget = wibox.widget.background()
cpuwidget:set_widget(cpu_widget)
cpuwidget:set_bgimage(beautiful.widget_display)

tmp_widget = wibox.widget.textbox()
vicious.register(tmp_widget, vicious.widgets.thermal, vspace1 .. "$1°C" .. vspace1, 9, "thermal_zone0")

widget_tmp = wibox.widget.imagebox()
widget_tmp:set_image(beautiful.widget_tmp)
tmpwidget = wibox.widget.background()
tmpwidget:set_widget(tmp_widget)
tmpwidget:set_bgimage(beautiful.widget_display)

-- | MEM | --

mem_widget = lain.widgets.mem({
    settings = function()
        widget:set_markup(space3 .. mem_now.used .. " MB" .. markup.font("Tamsyn 4", " "))
    end
})

widget_mem = wibox.widget.imagebox()
widget_mem:set_image(beautiful.widget_mem)
memwidget = wibox.widget.background()
memwidget:set_widget(mem_widget)
memwidget:set_bgimage(beautiful.widget_display)

-- | FS | --

-- /home
--[[
diskbar = awful.widget.progressbar()
diskbar:set_color(beautiful.fg_normal)
diskbar:set_width(25)
diskbar:set_ticks(true)
diskbar:set_ticks_size(6)
diskbar:set_background_color(beautiful.bg_normal)
diskmargin = wibox.layout.margin(diskbar, 2, 2)
diskmargin:set_top(6)
diskmargin:set_bottom(6)

fs_widget = lain.widgets.fs({
    partition = "/home",
    settings  = function()
        if fs_now.used < 90 then
            diskbar:set_color(beautiful.fg_normal)
        else
            diskbar:set_color("#EB8F8F")
        end
        diskbar:set_value(fs_now.used / 100)
    end
})

widget_fs = wibox.widget.textbox()
widget_fs:set_markup(markup.font("Tamsyn 1", " ") .. "/home")
fswidget = wibox.widget.background(diskmargin)
fswidget:set_bgimage(beautiful.widget_display)
fswidget:connect_signal('mouse::enter', function () fs_widget:show(0) end)
fswidget:connect_signal('mouse::leave', function () fs_widget:hide() end)
]] --

--[[
-- /
diskbar_root = awful.widget.progressbar()
diskbar_root:set_color(beautiful.fg_normal)
diskbar_root:set_width(25)
diskbar_root:set_ticks(true)
diskbar_root:set_ticks_size(6)
diskbar_root:set_background_color(beautiful.bg_normal)
diskmargin_root = wibox.layout.margin(diskbar_root, 2, 2)
diskmargin_root:set_top(6)
diskmargin_root:set_bottom(6)

fs_widget_root = lain.widgets.fs({
    partition = "/",
    settings  = function()
        if fs_now.used < 90 then
            diskbar_root:set_color(beautiful.fg_normal)
        else
            diskbar_root:set_color("#EB8F8F")
        end
        diskbar_root:set_value(fs_now.used / 100)
    end
})

-- widget_fs_root = wibox.widget.textbox()
-- widget_fs_root:set_markup(markup.font("Tamsyn 1", " ") .. "/")
widget_fs_root = wibox.widget.imagebox()
widget_fs_root:set_image(beautiful.widget_fs)
fswidget_root = wibox.widget.background(diskmargin_root)
fswidget_root:set_bgimage(beautiful.widget_display)
fswidget_root:connect_signal('mouse::enter', function () fs_widget_root:show(0) end)
fswidget_root:connect_signal('mouse::leave', function () fs_widget_root:hide() end)
]]

--[[
-- | NET | --

net_widgetdl = wibox.widget.textbox()
net_widgetul = lain.widgets.net({
    include_misbehaving_ppp = true,
    settings = function()
        widget:set_markup(markup.font("Tamsyn 1", "  ") .. net_now.sent)
        net_widgetdl:set_markup(markup.font("Tamsyn 1", " ") .. net_now.received .. markup.font("Tamsyn 1", " "))
    end
})

widget_netdl = wibox.widget.imagebox()
widget_netdl:set_image(beautiful.widget_netdl)
netwidgetdl = wibox.widget.background()
netwidgetdl:set_widget(net_widgetdl)
netwidgetdl:set_bgimage(beautiful.widget_display)

widget_netul = wibox.widget.imagebox()
widget_netul:set_image(beautiful.widget_netul)
netwidgetul = wibox.widget.background()
netwidgetul:set_widget(net_widgetul)
netwidgetul:set_bgimage(beautiful.widget_display)
]]--

-- | Clock / Calendar | --
local luatz = require("luatz")
local tzcache = require("luatz.tzcache")
local clocktimer    = require("lain.helpers").newtimer

mytextclock    = wibox.widget.textbox()
function mytextclock.Update()
    local format = "%a %d %b, %H:%M"
    tzcache.clear_tz_cache()
    mytextclock:set_markup(
        markup(clockgf, space3 .. 
            os.date("!"..format, luatz.time_in()) ..
            markup.font("Tamsyn 3", "  ") .. "/" .. markup.font("Tamsyn 3", "  ") ..
            os.date("!%H:%M", luatz.time_in("America/Denver")) ..
            markup.font("Tamsyn 3", " ")
        )
    )
end
clocktimer("textclock", 60, mytextclock.Update)

widget_clock = wibox.widget.imagebox()
widget_clock:set_image(beautiful.widget_clock)

clockwidget = wibox.widget.background()
clockwidget:set_widget(mytextclock)
clockwidget:set_bgimage(beautiful.widget_display)
lain.widgets.calendar:attach(mytextclock, { font_size = 10 })


-- [ Battery ] --
widget_bat = wibox.widget.imagebox(beautiful.widget_battery)
bat_widget = lain.widgets.bat({
    settings = function()
        if bat_now.perc == "N/A" then
            widget:set_markup(markup.font("Tamsyn 1", " AC "))
            widget_bat:set_image(beautiful.widget_ac)
            return
        elseif tonumber(bat_now.perc) <= 5 then
            widget_bat:set_image(beautiful.widget_battery_empty)
        elseif tonumber(bat_now.perc) <= 15 then
            widget_bat:set_image(beautiful.widget_battery_low)
        else
            widget_bat:set_image(beautiful.widget_battery)
        end
        widget:set_markup(space3 .. bat_now.perc .. " %" .. markup.font("Tamsyn 4", " "))
    end
})

batwidget = wibox.widget.background()
batwidget:set_widget(bat_widget)
batwidget:set_bgimage(beautiful.widget_display)

-- [ Volume ] --
local pulseaudio    = require("apw.pulseaudio")
local pulseinstance = pulseaudio:Create()
local pulsemixer    = "pavucontrol"
local pulsetimer    = require("lain.helpers").newtimer

widget_vol = wibox.widget.imagebox(beautiful.widget_vol)
volbar = awful.widget.progressbar()
volbar:set_color(beautiful.fg_normal)
volbar.step = 0.05
volbar:set_width(25)
volbar:set_ticks(true)
volbar:set_ticks_size(2)
volbar:set_background_color(beautiful.bg_normal)
vol_widget = wibox.layout.margin(volbar, 2, 2)
vol_widget:set_top(6)
vol_widget:set_bottom(6)

function _updateVolume()
    if pulseinstance.Mute then
        widget_vol:set_image(beautiful.widget_vol_mute)
        volbar:set_value(0)
    else
        if pulseinstance.Volume  == 0 then
            widget_vol:set_image(beautiful.widget_vol_no)
        elseif pulseinstance.Volume <= 32768 then -- 0.5 * 0x10000
            widget_vol:set_image(beautiful.widget_vol_low)
        else
            widget_vol:set_image(beautiful.widget_vol)
        end
        volbar:set_value(pulseinstance.Volume)
    end
end

function vol_widget.Up()
    pulseinstance:SetVolume(pulseinstance.Volume + volbar.step)
    _updateVolume()
end

function vol_widget.Down()
    pulseinstance:SetVolume(pulseinstance.Volume - volbar.step)
    _updateVolume()
end

function vol_widget.ToggleMute()
    pulseinstance:ToggleMute()
    _updateVolume()
end

function vol_widget.Update()
    pulseinstance:UpdateState()
    _updateVolume()
end

function vol_widget.LaunchMixer()
    awful.util.spawn_with_shell( pulsemixer )
end

-- register mouse button actions
vol_widget:buttons(awful.util.table.join(
    awful.button({ }, 1, vol_widget.ToggleMute),
    awful.button({ }, 3, vol_widget.LaunchMixer),
    awful.button({ }, 4, vol_widget.Up),
    awful.button({ }, 5, vol_widget.Down)
))

widget_vol = wibox.widget.imagebox(beautiful.widget_vol)
volwidget = wibox.widget.background(vol_widget)
volwidget:set_bgimage(beautiful.widget_display)
_updateVolume()
pulsetimer("pulseaudio", 5, vol_widget.Update)

-- | Taglist | --

mytaglist         = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )

-- | Tasklist | --

mytasklist         = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
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

-- | PANEL | --

mywibox           = {}
mypromptbox       = {}
mylayoutbox       = {}

for s = 1, screen.count() do

    mypromptbox[s] = awful.widget.prompt()

    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))

    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    mywibox[s] = awful.wibox({ position = "top", screen = s, height = "22" })

    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(spr5px)
    left_layout:add(mytaglist[s])
    left_layout:add(spr5px)
    left_layout:add(mypromptbox[s])
    left_layout:add(spr5px)

    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then
        right_layout:add(spr)
        right_layout:add(wibox.widget.systray())
        right_layout:add(spr5px)
    end

    -- right_layout:add(spr)

    -- right_layout:add(prev_icon)
    -- right_layout:add(spr)
    -- right_layout:add(stop_icon)
    -- right_layout:add(spr)
    -- right_layout:add(play_pause_icon)
    -- right_layout:add(spr)
    -- right_layout:add(next_icon)
    -- right_layout:add(mpd_sepl)
    -- right_layout:add(musicwidget)
    -- right_layout:add(mpd_sepr)

    right_layout:add(spr)

    -- right_layout:add(widget_mail)
    -- right_layout:add(widget_display_l)
    -- right_layout:add(mailwidget)
    -- right_layout:add(widget_display_r)
    -- right_layout:add(spr5px)

    -- right_layout:add(spr)

    right_layout:add(widget_cpu)
    right_layout:add(widget_display_l)
    right_layout:add(cpuwidget)
    --right_layout:add(widget_display_r)
    right_layout:add(widget_display_c)
    right_layout:add(tmpwidget)
    right_layout:add(widget_tmp)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)

    right_layout:add(spr)

    right_layout:add(widget_mem)
    right_layout:add(widget_display_l)
    right_layout:add(memwidget)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)

    --[[
    right_layout:add(spr)

    right_layout:add(widget_fs)
    right_layout:add(widget_display_l)
    right_layout:add(fswidget)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)
    ]]

    --[[
    right_layout:add(spr)

    right_layout:add(widget_fs_root)
    right_layout:add(widget_display_l)
    right_layout:add(fswidget_root)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)
    ]]


    --[[
    right_layout:add(spr)

    right_layout:add(widget_netdl)
    right_layout:add(widget_display_l)
    right_layout:add(netwidgetdl)
    right_layout:add(widget_display_c)
    right_layout:add(netwidgetul)
    right_layout:add(widget_display_r)
    right_layout:add(widget_netul)
    ]]

    right_layout:add(spr)

    right_layout:add(widget_vol)
    right_layout:add(widget_display_l)
    right_layout:add(volwidget)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)

    right_layout:add(spr)

    right_layout:add(widget_bat)
    right_layout:add(widget_display_l)
    right_layout:add(batwidget)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)
    right_layout:add(spr)

    --right_layout:add(widget_clock)
    right_layout:add(spr5px)
    right_layout:add(widget_display_l)
    right_layout:add(clockwidget)
    right_layout:add(widget_display_r)
    right_layout:add(spr5px)

    right_layout:add(spr)

    right_layout:add(mylayoutbox[s])

    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_bg(beautiful.panel)

    mywibox[s]:set_widget(layout)
end

-- | Mouse bindings | --

root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mainmenu:toggle() end)
    -- awful.button({ }, 4, awful.tag.viewnext),
    -- awful.button({ }, 5, awful.tag.viewprev)
))

-- | Key bindings | --

globalkeys = awful.util.table.join(

    awful.key({ modkey,           }, "w",      function () mainmenu:show() end),
    awful.key({ modkey,           }, "Escape", function () exec("/usr/local/sbin/zaprat --toggle") end),
    awful.key({ modkey            }, "r",      function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    -- awful.key({ modkey,           }, "Tab",
    --     function ()
    --         awful.client.focus.history.previous()
    --         if client.focus then
    --             client.focus:raise()
    --         end
    --     end),
    -- awful.key({ modkey,         }, "Tab", function(c)
    --         cyclefocus.cycle(1, {modifier="Super_L"})
    -- end),
    -- awful.key({ modkey, "Shift" }, "Tab", function(c)
    --         cyclefocus.cycle(-1, {modifier="Super_L"})
    -- end),
    cyclefocus.key({ altkey, }, "Tab", 1, {
        cycle_filters = { cyclefocus.filters.same_screen, cyclefocus.filters.common_tag },
        keys = {'Tab', 'ISO_Left_Tab'}
    }),
    awful.key({ modkey, "Control" }, "r",      awesome.restart),
    awful.key({ modkey, "Shift"   }, "q",      awesome.quit),
    awful.key({ modkey,           }, "Return", function () exec(terminal) end),
    awful.key({ modkey,           }, "t",      function () exec(tmux) end),
    awful.key({ modkey,           }, "space",  function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space",  function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey,           }, "u",      function () exec("urxvt -geometry 254x60+80+60") end),
    awful.key({ modkey,           }, "s",      function () exec(filemanager) end),
    awful.key({ modkey            }, "g",      function () exec("gvim") end),

    awful.key({         }, "XF86AudioMute", vol_widget.ToggleMute),
    awful.key({         }, "XF86AudioLowerVolume", vol_widget.Down),
    awful.key({         }, "XF86AudioRaiseVolume", vol_widget.Up),

    -- Keyboard Backlight
    awful.key({         }, "XF86KbdBrightnessUp",   function () awful.util.spawn("sudo asus-kbd-backlight up") end),
    awful.key({         }, "XF86KbdBrightnessDown", function () awful.util.spawn("sudo asus-kbd-backlight down") end),

    -- Screen Brightness
    awful.key({         }, "XF86MonBrightnessUp",   function () awful.util.spawn("xbacklight -inc 5") end),
    awful.key({         }, "XF86MonBrightnessDown", function () awful.util.spawn("xbacklight -dec 5") end),

    -- Lock workstation
    awful.key({ CONTROL_KEY, "Mod1" }, "l",     function () awful.util.spawn("xscreensaver-command -lock") end )

    -- awful.key({ modkey            }, "Print",  function () exec("screengrab") end),
    -- awful.key({ modkey, "Control" }, "Print",  function () exec("screengrab --region") end),
    -- awful.key({ modkey, "Shift"   }, "Print",  function () exec("screengrab --active") end),
    -- awful.key({ modkey            }, "7",      function () exec("firefox") end),
    -- awful.key({ modkey            }, "8",      function () exec("chromium") end),
    -- awful.key({ modkey            }, "9",      function () exec("dwb") end),
    -- awful.key({ modkey            }, "0",      function () exec("thunderbird") end),
    -- awful.key({ modkey            }, "'",      function () exec("leafpad") end),
    -- awful.key({ modkey            }, "\\",     function () exec("sublime_text") end),
    -- awful.key({ modkey            }, "i",      function () exec("gcolor2") end),
    -- awful.key({ modkey            }, "`",      function () exec("xwinmosaic") end),
    -- awful.key({ modkey, "Control" }, "m",      function () shexec(ncmpcpp) end),
    -- awful.key({ modkey, "Control" }, "f",      function () shexec(newsbeuter) end),
    -- awful.key({ modkey            }, "Pause",  function () exec("VirtualBox --startvm 'a8d5ac56-b0d2-4f7f-85be-20666d2f46df'") end)
    -- awful.key({ modkey }, "x",
    --           function ()
    --               awful.prompt.run({ prompt = "Run Lua code: " },
    --               mypromptbox[mouse.screen].widget,
    --               awful.util.eval, nil,
    --               awful.util.getdir("cache") .. "/history_eval")
    --           end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey            }, "Next",   function () awful.client.moveresize( 20,  20, -40, -40) end),
    awful.key({ modkey            }, "Prior",  function () awful.client.moveresize(-20, -20,  40,  40) end),
    awful.key({ modkey            }, "Down",   function () awful.client.moveresize(  0,  20,   0,   0) end),
    awful.key({ modkey            }, "Up",     function () awful.client.moveresize(  0, -20,   0,   0) end),
    awful.key({ modkey            }, "Left",   function () awful.client.moveresize(-20,   0,   0,   0) end),
    awful.key({ modkey            }, "Right",  function () awful.client.moveresize( 20,   0,   0,   0) end),
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,           }, "n",
        function (c)
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
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
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

awful.menu.menu_keys = {
    up    = { "k", "Up" },
    down  = { "j", "Down" },
    exec  = { "l", "Return", "Space" },
    enter = { "l", "Right" },
    back  = { "h", "Left" },
    close = { "q", "Escape" }
}

root.keys(globalkeys)

-- | Rules | --
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     size_hints_honor = false,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "VLC" },
      properties = { floating = true } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "mplayer2" },
      properties = { floating = true } },
    { rule = { class = "mpv" },
      properties = { floating = true } },
    { rule = { class = "CrashPlan" },
      properties = { floating = true } },
    { rule = { name = "calibre - Preferences" },
      properties = { floating = true } },
    { rule = { class = "Calibre-ebook-viewer" },
      properties = { floating = true } },
    { rule = { class = "Linphone" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "Pavucontrol" },
      properties = { floating = true } },
    { rule = { name = "Firefox Preferences" },
      properties = { floating = true } },
    { rule = { name = "About Mozilla Firefox" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Gimp" },
      properties = { floating = true } },
    { rule = { class = "Steam" },
      properties = { floating = true } },
    { rule = { class = "VirtualBox" },
      properties = { floating = true } },
    { rule = { class = "Virtualbox" },
      properties = { floating = true } },
    { rule = { class = "feh" },
      properties = { floating = true } },
    { rule = { name = "StreamTorrent" },
      properties = { floating = true } },
    { rule = { name = "AutoKey" },
      properties = { floating = true } },
    { rule = { class = "Remmina" },
      properties = { floating = true } },
    { rule = { class = "Transmission-gtk" },
      properties = { floating = true } },
    { rule = { class = "com-sun-javaws-Main" },
      properties = { floating = true } },
    { rule = { class = "Systemsettings" },
      properties = { floating = true } },
    { rule = { class = "Lxappearance" },
      properties = { floating = true } },
    { rule = { class = "Skype" },
      properties = { floating = true } },
    { rule = { class = "Thunderbird" },
      properties = { floating = true } },
    { rule = { class = "Pidgin" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- | Signals | --

client.connect_signal("manage", function (c, startup)
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
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

        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- | run_once | --

function run_once(cmd)
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
    'setxkbmap -model pc101 -layout pt,us',
    'xscreensaver -no-splash',
    'xcompmgr',
    'xrdb -merge ~/.Xresources',
    'nm-applet',
    'numlockx on'
}

for _,i in pairs(cmds) do
    run_once(i)
end


