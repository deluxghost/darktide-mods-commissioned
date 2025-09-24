local mod = get_mod("JishuJun")
local Breed = require("scripts/utilities/breed")
local UIViewHandler = mod:original_require("scripts/managers/ui/ui_view_handler")
local jsj_definition = mod:io_dofile("JishuJun/scripts/mods/JishuJun/jsj_definition")
local mission_node_definition = mod:io_dofile("JishuJun/scripts/mods/JishuJun/mission_node_definition")

mod.version = "v11"

mod.enemy_health = mod:persistent_table("enemy_health")
mod.cutscene_seen = mod:persistent_table("cutscene_seen")
mod.data = mod:persistent_table("data")
mod.data_noself = mod:persistent_table("data_noself")
mod:register_hud_element({
	class_name = "HudElementJSJ",
	filename = "JishuJun/scripts/mods/JishuJun/HudElementJSJ",
	use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
})

local boss_breeds = {
	"chaos_plague_ogryn",
	"chaos_spawn",
	"chaos_beast_of_nurgle",
	"chaos_daemonhost",
	"chaos_mutator_daemonhost",
	"cultist_captain",
	"renegade_captain",
	"renegade_twin_captain",
	"renegade_twin_captain_two",
}
local melee_elite_breeds = {
	"cultist_berzerker",
	"renegade_berzerker",
	"renegade_executor",
	"chaos_ogryn_bulwark",
	"chaos_ogryn_executor",
}
local ranged_elite_breeds = {
	"cultist_gunner",
	"renegade_gunner",
	"renegade_plasma_gunner",
	"renegade_radio_operator",
	"cultist_shocktrooper",
	"renegade_shocktrooper",
	"chaos_ogryn_gunner",
}
local ogryn_elite_breeds = {
	"chaos_ogryn_bulwark",
	"chaos_ogryn_executor",
	"chaos_ogryn_gunner",
}
local normal_special_breeds = {
	"chaos_poxwalker_bomber",
	"renegade_grenadier",
	"cultist_grenadier",
	"renegade_sniper",
	"renegade_flamer",
	"renegade_flamer_mutator",
	"cultist_flamer",
	"chaos_hound",
	"cultist_mutant",
	"renegade_netgunner",
}
local weak_special_breeds = {
	"chaos_hound_mutator",
	"cultist_mutant_mutator",
}

