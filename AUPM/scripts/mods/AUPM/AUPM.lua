local mod = get_mod("AUPM")
local UIWidget = require("scripts/managers/ui/ui_widget")

mod.record_ability_name = mod:persistent_table("record_ability_name")
mod.record_ability_previous = mod:persistent_table("record_ability_previous")
mod.record_ability_used = mod:persistent_table("record_ability_used")
mod.record_ability_cd = mod:persistent_table("record_ability_cd")

function mod.on_game_state_changed(status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		for key in pairs(mod.record_ability_name) do
			mod.record_ability_name[key] = nil
		end
		for key in pairs(mod.record_ability_previous) do
			mod.record_ability_previous[key] = nil
		end
		for key in pairs(mod.record_ability_used) do
			mod.record_ability_used[key] = nil
		end
		for key in pairs(mod.record_ability_cd) do
			mod.record_ability_cd[key] = nil
		end
	end
end

local local_game_modes = {
	"shooting_range",
	"prologue",
	"prologue_hub",
}

mod.is_local_game = function ()
	local game_mode = Managers.state and Managers.state.game_mode and Managers.state.game_mode:game_mode_name()
	if not game_mode then
		return false
	end
	if table.array_contains(local_game_modes, game_mode) then
		return true
	end
	if Managers.multiplayer_session:host_type() == "singleplay" then
		return true
	end
	return false
end

mod.get_aupm_value = function (uuid)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			return nil
		end
	end
	if not Managers or not Managers.time then
		return "N/A"
	end
	local mission_timer = Managers.time:time("gameplay") / 60.0
	if not mission_timer or mission_timer <= 0 then
		return "N/A"
	end
	if mod.record_ability_used == nil then
		return "N/A"
	end
	if not uuid then
		return "N/A"
	end
	local ability_used = mod.record_ability_used[uuid] or 0
	local aupm = ability_used / mission_timer
	local max_cd = mod.record_ability_cd[uuid] or 0
	return string.format("%d [%.1fs CD]\n%.2f/min", ability_used, max_cd, aupm)
end

local player_from_unit = function (unit)
	if unit then
		for _, player in pairs(Managers.player:players()) do
			if player.player_unit == unit then
				return player
			end
		end
	end
	return nil
end

mod.get_player_uuid = function(player)
	if not player then
		return
	end
	return player:account_id() or player:name()
end

local ability_hook_function = function (self, unit, dt, t)
	local enabled = self:ability_enabled("combat_ability")
	if not enabled then
		return
	end

	local player = player_from_unit(unit)
	if not player then
		return
	end
	local player_uuid = mod.get_player_uuid(player)
	if not player_uuid then
		return
	end
	local health_extension = ScriptUnit.has_extension(unit, "health_system")
	if not health_extension then
		return
	end

	local alive = true
	if not health_extension:is_alive() then
		alive = false
	end
	if (health_extension:current_health_percent() or 0) == 0 then
		alive = false
	end

	local name
	if self._equipped_abilities.combat_ability then
		name = self._equipped_abilities.combat_ability.name
	end
	local name_previous = mod.record_ability_name[player_uuid] or nil
	local ability_previous = mod.record_ability_previous[player_uuid] or 0
	local ability_components = self._ability_components or self._components
	local component = ability_components["combat_ability"]
	local current_num_charges = component.num_charges
	if name == name_previous and ability_previous ~= current_num_charges then
		local charge_delta = current_num_charges - ability_previous
		if charge_delta < 0 and alive then
			mod.record_ability_used[player_uuid] = mod.record_ability_used[player_uuid] or 0
			mod.record_ability_used[player_uuid] = mod.record_ability_used[player_uuid] - charge_delta
		end
	end
	mod.record_ability_cd[player_uuid] = self:max_ability_cooldown("combat_ability") or 0
	mod.record_ability_previous[player_uuid] = current_num_charges
	mod.record_ability_name[player_uuid] = name
end

mod:hook_safe(CLASS.PlayerUnitAbilityExtension, "update", ability_hook_function)
mod:hook_safe(CLASS.PlayerHuskAbilityExtension, "update", ability_hook_function)

mod:hook_require("scripts/ui/hud/elements/personal_player_panel/hud_element_personal_player_panel_definitions", function(instance)
	instance.widget_definitions.aupm_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "技能次数",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 16,
				drop_shadow = true,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.white(255, true),
				offset = { 360 + mod:get("personal_x_offset"), -10 + mod:get("personal_y_offset"), 0 },
			},
			visibility_function = function (content, style)
				style.offset = { 360 + mod:get("personal_x_offset"), -10 + mod:get("personal_y_offset"), 0 }
				return true
			end
		},
		{
			value_id = "value",
			style_id = "value",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 18,
				drop_shadow = true,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.white(255, true),
				offset = { 360 + mod:get("personal_x_offset"), 14 + mod:get("personal_y_offset"), 0 },
			},
			visibility_function = function (content, style)
				style.offset = { 360 + mod:get("personal_x_offset"), 14 + mod:get("personal_y_offset"), 0 }
				return true
			end
		},
	}, "toughness_bar")
end)

mod:hook_require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions", function(instance)
	instance.widget_definitions.aupm_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 16,
				drop_shadow = true,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.white(255, true),
				offset = { 250 + mod:get("team_x_offset"), -44 + mod:get("team_y_offset"), 0 },
			},
			visibility_function = function (content, style)
				style.offset = { 250 + mod:get("team_x_offset"), -44 + mod:get("team_y_offset"), 0 }
				return true
			end
		},
		{
			value_id = "value",
			style_id = "value",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 18,
				drop_shadow = true,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.white(255, true),
				offset = { 250 + mod:get("team_x_offset"), -20 + mod:get("team_y_offset"), 0 },
			},
			visibility_function = function (content, style)
				style.offset = { 250 + mod:get("team_x_offset"), -20 + mod:get("team_y_offset"), 0 }
				return true
			end
		},
	}, "toughness_bar")
end)

local function update_aupm_player_features_func(team)
	return function (func, self, dt, t, player, ui_renderer)
		func(self, dt, t, player, ui_renderer)

		local widget = self._widgets_by_name.aupm_text
		if not widget then
			return
		end
		widget.dirty = true

		if not player then
			widget.content.text = ""
			widget.content.value = ""
			return
		end
		local uuid = mod.get_player_uuid(player)
		if not uuid then
			widget.content.text = ""
			widget.content.value = ""
			return
		end

		if Managers and Managers.state and Managers.state.game_mode then
			local game_mode_name = Managers.state.game_mode:game_mode_name()
			if game_mode_name == "hub" then
				widget.content.text = ""
				widget.content.value = ""
				return
			end
		end
		local value = mod.get_aupm_value(uuid)
		if value == nil then
			widget.content.text = ""
			widget.content.value = ""
			return
		end
		if not team then
			widget.content.text = "技能次数"
		end
		widget.content.value = value
	end
end

mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_aupm_player_features_func(true))
mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_aupm_player_features_func(false))
