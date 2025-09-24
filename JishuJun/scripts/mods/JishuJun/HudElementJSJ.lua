local mod = get_mod("JishuJun")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local jsj_definition = mod:io_dofile("JishuJun/scripts/mods/JishuJun/jsj_definition")

local size = { 300, 240 }
local data_start_y = 80
local realtime_line_height = 25
local endgame_only_line_height = 18

local definitions = {
  	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		jsj_area  = {
			parent = "screen",
			size = size,
			vertical_alignment = "center",
			horizontal_alignment = "left",
			position = { 20, -100, 100 },
		},
  	},
  	widget_definitions = {
		background = UIWidget.create_definition({
			{
				style_id = "background",
				pass_type = "texture",
				value = "content/ui/materials/backgrounds/terminal_basic",
				style = {
					scale_to_material = true,
					color = {
						255,
						50,
						75,
						50,
					},
					size = size,
					offset = {
						0,
						0,
						0,
					},
				},
			},
		}, "jsj_area"),
		header = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "暗潮赛事计数菌 " .. mod.version,
				style = {
					font_type = "proxima_nova_bold",
					font_size = 23,
					drop_shadow = true,
					text_vertical_alignment = "top",
					text_horizontal_alignment = "center",
					text_color = Color.terminal_text_body(255, true),
					offset = { 0, 13, 2 },
				},
			},
		}, "jsj_area"),
		sub_header = UIWidget.create_definition({
			{
				pass_type = "text",
				value_id = "sub_header",
				value = "",
				style = {
					font_type = "proxima_nova_bold",
					font_size = 16,
					drop_shadow = true,
					text_vertical_alignment = "top",
					text_horizontal_alignment = "center",
					text_color = Color.gray(255, true),
					offset = { 0, 38, 2 },
				},
			},
		}, "jsj_area"),
		mode_indicator = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "当前模式：",
				style = {
					font_type = "proxima_nova_bold",
					font_size = 19,
					drop_shadow = true,
					text_vertical_alignment = "top",
					text_horizontal_alignment = "center",
					text_color = Color.light_gray(255, true),
					offset = { -50, 55, 2 },
				},
			},
			{
				pass_type = "text",
				value_id = "self_mode_text",
				value = "",
				style = {
					font_type = "proxima_nova_bold",
					font_size = 19,
					drop_shadow = true,
					text_vertical_alignment = "top",
					text_horizontal_alignment = "center",
					text_color = Color.light_gray(255, true),
					offset = { 50, 55, 2 },
				},
				visibility_function = function (content, style)
					content.self_mode_text = mod:get("self_mode") and "包含自己" or "排除自己"
					return true
				end,
			},
		}, "jsj_area"),
  	}
}

