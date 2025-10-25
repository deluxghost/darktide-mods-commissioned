local mod = get_mod("DpmHalfMinutes")
local Breed = require("scripts/utilities/breed")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIViewHandler = mod:original_require("scripts/managers/ui/ui_view_handler")

mod.enemy_health = mod:persistent_table("enemy_health")
mod.record = mod:persistent_table("record")

function mod.on_game_state_changed(status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		mod.record.damage_list = {}
		mod.record.max_dpm = {}
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

mod.get_player_dpm = function (uuid)
	if not mod.record.damage_list then
		return 0
	end
	local dmg_list = mod.record.damage_list[uuid] or {}
	local sum = 0
	for _, dmg_data in ipairs(dmg_list) do
		sum = sum + dmg_data.dmg
	end
	local dpm = sum * 2
	mod.set_max_dpm(uuid, dpm)
	return dpm
end

local get_format = function (raw)
	local value = math.floor(raw / 1000)
	local text = ""
	if value >= 1000 then
		text = "999+"
	elseif value < 1 then
		text = "0"
	else
		text = string.format("%d", value)
	end
	return text
end

mod.get_value_text = function (uuid)
	local dpm, max_dpm = mod.get_player_dpm(uuid), mod.get_max_dpm(uuid)
	return string.format("{#color(250,50,50)}%s\n{#color(255,255,255)}%s", get_format(dpm), get_format(max_dpm))
end

mod.add_new_dmg = function (uuid, dmg, t)
	if not uuid then
		return
	end
	mod.record.damage_list = mod.record.damage_list or {}
	mod.record.damage_list[uuid] = mod.record.damage_list[uuid] or {}
	mod.record.damage_list[uuid][#mod.record.damage_list[uuid]+1] = {
		dmg = dmg,
		t = t,
	}
end

mod.clear_old_dmg = function (uuid, t)
	if not mod.record.damage_list then
		return
	end
	local dmg_list = mod.record.damage_list[uuid] or {}
	local valid_dmgs = {}
	for _, dmg_data in ipairs(dmg_list) do
		if dmg_data.t >= t - 30 then
			valid_dmgs[#valid_dmgs+1] = dmg_data
		end
	end
	mod.record.damage_list[uuid] = valid_dmgs
end

mod.get_max_dpm = function (uuid)
	if not uuid then
		return 0
	end
	mod.record.max_dpm = mod.record.max_dpm or {}
	return mod.record.max_dpm[uuid] or 0
end

mod.set_max_dpm = function (uuid, current_dpm)
	if not uuid then
		return
	end
	mod.record.max_dpm = mod.record.max_dpm or {}
	local old_dpm = mod.record.max_dpm[uuid] or 0
	if current_dpm > old_dpm then
		mod.record.max_dpm[uuid] = current_dpm
	end
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
	instance.widget_definitions.dpm_hm_text = UIWidget.create_definition({
		{
			value_id = "value",
			style_id = "value",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 22,
				drop_shadow = true,
				vertical_alignment = "center",
				horizontal_alignment = "center",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "right",
				text_color = Color.white(255, true),
				offset = { -373, 2, 0 },
			},
			visibility_function = function (content, style)
				return true
			end
		},
	}, "toughness_bar")
end)

mod:hook_require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions", function(instance)
	instance.widget_definitions.dpm_hm_text = UIWidget.create_definition({
		{
			value_id = "value",
			style_id = "value",
			pass_type = "text",
			value = "",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 22,
				drop_shadow = true,
				vertical_alignment = "center",
				horizontal_alignment = "center",
				text_vertical_alignment = "center",
				text_horizontal_alignment = "right",
				text_color = Color.white(255, true),
				offset = { -258, -15, 0 },
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

		local widget = self._widgets_by_name.dpm_hm_text
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
		local value = mod.get_value_text(uuid)
		if value == nil then
			widget.content.value = ""
			return
		end
		widget.content.value = value
		local gameplay_t = Managers.time:time("gameplay")
		mod.clear_old_dmg(uuid, gameplay_t)
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
	local t = Managers.time:time("gameplay")
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
				mod.add_new_dmg(player_uuid, actual_damage, t)
			end
		end
	end
	return func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, ...)
end)
