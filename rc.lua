local gears         = require("gears"                    )
local gtable        = require("gears.table"              )
local awful         = require("awful"                    )
                      require("awful.autofocus"          )
local hotkeys_popup = require("awful.hotkeys_popup.keys" )
local wibox         = require("wibox"                    )
local beautiful     = require("beautiful"                )
local naughty       = require("naughty"                  )
local ruled         = require("ruled"                    )
local menubar       = require("menubar"                  )
local io            = require("io"                       )
local dpi           = require("beautiful.xresources"     ).apply_dpi

naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened"..(startup and " during startup! Falling back!" or "!"),
        message = message
    }
end)

local conf_dir = gears.filesystem.get_configuration_dir()

local themeName = "copland"
beautiful.init(conf_dir .. "/themes/" .. themeName .. "/theme.lua")

bling = require('bling')

local weather           = require("awesome-wm-widgets.weather-widget.weather"    )
local cpu_widget        = require("awesome-wm-widgets.cpu-widget.cpu-widget"     )
local ram_widget        = require("awesome-wm-widgets.ram-widget.ram-widget"     )
local volume_widget     = require("awesome-wm-widgets.volume-widget.volume"      )
local spotify_widget    = require("awesome-wm-widgets.spotify-widget.spotify"    )
local docker_widget     = require("awesome-wm-widgets.docker-widget.docker"      )
local calendar_widget   = require("awesome-wm-widgets.calendar-widget.calendar"  )
local net_speed         = require("awesome-wm-widgets.net-speed-widget.net-speed")
local secrets           = require("secrets"                                      )

local machi = require("layout-machi")

local lain = require("lain")

--terminal = config.user.terminal --"kitty" --"urxvt"
terminal   = "urxvt"
editor     = os.getenv("EDITOR") or "emacsclient -nc"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"
altkey  = "Mod1"
ctrlkey = "Control"
shiftkey = "Shift"

local defaultlayouts = {
   awful.layout.suit.tile,
   awful.layout.suit.floating,
--   lain.layout.centerwork,
--   lain.layout.termfair.center,
   awful.layout.suit.spiral,
   awful.layout.suit.magnifier,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
--   machi.layout.create{ new_placement_cb = machi.layout.placement.empty_then_fair },
   awful.layout.suit.tile.bottom,
   machi.default_layout,
}

tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts(defaultlayouts)
end)

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = dpi(2)
lain.layout.cascade.tile.offset_y      = dpi(32)
lain.layout.cascade.tile.extra_padding = dpi(5)
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

