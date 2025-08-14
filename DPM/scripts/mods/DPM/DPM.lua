local mod = get_mod("DPM")
local Breed = require("scripts/utilities/breed")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIViewHandler = mod:original_require("scripts/managers/ui/ui_view_handler")

mod:register_hud_element({
	class_name = "HudElementDPM",
	filename = "DPM/scripts/mods/DPM/HudElementDPM",
	use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
})
mod.enemy_health = mod:persistent_table("enemy_health")
mod.record = mod:persistent_table("record")

function mod.on_game_state_changed(status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		mod.record.total_damage = 0
		mod.record.total_team_damage = 0
		mod.record.player_damage = {}
		for key in pairs(mod.enemy_health) do
			mod.enemy_health[key] = nil
		end
	end
end

local local_game_modes = {
	"shooting_range",
	"prologue",
	"prologue_hub",
}

mod.get_dpm_short_text = function (uuid)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			return nil
		end
	end
	if not Managers or not Managers.time then
		return nil
	end
	local mission_timer = Managers.time:time("gameplay") / 60.0
	if not mission_timer or mission_timer <= 0 then
		return nil
	end
	if mod.record.player_damage == nil then
		return nil
	end
	if not uuid then
		return nil
	end
	local damage = mod.record.player_damage[uuid] or 0
	local value = math.floor(damage / mission_timer / 1000)
	local color = "{#color(185,80,255)}"
	if value >= 50 then
		color = "{#color(245,40,80)}"
	elseif value >= 40 then
		color = "{#color(255,130,0)}"
	elseif value >= 30 then
		color = "{#color(0,185,255)}"
	end
	local text = ""
	if value >= 1000 then
		text = "999+"
	elseif value < 1 then
		text = "<1"
	else
		text = string.format("%d", value)
	end
	return color .. text
end

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

mod.recreate_hud = function ()
	local ui_manager = Managers.ui
	if ui_manager then
		local hud = ui_manager._hud
		if hud then
			local player = Managers.player:local_player(1)
			local peer_id = player:peer_id()
			local local_player_id = player:local_player_id()
			local elements = hud._element_definitions
			local visibility_groups = hud._visibility_groups

			hud:destroy()
			ui_manager:create_player_hud(peer_id, local_player_id, elements, visibility_groups)
		end
	end
end

mod.on_all_mods_loaded = function ()
	mod.recreate_hud()
end

mod:hook_safe(UIViewHandler, "close_view", function(self, view_name, force_close)
	if view_name == "dmf_options_view" or view_name == "inventory_view" then
		mod.recreate_hud()
	end
end)

mod:hook_require("scripts/ui/hud/elements/personal_player_panel/hud_element_personal_player_panel_definitions", function(instance)
	instance.widget_definitions.dpm_text = UIWidget.create_definition({
		{
			value_id = "value",
			style_id = "value",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 30,
				drop_shadow = true,
				vertical_alignment = "center",
				horizontal_alignment = "center",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "center",
				text_color = Color.white(255, true),
				offset = { -190, 2, 0 },
			},
			visibility_function = function (content, style)
				return true
			end
		},
	}, "toughness_bar")
end)

mod:hook_require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions", function(instance)
	instance.widget_definitions.dpm_text = UIWidget.create_definition({
		{
			value_id = "value",
			style_id = "value",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 30,
				drop_shadow = true,
				vertical_alignment = "center",
				horizontal_alignment = "center",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "center",
				text_color = Color.white(255, true),
				offset = { -133, -15, 0 },
			},
			visibility_function = function (content, style)
				return true
			end
		},
	}, "toughness_bar")
end)

local function update_dpm_player_features_func(team)
	return function (func, self, dt, t, player, ui_renderer)
		func(self, dt, t, player, ui_renderer)

		local widget = self._widgets_by_name.dpm_text
		if not widget then
			return
		end
		widget.dirty = true

		if not player then
			widget.content.value = ""
			return
		end
		local uuid = mod.get_player_uuid(player)
		if not uuid then
			widget.content.value = ""
			return
		end

		if Managers and Managers.state and Managers.state.game_mode then
			local game_mode_name = Managers.state.game_mode:game_mode_name()
			if game_mode_name == "hub" then
				widget.content.value = ""
				return
			end
		end
		local value = mod.get_dpm_short_text(uuid)
		if value == nil then
			widget.content.value = ""
			return
		end
		widget.content.value = value
	end
end

mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_dpm_player_features_func(true))
mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_dpm_player_features_func(false))

mod:hook_safe(CLASS.HuskHealthExtension, "init", function (self, extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id, ...)
	mod.enemy_health[unit] = self:max_health()
end)

mod:hook_safe(CLASS.HuskHealthExtension, "pre_update", function (self, unit, dt, t)
	if not mod.enemy_health[unit] then
		return
	end
	-- for enemy health regen
	local saved_health = mod.enemy_health[unit]
	local current_health = self:current_health()
	if saved_health < current_health then
		mod.enemy_health[unit] = current_health
	end
end)

mod:hook(CLASS.AttackReportManager, "add_attack_result", function(
		func, self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot,
		damage, attack_result, attack_type, damage_efficiency, ...
	)
	local is_local_game = mod.is_local_game()
	local player = player_from_unit(attacking_unit)
	local local_player = Managers.player:local_player(1)
	local is_self = player and (player:account_id() == local_player:account_id()) or false
	local player_uuid = mod.get_player_uuid(player)
	local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
	local unit_health_extension = ScriptUnit.has_extension(attacked_unit, "health_system")
	if unit_data_extension and unit_health_extension then
		local breed = unit_data_extension:breed()
		if breed and Breed.is_minion(breed) then
			local breed_name = unit_data_extension:breed_name()
			local damage_taken = unit_health_extension:damage_taken()
			local max_health = unit_health_extension:max_health()

			-- accurate damage calculation
			local actual_damage = 0
			if is_local_game then
				if attack_result == "died" then
					actual_damage = max_health - damage_taken + damage
				else
					actual_damage = damage
				end
			else
				local old_health = mod.enemy_health[attacked_unit]
				-- should not happen, have to guess
				if old_health == nil then
					old_health = unit_health_extension:current_health()
				end
				-- cannot ensure current_health() order
				local husk_health = unit_health_extension:current_health()
				local new_health = (husk_health < old_health) and husk_health or (old_health - damage)
				new_health = math.max(new_health, 0)

				if attack_result == "died" then
					actual_damage = old_health
					mod.enemy_health[attacked_unit] = nil
				else
					actual_damage = old_health - new_health
					mod.enemy_health[attacked_unit] = new_health
				end
			end

			if actual_damage > 0 then
				if is_self then
					mod.record.total_damage = mod.record.total_damage or 0
					mod.record.total_damage = mod.record.total_damage + actual_damage
				end
				mod.record.total_team_damage = mod.record.total_team_damage or 0
				mod.record.total_team_damage = mod.record.total_team_damage + actual_damage
				mod.record.player_damage = mod.record.player_damage or {}
				if player_uuid then
					mod.record.player_damage[player_uuid] = mod.record.player_damage[player_uuid] or 0
					mod.record.player_damage[player_uuid] = mod.record.player_damage[player_uuid] + actual_damage
				end
			end
		end
	end
	return func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, ...)
end)
