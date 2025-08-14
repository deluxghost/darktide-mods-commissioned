local mod = get_mod("AmmoEffi")
local UIWidget = require("scripts/managers/ui/ui_widget")
local Breed = require("scripts/utilities/breed")
local Havoc = require("scripts/utilities/havoc")
local HavocSettings = require("scripts/settings/havoc_settings")

local havoc_ammo_mul = {}
for _, ammo_settings in ipairs(HavocSettings.modifier_templates.ammo_pickup_modifier) do
	havoc_ammo_mul[#havoc_ammo_mul+1] = ammo_settings.ammo_pickup_modifier
end

local grenade_names = {
	"kill_volume_with_gibbing",
	"ogryn_dodge_impact",
	"default_grenade",
	"close_grenade",
	"frag_grenade",
	"close_frag_grenade",
	"krak_grenade",
	"close_krak_grenade",
	"ogryn_box_cluster_frag_grenade",
	"ogryn_box_cluster_close_frag_grenade",
	"smoke_grenade",
	"shock_grenade",
	"ogryn_charge_impact",
	"ogryn_charge_finish",
	"ogryn_charge_impact_damage",
	"ogryn_charge_finish_damage",
	"zealot_dash_health_to_damage_transfer",
	"zealot_preacher_ability_close",
	"zealot_preacher_ability_far",
	"frag_grenade_impact",
	"krak_grenade_impact",
	"ogryn_friendly_rock_impact",
	"ogryn_grenade_box_cluster_impact",
	"ogryn_grenade_impact",
	"psyker_smite_kill",
	"psyker_smite_light",
	"psyker_smite_heavy",
	"psyker_biomancer_soul",
	"psyker_protectorate_chain_lighting",
	"psyker_protectorate_chain_lighting_fast",
	"psyker_protectorate_channel_chain_lightning_activated",
	"psyker_protectorate_spread_chain_lightning_interval",
	"psyker_throwing_knives",
	"psyker_throwing_knives_pierce",
	"psyker_throwing_knives_aimed",
	"psyker_throwing_knives_aimed_pierce",
	"psyker_throwing_knives_psychic_fortress",
	"fire_grenade_impact",
	"zealot_throwing_knives",
	"adamant_grenade",
	"adamant_grenade_improved",
	"adamant_whistle",
	"adamant_shock_mine",
}

mod.enemy_health = mod:persistent_table("enemy_health")
mod.record = mod:persistent_table("record")
mod.record_dmg = mod:persistent_table("record_dmg")
mod.record_ammo = mod:persistent_table("record_ammo")

function mod.on_game_state_changed(status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		for key in pairs(mod.enemy_health) do
			mod.enemy_health[key] = nil
		end
		mod.record.havoc = 1
		if Managers.mechanism and Managers.mechanism._mechanism and Managers.mechanism._mechanism._mechanism_data then
			local mechanism_data = Managers.mechanism._mechanism._mechanism_data
			if mechanism_data.havoc_data then
				local parsed = Havoc.parse_data(mechanism_data.havoc_data)
				if parsed.modifiers then
					for _, modifier in ipairs(parsed.modifiers) do
						if modifier.name == "ammo_pickup_modifier" then
							mod.record.havoc = havoc_ammo_mul[modifier.level] or 1
						end
					end
				end
			end
		end
		mod.record_dmg.ranged = {}
		mod.record_dmg.burning = {}
		mod.record_dmg.bleeding = {}
		mod.record_dmg.warpfire = {}
		mod.record_ammo.small = {}
		mod.record_ammo.large = {}
		mod.record_ammo.crate = {}
		mod.record_ammo.current = {}
		mod.record_ammo.max = {}
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

mod.get_effi_value = function (uuid, team)
	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			return nil
		end
	end
	if mod.record == nil or mod.record_dmg == nil or mod.record_ammo == nil then
		return "N/A"
	end
	if not uuid then
		return "N/A"
	end
	local havoc_mul = mod.record.havoc or 1
	local ranged = mod.record_dmg.ranged[uuid] or 0
	local burning = mod.record_dmg.burning[uuid] or 0
	local bleeding = mod.record_dmg.bleeding[uuid] or 0
	local warpfire = mod.record_dmg.warpfire[uuid] or 0
	local dmg = ranged + burning
	if not team then
		if mod:get("personal_bleeding_enable") then
			dmg = dmg + bleeding
		end
		if mod:get("personal_warpfire_enable") then
			dmg = dmg + warpfire
		end
	end
	local small = mod.record_ammo.small[uuid] or 0
	local large = mod.record_ammo.large[uuid] or 0
	local crate = mod.record_ammo.crate[uuid] or 0
	if small == 0 and large == 0 and crate == 0 then
		return "ECO"
	end
	local current = mod.record_ammo.current[uuid] or 0
	local max = mod.record_ammo.max[uuid] or 0
	local ammo_mul = 1 + small * 0.15 * havoc_mul + large * 0.5 * havoc_mul + crate * havoc_mul - (max == 0 and 1 or current / max)
	if ammo_mul == 0 then
		return "ECO"
	end
	local effi = dmg / ammo_mul
	if effi > (mod:get("eco_value") * 1000) then
		return "ECO"
	end
	local normalized = ""
	if effi >= 1000000 then
		normalized = string.format("%.3fM", effi / 1000000)
	elseif effi >= 10000 then
		normalized = string.format("%.2fK", effi / 1000)
	else
		normalized = string.format("%.1f", effi)
	end
	return normalized
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

mod:hook(CLASS.InteracteeExtension, "stopped", function (func, self, result, ...)
	if result == "success" then
		local type = self:interaction_type() or ""
		local unit = self._interactor_unit
		if unit then
			local player = player_from_unit(unit)
			if player then
				local player_uuid = mod.get_player_uuid(player)
				if player_uuid then
					if type == "ammunition" then
						local ammo = self._override_contexts.ammunition.description
						if ammo == "loc_pickup_consumable_small_clip_01" then
							mod.record_ammo.small[player_uuid] = mod.record_ammo.small[player_uuid] or 0
							mod.record_ammo.small[player_uuid] = mod.record_ammo.small[player_uuid] + 1
						elseif ammo == "loc_pickup_consumable_large_clip_01" then
							mod.record_ammo.large[player_uuid] = mod.record_ammo.large[player_uuid] or 0
							mod.record_ammo.large[player_uuid] = mod.record_ammo.large[player_uuid] + 1
						elseif ammo == "loc_pickup_deployable_ammo_crate_01" then
							mod.record_ammo.crate[player_uuid] = mod.record_ammo.crate[player_uuid] or 0
							mod.record_ammo.crate[player_uuid] = mod.record_ammo.crate[player_uuid] + 1
						end
					end
				end
			end
		end
	end
	func(self, result, ...)
end)

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

mod:hook(CLASS.AttackReportManager, "add_attack_result", function (
		func, self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot,
		damage, attack_result, attack_type, damage_efficiency, ...
	)
	local is_local_game = mod.is_local_game()
	local player = player_from_unit(attacking_unit)
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

			if player then
				local player_uuid = mod.get_player_uuid(player)
				if player_uuid and actual_damage > 0 then
					if damage_profile and damage_profile.name and table.array_contains(grenade_names, damage_profile.name) then
						-- empty
					elseif attack_type == "ranged" or attack_type == "explosion" then
						mod.record_dmg.ranged[player_uuid] = mod.record_dmg.ranged[player_uuid] or 0
						mod.record_dmg.ranged[player_uuid] = mod.record_dmg.ranged[player_uuid] + actual_damage
					elseif damage_profile and damage_profile.name and damage_profile.name == "burning" then
						mod.record_dmg.burning[player_uuid] = mod.record_dmg.burning[player_uuid] or 0
						mod.record_dmg.burning[player_uuid] = mod.record_dmg.burning[player_uuid] + actual_damage
					elseif damage_profile and damage_profile.name and damage_profile.name == "bleeding" then
						mod.record_dmg.bleeding[player_uuid] = mod.record_dmg.bleeding[player_uuid] or 0
						mod.record_dmg.bleeding[player_uuid] = mod.record_dmg.bleeding[player_uuid] + actual_damage
					elseif damage_profile and damage_profile.name and damage_profile.name == "warpfire" then
						mod.record_dmg.warpfire[player_uuid] = mod.record_dmg.warpfire[player_uuid] or 0
						mod.record_dmg.warpfire[player_uuid] = mod.record_dmg.warpfire[player_uuid] + actual_damage
					end
				end
			end
		end
	end
	return func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, ...)
end)

mod:hook_require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions", function(instance)
	instance.widget_definitions.ammo_effi_text = UIWidget.create_definition({
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
				offset = { 80 + mod:get("team_x_offset"), -23 + mod:get("team_y_offset"), 10 },
			},
			visibility_function = function (content, style)
				style.offset = { 80 + mod:get("team_x_offset"), -23 + mod:get("team_y_offset"), 10 }
				return true
			end
		},
	}, "toughness_bar")
