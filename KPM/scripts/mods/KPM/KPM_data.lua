local mod = get_mod("KPM")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "show_mkpm",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_rkpm",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_skpm",
				type = "checkbox",
				default_value = true,
			},
		}
	}
}
