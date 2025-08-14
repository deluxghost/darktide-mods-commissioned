local mod = get_mod("AUPM")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "personal_x_offset",
				type = "numeric",
				default_value = 0,
				range = { -400, 1000 },
			},
			{
				setting_id = "personal_y_offset",
				type = "numeric",
				default_value = 0,
				range = { -500, 200 },
			},
			{
				setting_id = "team_x_offset",
				type = "numeric",
				default_value = 0,
				range = { -400, 1000 },
			},
			{
				setting_id = "team_y_offset",
				type = "numeric",
				default_value = 0,
				range = { -500, 200 },
			},
		}
	}
}
