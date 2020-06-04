-------------------------------------------------------------------------------
-- rc.lua for Awesome Configuration                                          --
-- Copyright (c) 2017 Tom Hartman (thomas.lees.hartman@gmail.com)            --
--                                                                           --
-- This program is free software; you can redistribute it and/or             --
-- modify it under the terms of the GNU General Public License               --
-- as published by the Free Software Foundation; either version 2            --
-- of the License, or the License, or (at your option) any later             --
-- version.                                                                  --
--                                                                           --
-- This program is distributed in the hope that it will be useful,           --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of            --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             --
-- GNU General Public License for more details.                              --
-------------------------------------------------------------------------------

--- Commentary -- {{{
-- Awesome configuration. The default rc.lua located in
-- /etc/xdg/awesome was used as the template for this file.
-- }}}

--- Code -- {{{

--- Libraries -- {{{{
-- Standard awesome library
local gears     = require("gears"           )
local gtable    = require("gears.table"     )
local awful     = require("awful"           )
awful.rules     = require("awful.rules"     )
                  require("awful.autofocus" )
-- Widget and layout library
local wibox     = require("wibox"           )
-- Theme handling library
local beautiful = require("beautiful"       )
-- Notification library
local naughty   = require("naughty"         )
local menubar   = require("menubar"         )

-- Widget Libraries
package.path    = '/home/thartman/.config/awesome/widgets/?.lua;' .. package.path
local pass      = require("widgets.awesome-pass"     )
local bat       = require("widgets.awesome-battery"  )
-- }}}

--- Error handling -- {{{
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

--- Variable definitions -- {{{
local home_path = '/home/' .. os.getenv('USER')
local awesome_path = home_path .. '/.config/awesome/'

-- Themes define colours, icons, font and wallpapers.
beautiful.init(awesome_path .. 'theme.lua')

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

--- Autorun -- {{{
autorun = true
autorunProgs = {
   "xcompmgr -f -c -s"
}

if autorun then
   for _,v in ipairs(autorunProgs) do
      awful.util.spawn(v)
   end
end

-- }}}

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts = {
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

local wibox_args = {
   ontop        = false,
   screen       = s,
   height       = beautiful.wibar_height or beautiful.default_height,
   bg           = beautiful.wibar_bg or beautiful.bar_bg_normal or beautiful.bg_normal,
   fg           = beautiful.wibar_fg,
   border_width = beautiful.wibar_border_width,
   border_color = beautiful.wibar_border_color,
}

-- }}}

--- Tools -- {{{
local tools = {}

tools.terminal           = 'urxvt'
tools.compmgr_cmd        = 'xcompmgr'
tools.compmgr_cmdopts    = '-f -c -s'
tools.filemanager_cmd    = 'mc'
tools.browser_cmd        = os.getenv('BROWSER') or 'firefox'
tools.editor_cmd         = os.getenv('EDITOR') or 'et'
tools.screenlock_cmd     = 'xscreensaver-command'
tools.screenlock_cmdopts = '-l'
tools.background_cmd     = 'nitrogen'
tools.background_cmdopts = '--restore'

-- }}}

--- Tags -- {{{
-- Define a tag table which hold all screen tags.
mytags = {}

-- Multi screen (desktop) tags
mytags.desktop = {}
mytags.desktop[1] = { "surf", "watch", "play", "create", "monitor" }
mytags.desktop[2] = { "chat", "read", "listen", "system" }
mytags.desktop[3] = { "code", "debug" }

-- Single screen (laptop) tags
mytags.laptop  = {}
mytags.laptop[1] = {"chat","code","read","surf","watch","listen",
                    "create","system","monitor"}

if screen.count() == 3 then
   mytags.tags = mytags.desktop
else
   mytags.tags = mytags.laptop
end

-- }}}

--- Widgets -- {{{
mywidgets = {}

-- layoutbox
local sep = wibox.widget { markup = " | ", align = "center", valign = "center",
                           widget = wibox.widget.textbox }

mywidgets.desktop    = { }
mywidgets.desktop[1] = { sep, pass(), sep, wibox.widget.textclock(),
                         sep, mylayoutbox,
                         layout = wibox.layout.fixed.horizontal }
mywidgets.desktop[2] = { mylayoutbox, layout = wibox.layout.fixed.horizontal }
mywidgets.desktop[3] = { mylayoutbox, layout = wibox.layout.fixed.horizontal }

mywidgets.laptop     = { }
mywidgets.laptop[1]  = { pass(), sep, wibox.widget.textclock(),
                         sep, mylayoutbox,
                         layout = wibox.layout.fixed.horizontal }

if screen.count() > 1 then
   mywidgets.widgets = mywidgets.desktop
else   
   mywidgets.widgets = mywidgets.laptop
end
-- }}}

--- Screens -- {{{
mypromptbox = {}
local wibox_top = {}
local wibox_bot = {}

--- TagList -- {{{
mytaglistbuttons = awful.util.table.join(
   awful.button({ }, 1, awful.tag.viewonly),
   awful.button({ modkey }, 1, awful.client.movetotag),
   awful.button({ }, 3, awful.tag.viewtoggle),
   awful.button({ modkey }, 3, awful.client.toggletag),
   awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
   awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)

-- }}}

--- Tasklist -- {{{
mytasklistbuttons = awful.util.table.join(
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
-- }}}

--- connect_for_each_screen -- {{{
awful.screen.connect_for_each_screen(function (s)      
      -- Tags
      awful.tag(mytags.tags[s.index], s, layouts)
      
      -- Prompt box
      mypromptbox[s] = awful.widget.prompt()

      -- taglist
      local taglist = awful.widget.taglist(s, awful.widget.taglist.filter.all,
                                           mytaglistbuttons)
      
      -- tasklist
      local mytasklist =
         awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags,
                               mytasklistbuttons)      
      
      -- Put it all together in a wibox
      wibox_top[s] = awful.wibar(setmetatable({ position = "top", screen = s},
                                    {__index=wibox_args}))

      local mylayouts = awful.widget.layoutbox(s)
      mylayouts:buttons(
         awful.util.table.join(
            awful.button({ }, 1, function () awful.layout.inc(1, s, layouts) end),
            awful.button({ }, 3, function () awful.layout.inc(-1, s, layouts) end),
            awful.button({ }, 4, function () awful.layout.inc(1, s, layouts) end),
            awful.button({ }, 5, function () awful.layout.inc(-1, s, layouts) end)))

      table.insert(mywidgets.widgets[s.index], mylayouts)

      wibox_top[s]:setup {
         layout = wibox.layout.align.horizontal,
         { -- Left side
            taglist,
            mypromptbox[s],
            layout = wibox.layout.fixed.horizontal
         },
         nil, -- Nothing in the middle

         -- right side
         mywidgets.widgets[s.index]
      }
      
      wibox_bot[s] = awful.wibar(setmetatable({ position = "bottom", screen = s},
                                    {__index=wibox_args}))

      wibox_bot[s]:setup {
         mytasklist,
         layout = wibox.layout.flex.horizontal
      }      
end)
-- }}}

--- Wallpaper -- {{{
awful.spawn(beautiful.wallpaper_cmd)
-- }}}

-- }}}

--- Menu -- {{{
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", tools.terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end }
}

mymainmenu = awful.menu({
      items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
         { "open terminal", tools.terminal }
      }
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
-- Set the terminal for applications that require it
menubar.utils.terminal = tools.terminal
-- }}}

--- Mouse bindings -- {{{
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

--- Key bindings -- {{{
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

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
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j",
       function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k",
       function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j",
       function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k",
       function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return",
       function () awful.util.spawn(tools.terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),
    awful.key({ modkey,           }, "l",
       function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",
       function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",
       function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",
       function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",
       function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",
       function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space",
       function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space",
       function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",
       function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
   awful.key({ modkey,           }, "f",
      function (c) c.fullscreen = not c.fullscreen  end),
   awful.key({ modkey, "Shift"   }, "c",
      function (c) c:kill() end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),
    awful.key({ modkey, "Control" }, "Return",
       function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen),
    awful.key({ modkey,           }, "t",
       function (c) c.ontop = not c.ontop end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
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
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
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

-- Set keys
root.keys(globalkeys)
-- }}}

--- Rules -- {{{
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

--- Signals -- {{{
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Give the new client focus
    c.screen = mouse.screen
    client.focus = c
                         
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end                         
                      
                         
    local titlebars_enabled = true
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

-- Enable sloppy focus
client.connect_signal("mouse::enter", function(c)
   if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
       and awful.client.focus.filter(c) then
          client.focus = c
   end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- }}}
