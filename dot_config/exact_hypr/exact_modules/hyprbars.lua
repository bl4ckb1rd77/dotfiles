local colors = require("modules.colors")
hl.config({
	plugin = {
		hyprbars = {
			bar_height = 32,
			bar_color = colors.crust,
			bar_text_size = 14,
			bar_buttons_alignment = "left",
			bar_text_font = "JetBrainsMono Nerd Font Propo",
		},
	},
})

hl.plugin.hyprbars.add_button({
	bg_color = colors.red,
	fg_color = colors.base,
	size = 18,
	icon = "",
	action = "hyprctl dispatch 'hl.dsp.window.close()'",
})

hl.plugin.hyprbars.add_button({
	bg_color = colors.yellow,
	fg_color = colors.base,
	size = 18,
	icon = "󰐃",
	action = "hyprctl dispatch 'hl.dsp.window.pin()'",
})

-- hl.plugin.hyprbars.add_button({
-- 	bg_color = colors.yellow,
-- 	fg_color = colors.base,
-- 	size = 16,
-- 	icon = "",
-- 	action = 'hyprctl dispatch \'hl.dsp.window.fullscreen({ mode="fullscreen", action="toggle" })\'',
-- })
