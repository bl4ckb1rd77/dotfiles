local monitors = hl.get_monitors()
local tareget_monitor = "eDP-1"
for _, m in ipairs(monitors) do
	if m.name ~= "eDP-1" then
		tareget_monitor = m.name
		break
	end
end

for wsn = 1, 9, 1 do
	hl.workspace_rule({
		workspace = tostring(wsn),
		persistent = true,
		monitor = tareget_monitor,
	})
end

hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

----  MISC  ----
hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
	},
})