mod.on_game_state_changed = function (status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		for key in pairs(mod.enemy_health) do
			mod.enemy_health[key] = nil
		end
		for key in pairs(mod.data) do
			mod.data[key] = nil
		end
		for key in pairs(mod.data_noself) do
			mod.data_noself[key] = nil
		end
		for key in pairs(mod.cutscene_seen) do
			mod.cutscene_seen[key] = nil
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

mod.format_data = function (data, def)
	if data then
		if def.use_unit then
			local suffix = ""
			local digit = 1
			for _, unit_data in ipairs(jsj_definition.unit_template) do
				if data > unit_data.reach then
					suffix = unit_data.suffix
					digit = unit_data.digit
					data = data * unit_data.multiplier
					break
				end
			end
			return def.format_func(data, digit) .. suffix
		end
		local formatted = data
		if def.format_func then
			formatted = def.format_func(data)
		end
		return formatted
	end
	return "N/A"
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

mod.get_score_template = function ()
	local score_template = mod:get("score_template") or "none"
	if score_template == "none" then
		return nil
	end
	local template
	for _, t in ipairs(jsj_definition.score_template) do
		if t.name == score_template then
			template = t
			break
		end
	end
	return template
end

local function get_objective_group_id()
	local level = Application.flow_callback_context_level()
	local unit_spawner_manager = Managers.state.unit_spawner

	if level then
		return unit_spawner_manager:index_by_level(level)
	else
		local unit = Application.flow_callback_context_unit()

		if unit then
			level = Unit.level(unit)

			if level then
				return unit_spawner_manager:index_by_level(level)
			end
		end
	end

	return 0
end

mod.get_mission_node_status = function ()
	if not Managers.mechanism or not Managers.mechanism._mechanism or not Managers.mechanism._mechanism._mechanism_data then
		return false, false
	end
	local mechanism_data = Managers.mechanism._mechanism._mechanism_data
	local mission_name = mechanism_data.mission_name
	local node_data = mission_node_definition[mission_name]
	if not node_data then
		return false, false
	end
	local mission_objective_system = Managers.state.extension:system("mission_objective_system")
	if not mission_objective_system then
		return false, false
	end

	local obj_group = mission_objective_system._objective_groups[get_objective_group_id()]
	if obj_group.active_objectives[node_data.node2] or obj_group.completed_objectives[node_data.node2] then
		return true, true
	end
	if obj_group.active_objectives[node_data.node1] or obj_group.completed_objectives[node_data.node1] then
		return true, false
	end
	return false, false
end

mod.on_all_mods_loaded = function ()
	local current_score_template = mod:get("score_template")
	local valid_score_template = false
	for _, template in ipairs(jsj_definition.score_template) do
		if template.name == current_score_template then
			valid_score_template = true
			break
		end
	end
	if not valid_score_template then
		mod:set("score_template", "none")
	end
	mod.recreate_hud()
end

mod.is_weakened = function (unit, breed)
	local is_weakened = false

	if not breed.is_boss or breed.ignore_weakened_boss_name then
		return is_weakened
	end

	local health_extension = ScriptUnit.extension(unit, "health_system")
	local max_health = health_extension:max_health()
	local initial_max_health = math.floor(Managers.state.difficulty:get_minion_max_health(breed.name))

	if max_health < initial_max_health then
		is_weakened = true
	else
		local is_havoc = Managers.state.difficulty:get_parsed_havoc_data()

		if is_havoc then
			local havoc_extension = Managers.state.game_mode:game_mode():extension("havoc")
			local havoc_health_override_value = havoc_extension and havoc_extension:get_modifier_value("modify_monster_health")

			if havoc_health_override_value then
				local multiplied_max_health = initial_max_health + initial_max_health * havoc_health_override_value

				if max_health < multiplied_max_health then
					is_weakened = true
				end
			end
		end
	end

	return is_weakened
end

mod.set_data = function (name, value, is_self)
	mod.data[name] = value
	if not is_self then
		mod.data_noself[name] = value
	end
end

mod.set_node_data = function (node1, node2, won)
	local onode1, onode2, owon = mod.data["node1"], mod.data["node2"], mod.data["won"]
	if node1 or onode1 then
		node1 = true
	end
	if node2 or onode2 then
		node1 = true
		node2 = true
	end
	if won or owon then
		node1 = true
		node2 = true
		won = true
	end
	mod.data["node1"] = node1
	mod.data_noself["node1"] = node1
	mod.data["node2"] = node2
	mod.data_noself["node2"] = node2
	mod.data["won"] = won
	mod.data_noself["won"] = won
end

mod.increase_data = function (name, value, is_self)
	mod.data[name] = mod.data[name] or 0
	mod.data[name] = mod.data[name] + value
	if not is_self then
		mod.data_noself[name] = mod.data_noself[name] or 0
		mod.data_noself[name] = mod.data_noself[name] + value
	end
end

mod:hook_safe(UIViewHandler, "close_view", function(self, view_name, force_close)
	if view_name == "dmf_options_view" or view_name == "inventory_view" then
		mod.recreate_hud()
	end
end)

local function end_game_score(won)
	if mod.data.reported then
		return
	end

	local timer, timer_min = mod.data.raw_timer, nil
	if timer then
		timer_min = timer / 60
	end
	mod.set_node_data(false, false, won)
	mod.set_data("reported", true, false)

	local msg_list = { "本局详细数据：" }
	local data_table
	if mod:get("self_mode") then
		data_table = table.clone(mod.data)
	else
		data_table = table.clone(mod.data_noself)
	end
	for _, def in ipairs(jsj_definition.dataset) do
		local enable = mod:get("enable_endgame_" .. def.name)
		if enable then
			local get_func = def.end_func and def.end_func or def.get_func
			local data = get_func(data_table, timer, timer_min)
			msg_list[#msg_list+1] = string.format("%s: %s", def.display, mod.format_data(data, def))
		end
	end

	local score_template = mod.get_score_template()
	if score_template then
		local score_desc = mod:localize("score_template_" .. score_template.name)
		local score, calc_type, end_msg = score_template.calc_func(data_table, timer, timer_min)
		if calc_type then
			score_desc = score_desc .. " - " .. calc_type
		end
		msg_list[#msg_list+1] = "算分方案: " .. score_desc
		local score_result = "无效分数"
		if score ~= nil then
			score_result = string.format("%.3f", score)
		end
		msg_list[#msg_list+1] = "机算分数: " .. score_result
		if end_msg then
			msg_list[#msg_list+1] = end_msg
		end
	else
		msg_list[#msg_list+1] = "机算分数: 不出分"
	end

	mod:echo(table.concat(msg_list, "\n"))
end

mod:hook_safe("CinematicSceneExtension", "setup_from_component", function(self)
	local name = self._cinematic_name or ""
	local won = false
	if name == "outro_win" then
		won = true
	elseif name == "outro_fail" then
		won = false
	else
		return
	end
	if mod.cutscene_seen[name] then
		end_game_score(won)
	else
		mod.cutscene_seen[name] = true
	end
end)

local function player_from_unit(unit)
	if unit then
		for _, player in pairs(Managers.player:players()) do
			if player.player_unit == unit then
				return player
			end
		end
	end
	return nil
end

mod:command("reload_jsj", mod:localize("刷新计数菌 HUD"), function ()
	mod.recreate_hud()
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
	local local_player = Managers.player:local_player(1)
	local is_self = player and (player:account_id() == local_player:account_id()) or false
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

			if player and mod.data and mod.data_noself then
				if attack_result == "died" then
					if table.array_contains(ogryn_elite_breeds, breed_name) then
						mod.increase_data("ogryn_elite_kills", 1, is_self)
					end
					if table.array_contains(melee_elite_breeds, breed_name) then
						mod.increase_data("melee_elite_kills", 1, is_self)
					elseif table.array_contains(ranged_elite_breeds, breed_name) then
						mod.increase_data("ranged_elite_kills", 1, is_self)
					elseif table.array_contains(normal_special_breeds, breed_name) then
						mod.increase_data("normal_special_kills", 1, is_self)
					elseif table.array_contains(weak_special_breeds, breed_name) then
						mod.increase_data("weak_special_kills", 1, is_self)
					end
				end
				if actual_damage > 0 then
					if table.array_contains(boss_breeds, breed_name) then
						local initial_max_health = Managers.state.difficulty:get_minion_max_health(breed_name)
						mod.increase_data("boss_damage", actual_damage, is_self)
						if mod.is_weakened(attacked_unit, breed) then
							mod.increase_data("weak_boss_damage", actual_damage, is_self)
						else
							mod.increase_data("normal_boss_damage", actual_damage, is_self)
						end
					end
				end
			end
		end
	end
	return func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, ...)
end)
