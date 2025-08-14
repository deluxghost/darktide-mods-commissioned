local mod = get_mod("JishuJun")
local jsj_definition = mod:io_dofile("JishuJun/scripts/mods/JishuJun/jsj_definition")

local data = {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "enable_realtime",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "self_mode",
				type = "checkbox",
				default_value = false,
			},
		}
	}
}

local score_data = {
	setting_id = "score_template",
	type = "dropdown",
	default_value = "none",
	options = {
		{ text = "score_template_none", value = "none" },
	},
}

for _, template in ipairs(jsj_definition.score_template) do
	score_data.options[#score_data.options+1] = {
		text = "score_template_" .. template.name,
		value = template.name,
	}
end
data.options.widgets[#data.options.widgets+1] = score_data

local group_data = {
	setting_id = "data_group",
	type = "group",
	sub_widgets = {},
}

for _, def in ipairs(jsj_definition.dataset) do
	group_data.sub_widgets[#group_data.sub_widgets+1] = {
		setting_id = "enable_realtime_" .. def.name,
		type = "checkbox",
		default_value = def.realtime_default,
	}
	group_data.sub_widgets[#group_data.sub_widgets+1] = {
		setting_id = "enable_endgame_" .. def.name,
		type = "checkbox",
		default_value = def.endgame_default,
	}
end
data.options.widgets[#data.options.widgets+1] = group_data

return data
