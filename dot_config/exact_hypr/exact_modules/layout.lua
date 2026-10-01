local colors = require("modules.colors")
hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 15,
		border_size = 2,
		col = {
			active_border = colors.activeborder2,
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

if hl.plugin.hyprglass ~= nil then
	hl.plugin.hyprglass.config({
		enabled = true,

		blur_strength = 0.7, -- default 2.0

		-- Edge effects, all raised so the pane still reads at 0.90 opacity.
		refraction_strength = 1.0,
		chromatic_aberration = 0.6,
		fresnel_strength = 1.0,
		specular_strength = 1.0,
		edge_thickness = 0.10,

		-- Less magnification; it smears at this blur level.
		lens_distortion = 0.3,

		-- Default tint at half alpha.
		tint_color = 0x8899aa11,

		-- Tone mapping off: the dark preset dims and flattens an already
		-- dark wallpaper.
		dark = {
			brightness = 1.0,
			contrast = 1.0,
			saturation = 0.9,
			adaptive_dim = 0.0,
		},
	})
end