end)

mod:hook_require("scripts/ui/hud/elements/player_weapon/hud_element_player_weapon_definitions", function(instance)
	instance.widget_definitions.ammo_effi_text = UIWidget.create_definition({
		{
			value_id = "text",
			style_id = "text",
			pass_type = "text",
			value = "弹药资源效率",
			style = {
				font_type = "proxima_nova_bold",
				font_size = 16,
				drop_shadow = true,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.white(255, true),
				offset = { 30 + mod:get("personal_x_offset"), 75 + mod:get("personal_y_offset"), 0 },
			},
			visibility_function = function (content, style)
				style.offset = { 30 + mod:get("personal_x_offset"), 75 + mod:get("personal_y_offset"), 0 }
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
				font_size = 16,
				drop_shadow = true,
				vertical_alignment = "top",
				horizontal_alignment = "left",
				text_vertical_alignment = "top",
				text_horizontal_alignment = "left",
				text_color = Color.white(255, true),
				offset = { 30 + mod:get("personal_x_offset"), 95 + mod:get("personal_y_offset"), 10 },
			},
			visibility_function = function (content, style)
				style.offset = { 30 + mod:get("personal_x_offset"), 95 + mod:get("personal_y_offset"), 10 }
				return true
			end
		},
	}, "weapon")
