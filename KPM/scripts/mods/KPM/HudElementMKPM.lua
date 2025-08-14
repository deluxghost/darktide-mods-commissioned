local mod = get_mod("KPM")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local definitions = {
  	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		mkpm_area  = {
			parent = "screen",
			size = { 1000, 50 },
			vertical_alignment = "bottom",
			horizontal_alignment = "center",
			position = { 0, 0, 100 }
		}
  	},
  	widget_definitions = {
		mkpm_text = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "",
				value_id = "mkpm",
				style_id = "mkpm",
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
		}, "mkpm_area")
  	}
}

HudElementMKPM = class("HudElementMKPM", "HudElementBase")

function HudElementMKPM:init(parent, draw_layer, start_scale)
  	HudElementMKPM.super.init(self, parent, draw_layer, start_scale, definitions)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		self.is_in_hub = game_mode_name == "hub"
	end
end

HudElementMKPM.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementMKPM.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			self._widgets_by_name.mkpm_text.content.mkpm = ""
			return
		end
	end
	if not mod:get("show_mkpm") then
		self._widgets_by_name.mkpm_text.content.mkpm = ""
		return
	end
	if mod:get("show_rkpm") and mod:get("show_skpm") then
		self._widgets_by_name.mkpm_text.style.mkpm.offset[1] = -300
	elseif mod:get("show_rkpm") or mod:get("show_skpm") then
		self._widgets_by_name.mkpm_text.style.mkpm.offset[1] = -150
	end
	if not Managers or not Managers.time then
		self._widgets_by_name.mkpm_text.content.mkpm = "MKPM: N/A"
		return
	end
	local mission_timer = Managers.time:time("gameplay") / 60.0
	if not mission_timer or mission_timer <= 0 then
		self._widgets_by_name.mkpm_text.content.mkpm = "MKPM: N/A"
		return
	end
	if not mod.record or mod.record.melee_kills == nil then
		self._widgets_by_name.mkpm_text.content.mkpm = "MKPM: N/A"
		return
	end
	local melee_kills = mod.record.melee_kills
	local mkpm = melee_kills / mission_timer
	local msg = string.format("MKPM: %.3f", mkpm)
	self._widgets_by_name.mkpm_text.content.mkpm = msg
end

return HudElementMKPM
