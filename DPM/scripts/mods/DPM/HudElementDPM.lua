local mod = get_mod("DPM")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local definitions = {
  	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		dpm_area  = {
			parent = "screen",
			size = { 400, 50 },
			vertical_alignment = "center",
			horizontal_alignment = "center",
			position = { -200, -200, 100 }
		}
  	},
  	widget_definitions = {
		dpm_text = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "",
				value_id = "dpm",
				style_id = "dpm",
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
		}, "dpm_area")
  	}
}

HudElementDPM = class("HudElementDPM", "HudElementBase")

function HudElementDPM:init(parent, draw_layer, start_scale)
  	HudElementDPM.super.init(self, parent, draw_layer, start_scale, definitions)
end

HudElementDPM.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementDPM.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			self._widgets_by_name.dpm_text.content.dpm = ""
			return
		end
	end
	if not Managers or not Managers.time then
		self._widgets_by_name.dpm_text.content.dpm = "DPM: N/A"
		return
	end
	local mission_timer = Managers.time:time("gameplay") / 60.0
	if not mission_timer or mission_timer <= 0 then
		self._widgets_by_name.dpm_text.content.dpm = "DPM: N/A"
		return
	end
	if not mod.record or mod.record.total_damage == nil then
		self._widgets_by_name.dpm_text.content.dpm = "DPM: N/A"
		return
	end
	local total_damage = mod.record.total_damage
	local total_team_damage = mod.record.total_team_damage
	local dpm = total_damage / mission_timer
	local tdpm = total_team_damage / mission_timer
	local msg = dpm < 10000 and string.format("%.1f", dpm) or string.format("%.2fK", dpm / 1000)
	local tmsg = tdpm < 10000 and string.format("%.1f", tdpm) or string.format("%.2fK", tdpm / 1000)
	self._widgets_by_name.dpm_text.content.dpm = "DPM: " .. msg .. " / " .. tmsg
end

return HudElementDPM