end)

local function update_player_ammo(self, player)
	if not player then
		return
	end
	local uuid = mod.get_player_uuid(player)
	if not uuid then
		return
	end

	if Managers and Managers.state and Managers.state.game_mode then
		local game_mode_name = Managers.state.game_mode:game_mode_name()
		if game_mode_name == "hub" then
			return
		end
	end

	local extensions = self:_player_extensions(player)
	local unit_data_extension = extensions and extensions.unit_data
	if unit_data_extension then
		local weapon_slots = self._weapon_slots
		local total_current_ammo = 0
		local total_max_ammo = 0

		for i = 1, #weapon_slots do
			local slot_id = weapon_slots[i]
			local inventory_component = unit_data_extension:read_component(slot_id)

			if inventory_component then
				local max_clip = inventory_component.max_ammunition_clip or 0
				local max_reserve = inventory_component.max_ammunition_reserve or 0
				local current_clip = inventory_component.current_ammunition_clip or 0
				local current_reserve = inventory_component.current_ammunition_reserve or 0
				total_current_ammo = total_current_ammo + current_clip + current_reserve
				total_max_ammo = total_max_ammo + max_clip + max_reserve
			end
		end

		if total_max_ammo == 0 or self._show_as_dead or self._dead or self._hogtied then
			-- empty
		else
			mod.record_ammo.current[uuid] = total_current_ammo
			mod.record_ammo.max[uuid] = total_max_ammo
		end
	end
end

local function update_effi_player_features_func(team)
	return function (func, self, dt, t, player, ui_renderer)
		func(self, dt, t, player, ui_renderer)

		update_player_ammo(self, player)
		if not team then
			return
		end

		local widget = self._widgets_by_name.ammo_effi_text
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
		local value = mod.get_effi_value(uuid)
		if value == nil then
			widget.content.value = ""
			return
		end
		widget.content.value = value
	end
end

mod:hook("HudElementTeamPlayerPanel", "_update_player_features", update_effi_player_features_func(true))
mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", update_effi_player_features_func(false))

mod:hook_safe("HudElementPlayerWeapon", "update", function(self, _dt, _t, ui_renderer)
	local widget = self._widgets_by_name.ammo_effi_text
	if not widget then
		return
	end
	widget.dirty = true

	local player = Managers.player:local_player(1)
	if not player then
		widget.content.text = ""
		widget.content.value = ""
		return
	end
	local uuid = player:account_id()
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
	local value = mod.get_effi_value(uuid)
	if value == nil then
		widget.content.text = ""
		widget.content.value = ""
		return
	end
	widget.content.text = "弹药资源效率"
	widget.content.value = value
end)
