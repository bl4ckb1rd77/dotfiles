hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	name = "kitty",
	match = {
		class = "^kitty$",
	},
	opacity = "0.9 0.5",
})

hl.window_rule({
	name = "floatkitty",
	float = true,
	size = { "(monitor_w*0.5)", "(monitor_h*0.5)" },
	opacity = "0.9 0.5",
	center = true,
	match = {
		initial_title = "^floatkitty$",
	},
})

hl.window_rule({
	name = "Brave",
	match = {
		class = "^brave-browser$",
	},
	opacity = "0.9 0.5",
})

hl.window_rule({
	name = "sysinfo",
	match = {
		title = "^sysinfo$",
	},
	opacity = "0.8 0.6",
	float = true,
	size = { 900, 430 },
	center = true,
})

hl.window_rule({
	name = "updater",
	float = true,
	size = { 800, "(monitor_h*0.94)" },
	move = { "((monitor_w*1)-810)", 49 },
	opacity = "0.9 0.7",
	match = {
		initial_title = "^update$",
	},
})
