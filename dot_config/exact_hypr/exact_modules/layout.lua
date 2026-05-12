local colors = require("modules.colors")
hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 15,
		border_size = 2,
		col = {
			active_border = colors.activeborder1,
			inactive_border = colors.crust,
		},

		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 8,
		rounding_power = 2,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		dim_inactive = true,
		dim_strength = 0.3,
		dim_around = 0.3,

		shadow = {
			enabled = true,
			range = 25,
			render_power = 5,
			color = colors.shadow,
			color_inactive = colors.inactiveshadow,
		},

		glow = {
			enabled = true,
			range = 15,
			color = "rgba(cba6f7aa)",
		},

		blur = {
			enabled = true,
			size = 5,
			passes = 2,
		},
	},

	animations = {
		enabled = true,
	},
})