--- Tags -- {{{
-- Define a tag table which hold all screen tags.
mytags = {}

-- Multi screen (desktop) tags
mytags.desktop = {}
mytags.desktop[1] = { "surf", "code", "play", "watch", "create" }
mytags.desktop[2] = { "chat", "read", "listen", "system" }
mytags.desktop[3] = { "monitor", "debug" }

-- Single screen (laptop) tags
mytags.laptop  = {}
mytags.laptop[1] = {"chat","code","read","surf","watch","listen",
                    "create","system","monitor"}

-- Dual Screen (laptop) tags
mytags.laptopExt = {}
mytags.laptopExt[1] = {"chat","code","read","surf","watch","listen",
                    "create"}
mytags.laptopExt[2] = {"debug","monitor","system"}

-- check the number of screens to determine if we are on the desktop or laptop
if screen.count() == 3 then
   mytags.tags = mytags.desktop
elseif screen.count() == 2 then
   mytags.tags = mytags.laptopExt
else
   mytags.tags = mytags.laptop
end

--- Widgets -- {{{
mywidgets = {}

local sep = wibox.widget { markup = "  ", align = "center", valign = "center",
                           widget = wibox.widget.textbox }

local cpu = cpu_widget({
         width = 70,
         step_width = 2,
         step_spacing = 0,
         color = '#434c5e'})

local ram = ram_widget{
   widget_show_buf = false
}

mytextclock = wibox.widget.textclock()

local cw = calendar_widget({
    theme = 'outrun',
    placement = 'top_right',
    start_sunday = true,
    radius = 8,
-- with customized next/previous (see table above)
    previous_month_button = 1,
    next_month_button = 3,
})

mytextclock:connect_signal("button::press",
    function(_, _, _, button)
        if button == 1 then cw.toggle() end
    end)

local vol = volume_widget({
      widget_type = "arc"
      })

local spotify = spotify_widget({
      dim_when_paused = true,
      dim_opacity = 0.5,
      max_length = -1,
      font = beautiful.font
})

local netspeed = net_speed()

local docker = docker_widget()

local weather = weather({
      api_key = secrets.weather_api_key,
      coordinates = { secrets.latitude, secrets.longitude},
      time_format_12h = true,
      units = 'imperial',
      both_units_widget = false,
      font_name = 'Carter One',
      icons = 'weather-underground-icons',
      show_hourly_forecast = true,
      show_daily_forecast = true,
      icons_extension = '.png'
})

mywidgets.desktop    = { }
mywidgets.desktop[1] = {
   spotify,
   sep,
   docker,
   sep,
   vol,
   netspeed,
   cpu,
   sep,
   ram,
   sep,
   weather,
   sep,
   mytextclock,
   mylayoutbox,
   layout = wibox.layout.fixed.horizontal }
mywidgets.desktop[2] = { mylayoutbox, layout = wibox.layout.fixed.horizontal }
mywidgets.desktop[3] = { mylayoutbox, layout = wibox.layout.fixed.horizontal }

mywidgets.laptop     = { }
mywidgets.laptop[1]  = {
   spotify,
   sep,
   docker,
   sep,
   vol,
   netspeed,
   cpu,
   sep,
   ram,
   sep,
   weather,
   sep,
   mytextclock,
   mylayoutbox,
   layout = wibox.layout.fixed.horizontal }
-- }}}

if screen.count() > 1 then
   mywidgets.widgets = mywidgets.desktop
else
   mywidgets.widgets = mywidgets.laptop
end

--- connect_for_each_screen -- {{{
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

awful.screen.connect_for_each_screen(function (s)
      -- Tags
      awful.tag(mytags.tags[s.index], s, defaultlayouts)

      -- Prompt box
      s.mypromptbox = awful.widget.prompt()

      -- quake termainl
      s.quake = lain.util.quake({ app = terminal })

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
            s.mypromptbox,
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

awful.mouse.append_global_mousebindings({
--    awful.button({}, 3, function() main_menu:toggle(nil, { source = "mouse" }) end),
    awful.button({}, 4, awful.tag.viewprev),
    awful.button({}, 5, awful.tag.viewnext),
    awful.button({ modkey, altkey }, 4, function ()
        os.execute(string.format("amixer -q set %s 5%%+", beautiful.volume.channel))
        beautiful.volume.update()
    end),
    awful.button({ modkey, altkey }, 5, function ()
        os.execute(string.format("amixer -q set %s 5%%-", beautiful.volume.channel))
        beautiful.volume.update()
    end),
})

awful.keyboard.append_global_keybindings({
    -- awful.key({ modkey, ctrlkey }, "s", hotkeys_popup.show_help,
    --           {description="show help", group="awesome"}),
    -- awful.key({ modkey }, "w", function () main_menu:toggle(nil, { source = "mouse" }) end,
    --           {description = "show main menu", group = "awesome"}),
    -- awful.key({ modkey }, "q", function () fishlive.widget.exit_screen() end,
    --           {description = "exit screen", group = "awesome"}),
    awful.key({ modkey }, "c", function () beautiful.menu_colorschemes_create():toggle() end,
              {description = "show colorschemes menu", group = "awesome"}),
    awful.key({ modkey }, "x", function () beautiful.menu_portrait_create():toggle() end,
              {description = "show portrait menu for love tag", group = "awesome"}),
    awful.key({ modkey }, "a", function () awful.spawn("clipmenu") end,
              {description = "clipboard history by rofi/clipmenud", group = "awesome"}),
    awful.key({ modkey }, "l", function() awful.menu.client_list { theme = { width = 250 } } end,
              {description="show client list", group="awesome"}),
    awful.key({ modkey, ctrlkey }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey, ctrlkey }, "x", function ()
        awful.prompt.run {
            prompt       = "Run Lua code: ",
            textbox      = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval"
        }
        end,
        {description = "lua execute prompt", group = "awesome"}),
    awful.key({ modkey }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal (alacritty)", group = "launcher"}),
    awful.key({ modkey, altkey }, "Return", function () awful.spawn(terminal2) end,
              {description = "open a terminal2 (wezterm)", group = "launcher"}),
    awful.key({ modkey }, "r", function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),
    awful.key({ modkey }, "`", function () awful.screen.focused().quake:toggle() end,
       { description = "open the quake terminal", group = "launcher"}),
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the d-menu", group = "launcher"}),
})

-- Tags related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey }, "Left", awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey }, "Right",awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
})

-- Focus related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey }, "j", function () awful.client.focus.byidx(1) end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey }, "k", function () awful.client.focus.byidx(-1) end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey }, "Tab", function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
    awful.key({ modkey, ctrlkey }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, ctrlkey }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey, ctrlkey }, "n", function ()
              local c = awful.client.restore()
              -- Focus restored client
              if c then
                c:activate { raise = true, context = "key.unminimize" }
              end
          end,
          {description = "restore minimized", group = "client"}),
})

