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
require("modules.hyprbars")

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

require("noctalia.noctalia-colors")