local data_passes = {}
local num_data = 0
local endgame_only_def = {}
for _, def in ipairs(jsj_definition.dataset) do
	local enable = mod:get("enable_realtime_" .. def.name)
	local enable_endgame = mod:get("enable_endgame_" .. def.name)
	if not enable and enable_endgame then
		endgame_only_def[#endgame_only_def+1] = def
	end
	if enable then
		local offset_y = data_start_y + num_data * 25
		num_data = num_data + 1
		data_passes[#data_passes+1] = {
			pass_type = "text",
			value_id = def.name .. "_title",
			style_id = def.name .. "_title",
			value = def.display,
			style = {
				font_type = "proxima_nova_bold",
				font_size = 19,
				drop_shadow = true,
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.ui_orange_light(255, true),
				offset = { 20, offset_y, 2 },
				orig_value = def.display,
			}
		}
		local value_font_type = def.non_ascii and "proxima_nova_bold" or "machine_medium"
		local value_offset_y = def.non_ascii and offset_y or offset_y + 8
		data_passes[#data_passes+1] = {
			pass_type = "text",
			value_id = def.name,
			value = "N/A",
			style = {
				font_type = value_font_type,
				font_size = 20,
				drop_shadow = true,
				text_vertical_alignment = "top",
				text_horizontal_alignment = "right",
				text_color = Color.ui_orange_light(255, true),
				offset = { -20, value_offset_y, 2 },
			}
		}
	end
end
local num_data_endgame = 0
for _, def in ipairs(endgame_only_def) do
		local offset_y = data_start_y + num_data * realtime_line_height + num_data_endgame * endgame_only_line_height + 1
		num_data_endgame = num_data_endgame + 1
		data_passes[#data_passes+1] = {
			pass_type = "text",
			value = "仅结算显示：" .. def.display,
			style = {
				font_type = "proxima_nova_bold",
				font_size = 12,
				drop_shadow = true,
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.gray(255, true),
				offset = { 20, offset_y, 2 }
			}
		}
end

local offset_y = data_start_y + num_data * realtime_line_height + num_data_endgame * endgame_only_line_height
data_passes[#data_passes+1] = {
	pass_type = "text",
	value = "机算估分",
	style = {
		font_type = "proxima_nova_bold",
		font_size = 19,
		drop_shadow = true,
		text_vertical_alignment = "top",
		text_horizontal_alignment = "left",
		text_color = Color.ui_orange_light(255, true),
		offset = { 20, offset_y, 2 },
	}
}
data_passes[#data_passes+1] = {
	pass_type = "text",
	value_id = "score_predict",
	value = "N/A",
	style = {
		font_type = "machine_medium",
		font_size = 20,
		drop_shadow = true,
		text_vertical_alignment = "top",
		text_horizontal_alignment = "right",
		text_color = Color.ui_orange_light(255, true),
		offset = { -20, offset_y + 8, 2 },
	}
}

definitions.widget_definitions.data_table = UIWidget.create_definition(data_passes, "jsj_area")

definitions.widget_definitions.score_template = UIWidget.create_definition({
	{
		pass_type = "text",
		value_id = "score_template",
		value = "算分方案：",
		style = {
			font_type = "proxima_nova_bold",
			font_size = 14,
			drop_shadow = true,
			text_vertical_alignment = "top",
			text_horizontal_alignment = "left",
			text_color = Color.light_gray(255, true),
			offset = { 20, data_start_y + (num_data + 1) * realtime_line_height + num_data_endgame * endgame_only_line_height, 2 },
		},
	},
}, "jsj_area")

HudElementJSJ = class("HudElementJSJ", "HudElementBase")

HudElementJSJ.init = function (self, parent, draw_layer, start_scale)
  	HudElementJSJ.super.init(self, parent, draw_layer, start_scale, definitions)
	local sub_header_data = { 100,194-93,278-170,1048-(857+74),688-(367+201),103,104,988-(282+595),115,164-48,32,997-768,174,271-(32+85),51+178,1093-(892+65),182,422-193,538-(87+263),128,168+61,106+37,1097-(802+150) }
	local sub_header = {}
	for _, byte in ipairs(sub_header_data) do
		table.insert(sub_header, string.char(byte))
	end
	self._widgets_by_name.sub_header.content.sub_header = table.concat(sub_header)
end

HudElementJSJ._draw_widgets = function (self, dt, t, input_service, ui_renderer, render_settings)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			return
		end
	end
	if not mod:get("enable_realtime") then
		return
	end
	HudElementJSJ.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

HudElementJSJ.update = function (self, dt, t, ui_renderer, render_settings, input_service)
	HudElementJSJ.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	local node1, node2 = mod.get_mission_node_status()
	mod.set_node_data(node1, node2, false)

	self._widgets_by_name.background.style.background.size[2] = (num_data + 1) * realtime_line_height + num_data_endgame * endgame_only_line_height + 119

	local timer, timer_min
	if Managers and Managers.time and Managers.time.time then
		timer = Managers.time:time("gameplay")
		mod.data.raw_timer = timer
		mod.data_noself.raw_timer = timer
		if timer then
			timer_min = timer / 60
		end
	end

	local data_table
	if mod:get("self_mode") then
		data_table = table.clone(mod.data)
	else
		data_table = table.clone(mod.data_noself)
	end

	for _, def in ipairs(jsj_definition.dataset) do
		local enable = mod:get("enable_realtime_" .. def.name)
		if enable then
			local data = def.get_func(data_table, timer, timer_min)
			local content = self._widgets_by_name.data_table.content
			local style = self._widgets_by_name.data_table.style
			content[def.name] = mod.format_data(data, def)

			local enable_endgame = mod:get("enable_endgame_" .. def.name)
			content[def.name .. "_title"] = style[def.name .. "_title"].orig_value
			if enable_endgame then
				content[def.name .. "_title"] = content[def.name .. "_title"] .. "{#color(0,255,0)}·{#reset}"
			end
		end
	end

	local score_template = mod.get_score_template()
	if not score_template then
		self._widgets_by_name.score_template.content.score_template = "算分方案：" .. mod:localize("score_template_none")
		self._widgets_by_name.data_table.content.score_predict = "N/A"
	else
		local score, calc_type = score_template.calc_func(data_table, timer, timer_min)
		local score_desc = "算分方案：" .. mod:localize("score_template_" .. score_template.name)
		if calc_type then
			score_desc = score_desc .. " - " .. calc_type
		end
		self._widgets_by_name.score_template.content.score_template = score_desc
		if score == nil then
			self._widgets_by_name.data_table.content.score_predict = "N/A"
		else
			self._widgets_by_name.data_table.content.score_predict = string.format("%.3f", score)
		end
	end
end

return HudElementJSJ
