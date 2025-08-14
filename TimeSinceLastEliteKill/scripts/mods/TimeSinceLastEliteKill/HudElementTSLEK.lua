local mod = get_mod("TimeSinceLastEliteKill")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local definitions = {
  	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		tslek_area  = {
			parent = "screen",
			size = { 500, 50 },
			vertical_alignment = "bottom",
			horizontal_alignment = "center",
			position = { 0, -120, 100 }
		}
  	},
  	widget_definitions = {
		tslek_text = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "",
				value_id = "tslek",
				style_id = "tslek",
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
		}, "tslek_area")
  	}
}

HudElementTSLEK = class("HudElementTSLEK", "HudElementBase")

function HudElementTSLEK:init(parent, draw_layer, start_scale)
  	HudElementTSLEK.super.init(self, parent, draw_layer, start_scale, definitions)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		self.is_in_hub = game_mode_name == "hub"
	end
end

HudElementTSLEK.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementTSLEK.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	if self.is_in_hub then
		self._widgets_by_name.tslek_text.content.tslek = ""
		return
	end
	if not Managers or not Managers.time then
		self._widgets_by_name.tslek_text.content.tslek = "TSLEK: N/A"
		return
	end
	local mission_timer = Managers.time:time("gameplay")
	if not mission_timer or mission_timer <= 0 then
		self._widgets_by_name.tslek_text.content.tslek = "TSLEK: N/A"
		return
	end
	if not mod.record or mod.record.elite_kill_time == nil then
		self._widgets_by_name.tslek_text.content.tslek = "TSLEK: N/A"
		return
	end
	local elite_kill_time = mod.record.elite_kill_time
	local tslek = mission_timer - elite_kill_time
	if tslek < 0 then
		tslek = 0
	end
	local tslek_sec = math.floor(tslek)
	local tslek_ms = tslek - tslek_sec
	local tslek_min = math.floor(tslek_sec / 60)
	tslek_sec = tslek_sec % 60
	tslek_ms = math.floor(tslek_ms * 10)
	local msg = string.format("TSLEK: %d:%02d.%d", tslek_min, tslek_sec, tslek_ms)
	self._widgets_by_name.tslek_text.content.tslek = msg
end

return HudElementTSLEK