-- Tabbed related keybindings
awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { modkey, ctrlkey },
        keygroup    = "numpad",
        description = "tabbed features",
        group       = "client",
        on_press    = function(index)
            if index == 1 then bling.module.tabbed.pick_with_dmenu()
            elseif index == 2 then bling.module.tabbed.pick_by_direction("down")
            elseif index == 4 then bling.module.tabbed.pick_by_direction("left")
            elseif index == 5 then bling.module.tabbed.iter()
            elseif index == 6 then bling.module.tabbed.pick_by_direction("right")
            elseif index == 7 then bling.module.tabbed.pick()
            elseif index == 8 then bling.module.tabbed.pick_by_direction("up")
            elseif index == 9 then bling.module.tabbed.pop()
            end
        end
    },
})

-- Layout related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey, "Shift" }, "j", function () awful.client.swap.byidx(1) end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift" }, "k", function () awful.client.swap.byidx(-1) end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey }, "l", function () awful.tag.incmwfact( 0.05) end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey }, "h", function () awful.tag.incmwfact(-0.05) end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, ctrlkey }, "h", function () awful.tag.incncol( 1, nil, true) end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, ctrlkey }, "l", function () awful.tag.incncol(-1, nil, true) end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey }, "space", function () awful.layout.inc( 1) end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(-1) end,
              {description = "select previous", group = "layout"}),
})

awful.keyboard.append_global_keybindings({
      awful.key({ modkey }, "F12", function(c) awful.util.spawn("xscreensaver-command --lock") end,
         {description = "Lock the computer"}),
      awful.key({ modkey}, "Print", function (c) awful.util.spawn("flameshot gui") end,
         {description = "Launch flameshot"}),
      awful.key({ modkey, shiftkey, ctrlkey}, "r", function (c) awesome.restart() end,
         {description = "Restart awesome"})
})


awful.keyboard.append_global_keybindings({
    awful.key({ modkey, ctrlkey, "Shift" }, "Right", function()
      local screen = awful.screen.focused()
      local t = screen.selected_tag
      if t then
          local idx = t.index + 1
          if idx > #screen.tags then idx = 1 end
          if client.focus then
            client.focus:move_to_tag(screen.tags[idx])
            screen.tags[idx]:view_only()
          end
      end
    end,
    {description = "move focused client to next tag and view tag", group = "tag"}),

    awful.key({ modkey, ctrlkey, "Shift" }, "Left", function()
      local screen = awful.screen.focused()
      local t = screen.selected_tag
      if t then
          local idx = t.index - 1
          if idx == 0 then idx = #screen.tags end
          if client.focus then
            client.focus:move_to_tag(screen.tags[idx])
            screen.tags[idx]:view_only()
          end
      end
    end,
    {description = "move focused client to previous tag and view tag", group = "tag"}),

    awful.key {
        modifiers   = { modkey },
        keygroup    = "numrow",
        description = "only view tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                tag:view_only()
            end
        end,
    },
    awful.key {
        modifiers   = { modkey, ctrlkey },
        keygroup    = "numrow",
        description = "toggle tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end,
    },
    awful.key {
        modifiers = { modkey, "Shift" },
        keygroup    = "numrow",
        description = "move focused client to tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { modkey, ctrlkey, "Shift" },
        keygroup    = "numrow",
        description = "toggle focused client on tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { modkey },
        keygroup    = "numpad",
        description = "select layout directly",
        group       = "layout",
        on_press    = function (index)
            local t = awful.screen.focused().selected_tag
            if t then
                t.layout = t.layouts[index] or t.layout
            end
        end,
    }
})

