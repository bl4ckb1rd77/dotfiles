require("modules.autostart")
require("modules.monitor")
require("modules.devices")
require("modules.env")
require("modules.layout")
require("modules.animations")
require("modules.workspaces")
require("modules.input")
require("modules.keybindings")
require("modules.window-rules")

-- hyprbars
-- require("modules.hyprbars")

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- This loads Noctalia-generated Hyprland colors.
dofile("/home/ahoefer/.config/hypr/noctalia/noctalia-colors.lua")

do
	local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"
	local file = io.open(path, "r")
	if file then
		file:close()
		dofile(path)
	end
end

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
