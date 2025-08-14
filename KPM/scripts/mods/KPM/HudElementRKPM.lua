local mod = get_mod("KPM")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local definitions = {
  	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		rkpm_area  = {
			parent = "screen",
			size = { 1000, 50 },
			vertical_alignment = "bottom",
			horizontal_alignment = "center",
			position = { 0, 0, 100 }
		}
  	},
  	widget_definitions = {
		rkpm_text = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "",
				value_id = "rkpm",
				style_id = "rkpm",
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
		}, "rkpm_area")
  	}
}

HudElementRKPM = class("HudElementRKPM", "HudElementBase")

function HudElementRKPM:init(parent, draw_layer, start_scale)
  	HudElementRKPM.super.init(self, parent, draw_layer, start_scale, definitions)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		self.is_in_hub = game_mode_name == "hub"
	end
end

HudElementRKPM.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementRKPM.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			self._widgets_by_name.rkpm_text.content.rkpm = ""
			return
		end
	end
	if not mod:get("show_rkpm") then
		self._widgets_by_name.rkpm_text.content.rkpm = ""
		return
	end
	if not mod:get("show_mkpm") and mod:get("show_skpm") then
		self._widgets_by_name.rkpm_text.style.rkpm.offset[1] = -150
	elseif mod:get("show_mkpm") and not mod:get("show_skpm") then
		self._widgets_by_name.rkpm_text.style.rkpm.offset[1] = 150
	end
	if not Managers or not Managers.time then
		self._widgets_by_name.rkpm_text.content.rkpm = "RKPM: N/A"
		return
	end
	local mission_timer = Managers.time:time("gameplay") / 60.0
	if not mission_timer or mission_timer <= 0 then
		self._widgets_by_name.rkpm_text.content.rkpm = "RKPM: N/A"
		return
	end
	if not mod.record or mod.record.ranged_kills == nil then
		self._widgets_by_name.rkpm_text.content.rkpm = "RKPM: N/A"
		return
	end
	local ranged_kills = mod.record.ranged_kills
	local rkpm = ranged_kills / mission_timer
	local msg = string.format("RKPM: %.3f", rkpm)
	self._widgets_by_name.rkpm_text.content.rkpm = msg
end

return HudElementRKPM
