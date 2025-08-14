local mod = get_mod("KPM")
local Breed = mod:original_require("scripts/utilities/breed")

mod:register_hud_element({
	class_name = "HudElementMKPM",
	filename = "KPM/scripts/mods/KPM/HudElementMKPM",
	use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
})
mod:register_hud_element({
	class_name = "HudElementRKPM",
	filename = "KPM/scripts/mods/KPM/HudElementRKPM",
	use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
})
mod:register_hud_element({
	class_name = "HudElementSKPM",
	filename = "KPM/scripts/mods/KPM/HudElementSKPM",
	use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
})
local melee_breeds = {
	"cultist_berzerker",
	"renegade_berzerker",
	"renegade_executor",
	"chaos_ogryn_bulwark",
	"chaos_ogryn_executor",
}
local ranged_breeds = {
	"cultist_gunner",
	"renegade_gunner",
	"cultist_shocktrooper",
	"renegade_shocktrooper",
	"chaos_ogryn_gunner",
}
local special_breeds = {
	"chaos_poxwalker_bomber",
	"renegade_grenadier",
	"cultist_grenadier",
	"renegade_sniper",
	"renegade_flamer",
	"cultist_flamer",
	"chaos_hound",
	"cultist_mutant",
	"renegade_netgunner",
}
mod.record = mod:persistent_table("record")

function mod.on_game_state_changed(status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		mod.record.melee_kills = 0
		mod.record.ranged_kills = 0
		mod.record.special_kills = 0
	end
end

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

mod:hook(CLASS.AttackReportManager, "add_attack_result", function(
		func, self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot,
		damage, attack_result, attack_type, damage_efficiency, ...
	)
	local player = player_from_unit(attacking_unit)
	if player then
		local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
		if unit_data_extension then
			local breed = unit_data_extension:breed()
			if breed and Breed.is_minion(breed) then
				local breed_name = unit_data_extension:breed_name()
				if mod.record and attack_result == "died" then
					if table.array_contains(melee_breeds, breed_name) then
						mod.record.melee_kills = mod.record.melee_kills or 0
						mod.record.melee_kills = mod.record.melee_kills + 1
					elseif table.array_contains(ranged_breeds, breed_name) then
						mod.record.ranged_kills = mod.record.ranged_kills or 0
						mod.record.ranged_kills = mod.record.ranged_kills + 1
					elseif table.array_contains(special_breeds, breed_name) then
						mod.record.special_kills = mod.record.special_kills or 0
						mod.record.special_kills = mod.record.special_kills + 1
					end
				end
			end
		end
	end
	return func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, ...)
end)
