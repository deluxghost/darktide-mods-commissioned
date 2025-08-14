local mod = get_mod("KPM")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local definitions = {
  	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		skpm_area  = {
			parent = "screen",
			size = { 1000, 50 },
			vertical_alignment = "bottom",
			horizontal_alignment = "center",
			position = { 0, 0, 100 }
		}
  	},
  	widget_definitions = {
		skpm_text = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "",
				value_id = "skpm",
				style_id = "skpm",
				style = {
					font_type = "machine_medium",
					font_size = 28,
					drop_shadow = true,
					text_vertical_alignment = "center",
					text_horizontal_alignment = "center",
					text_color = Color.terminal_text_body(255, true),
					offset = { 0, 0, 100 }
				}
			}
		}, "skpm_area")
  	}
}

HudElementSKPM = class("HudElementSKPM", "HudElementBase")

function HudElementSKPM:init(parent, draw_layer, start_scale)
  	HudElementSKPM.super.init(self, parent, draw_layer, start_scale, definitions)
end

HudElementSKPM.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementSKPM.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			self._widgets_by_name.skpm_text.content.skpm = ""
			return
		end
	end
	if not mod:get("show_skpm") then
		self._widgets_by_name.skpm_text.content.skpm = ""
		return
	end
	if mod:get("show_mkpm") and mod:get("show_rkpm") then
		self._widgets_by_name.skpm_text.style.skpm.offset[1] = 300
	elseif mod:get("show_mkpm") or mod:get("show_rkpm") then
		self._widgets_by_name.skpm_text.style.skpm.offset[1] = 150
	end
	if not Managers or not Managers.time then
		self._widgets_by_name.skpm_text.content.skpm = "SKPM: N/A"
		return
	end
	local mission_timer = Managers.time:time("gameplay") / 60.0
	if not mission_timer or mission_timer <= 0 then
		self._widgets_by_name.skpm_text.content.skpm = "SKPM: N/A"
		return
	end
	if not mod.record or mod.record.special_kills == nil then
		self._widgets_by_name.skpm_text.content.skpm = "SKPM: N/A"
		return
	end
	local special_kills = mod.record.special_kills
	local skpm = special_kills / mission_timer
	local msg = string.format("SKPM: %.3f", skpm)
	self._widgets_by_name.skpm_text.content.skpm = msg
end

return HudElementSKPM