client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings({
        awful.button({}, 1, function (c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ modkey }, 1, function (c)
            c:activate { context = "mouse_click", action = "mouse_move"  }
        end),
        awful.button({ modkey }, 3, function (c)
            c:activate { context = "mouse_click", action = "mouse_resize"}
        end),
    })
end)

-- {{ Personal keybindings
client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
        -- swap and rotate clients in treetile layout
        awful.key({ modkey, "Shift" }, "r", function (c) treetile.rotate(c) end,
            {description = "treetile.container.rotate", group = "layout"}),
        awful.key({ modkey, "Shift" }, "s", function (c) treetile.swap(c) end,
            {description = "treetile.container.swap", group = "layout"}),

        -- transparency for focused client
        awful.key({ modkey }, "Next", function (c) awful.util.spawn("transset-df -a --inc 0.20 --max 0.99") end,
            {description="Client Transparency Up", group="client"}),
        awful.key({ modkey }, "Prior", function (c) awful.util.spawn("transset-df -a --min 0.1 --dec 0.1") end,
            {description="Client Transparency Down", group="client"}),

        -- show/hide titlebar
        awful.key({ modkey }, "t", awful.titlebar.toggle,
            {description = "Show/Hide Titlebars", group="client"}),

        -- altkey+Tab: cycle through all clients.
        awful.key({ altkey }, "Tab", function(c)
                cyclefocus.cycle({modifier="Alt_L"})
            end,
            {description = "Cycle through all clients", group="client"}
        ),
        -- altkey+Shift+Tab: backwards
        awful.key({ altkey, "Shift" }, "Tab", function(c)
                cyclefocus.cycle({modifier="Alt_L"})
            end,
            {description = "cycle through all clients backwards", group="client"}
        ),
    })
end)
--}}

client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
       -- Store debug information
        awful.key({ modkey, "Shift" }, "d", function (c)
                --naughty.notify {
                --    text = fishlive.helpers.screen_res_y()
                --}
                local val = awesome.systray()
                local file = io.open(os.getenv("HOME") .. "/.config/awesome/debug.txt", "a")
                file:write("systray.tostring=" .. val .. "\n")
                file:close()
            end,
            {description = "store debug information to awesome/debug.txt", group = "client"}),
        awful.key({ modkey }, "f", function (c)
                c.fullscreen = not c.fullscreen
                c:raise()
            end,
            {description = "toggle fullscreen", group = "client"}),
        awful.key({ modkey, "Shift" }, "c", function (c) c:kill() end,
                {description = "close", group = "client"}),
        awful.key({ modkey, ctrlkey }, "space", awful.client.floating.toggle,
                {description = "toggle floating", group = "client"}),
        awful.key({ modkey, ctrlkey }, "Return", function (c) c:swap(awful.client.getmaster()) end,
                {description = "move to master", group = "client"}),
        awful.key({ modkey }, "o", function (c) c:move_to_screen() end,
                {description = "move to screen", group = "client"}),
        awful.key({ modkey }, "t", function (c) c.ontop = not c.ontop end,
                {description = "toggle keep on top", group = "client"}),
        awful.key({ modkey }, "n", function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
            end ,
            {description = "minimize", group = "client"}),
        awful.key({ modkey }, "m", function (c)
                c.maximized = not c.maximized
                c:raise()
            end ,
            {description = "(un)maximize", group = "client"}),
        awful.key({ modkey, ctrlkey }, "m", function (c)
                c.maximized_vertical = not c.maximized_vertical
                c:raise()
            end ,
            {description = "(un)maximize vertically", group = "client"}),
        awful.key({ modkey, "Shift"   }, "m", function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c:raise()
            end ,
            {description = "(un)maximize horizontally", group = "client"}),
    })
