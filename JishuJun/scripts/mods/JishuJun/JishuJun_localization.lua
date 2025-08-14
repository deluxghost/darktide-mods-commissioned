local mod = get_mod("JishuJun")
local jsj_definition = mod:io_dofile("JishuJun/scripts/mods/JishuJun/jsj_definition")

local localization = {
	mod_name = {
		en = "计数菌",
	},
	mod_description = {
		en = "暗潮赛事数据统计模组（作者：deluxghost）",
	},
	enable_realtime = {
		en = "启用实时显示",
	},
	self_mode = {
		en = "包含自己的数据",
	},
	self_mode_description = {
		en = "竞赛时，工作人员保持该选项关闭，可排除自己对统计产生干扰",
	},
	score_template = {
		en = "算分方案",
	},
	score_template_none = {
		en = "不出分",
	},
	data_group = {
		en = "统计数据选项",
	},
}

for _, template in ipairs(jsj_definition.score_template) do
	localization["score_template_" .. template.name] = {
		en = template.display,
	}
end

for _, def in ipairs(jsj_definition.dataset) do
	localization["enable_realtime_" .. def.name] = {
		en = "实时显示 " .. def.display,
	}
	localization["enable_endgame_" .. def.name] = {
		en = "      结算显示 " .. def.display,
	}
	if def.desc then
		localization["enable_realtime_" .. def.name .. "_description"] = {
			en = def.desc,
		}
		localization["enable_endgame_" .. def.name .. "_description"] = {
			en = def.desc,
		}
	end
end

return localization
