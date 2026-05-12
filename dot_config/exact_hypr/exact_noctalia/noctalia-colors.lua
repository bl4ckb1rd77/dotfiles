local primary = "rgb(cba6f7)"
local surface = "rgb(1e1e2e)"
local secondary = "rgb(fab387)"
local error = "rgb(f38ba8)"
local tertiary = "rgb(94e2d5)"
local surface_lowest = "rgb(212232)"

hl.config({
    general = {
        ["col.active_border"] = primary,
        ["col.inactive_border"] = surface,
    },
    group = {
        ["col.border_active"] = secondary,
        ["col.border_inactive"] = surface,
        ["col.border_locked_active"] = error,
        ["col.border_locked_inactive"] = surface,
        groupbar = {
            ["col.active"] = secondary,
            ["col.inactive"] = surface,
            ["col.locked_active"] = error,
            ["col.locked_inactive"] = surface,
        },
    },
})