end)

-- Steam bug with window outside of the screen
client.connect_signal("property::position", function(c)
     if c.class == 'Steam' then
         local g = c.screen.geometry
         if c.y + c.height > g.height then
             c.y = g.height - c.height
             naughty.notify{
                 text = "restricted window: " .. c.name,
             }
         end
         if c.x + c.width > g.width then
             c.x = g.width - c.width
         end
     end
 end)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients.
ruled.client.connect_signal("request::rules", function()
    -- All clients will match this rule.
    ruled.client.append_rule {
        id         = "floating",
        rule_any = {
            name = { "Ulauncher - Application Launcher" },
        },
        properties = {
            focus     = awful.client.focus.filter,
            raise     = true,
            screen    = awful.screen.preferred,
            border_width = 0,
        }
    }

    ruled.client.append_rule {
        id         = "global",
        rule       = { },
        properties = {
            focus     = awful.client.focus.filter,
            raise     = true,
            screen    = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    }

    -- Floating clients.
    ruled.client.append_rule {
        id       = "floating",
        rule_any = {
            instance = { "copyq", "pinentry" },
            class    = {
                "Arandr", "Blueman-manager", "Gpick", "Kruler", "Sxiv",
                "Tor Browser", "Wpa_gui", "veromix", "xtightvncviewer",
                "Pamac-manager",
                "Polkit-gnome-authentication-agent-1",
                "Polkit-kde-authentication-agent-1",
                "Gcr-prompter",
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name    = {
                "Event Tester",  -- xev.
                "Remmina Remote Desktop Client",
                "win0",
            },
            role    = {
                "AlarmWindow",    -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true },
        callback = function (c)
            awful.placement.centered(c, nil)
        end
    }

    -- Add titlebars to normal clients and dialogs
    ruled.client.append_rule {
        id         = "dialogs",
        rule_any   = { type = { "dialog" } },
        except_any = {
          -- place here exceptions for special dialogs windows
        },
        properties = { floating = true },
        callback = function (c)
            awful.placement.centered(c, nil)
        end
    }

    -- FullHD Resolution for Specific Apps
    ruled.client.append_rule {
        id         = "dialogs",
        rule_any   = {
            instance = { "remmina",}
        },
        except_any = {
            name = {
                "Remmina Remote Desktop Client"
            }
        },
        properties = { floating = true },
        callback = function (c)
            c.width = 1980
            c.height = 1080
            awful.placement.centered(c, nil)
        end
    }

    -- All Dialogs are floating and center
    ruled.client.append_rule {
        id         = "titlebars",
        rule_any   = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = true      }
    }

    -- Set Blender to always map on the tag 4 in screen 1.
    ruled.client.append_rule {
        rule_any    = {
            name = {"Blender"}
        },
        properties = {
            tag = screen[1].tags[4],
        },
    }
end)

ruled.notification.connect_signal('request::rules', function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen = awful.screen.preferred,
            --implicit_timeout = 5,
        }
    }
end)

-- Store notifications to the file
naughty.connect_signal("added", function(n)
    -- local file = io.open(os.getenv("HOME") .. "/.config/awesome/naughty_history", "a")
    -- file:write(n.title .. ": " .. n.id .. " " .. n.message .. "\n")
    -- file:close()
end)

client.connect_signal("mouse::enter", function(c)
    c:activate { context = "mouse_enter", raise = false }
end)

autorun = true
autorunProgs = {
   "xcompmgr -f -c -s",
   "xscreensaver --no-splash",
   "nitrogen --restore",
   "playerctld daemon"
}

if autorun then
   for _,v in ipairs(autorunProgs) do
      awful.util.spawn(v)
   end
end
