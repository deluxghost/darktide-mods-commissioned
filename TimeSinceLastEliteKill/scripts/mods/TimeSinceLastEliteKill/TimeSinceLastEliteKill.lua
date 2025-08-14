local mod = get_mod("TimeSinceLastEliteKill")
local Breed = mod:original_require("scripts/utilities/breed")

mod:register_hud_element({
	class_name = "HudElementTSLEK",
	filename = "TimeSinceLastEliteKill/scripts/mods/TimeSinceLastEliteKill/HudElementTSLEK",
	use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
})
local elite_breeds = {
	"cultist_berzerker",
	"renegade_berzerker",
	"renegade_executor",
	"chaos_ogryn_bulwark",
	"chaos_ogryn_executor",
	"cultist_gunner",
	"renegade_gunner",
	"cultist_shocktrooper",
	"renegade_shocktrooper",
	"chaos_ogryn_gunner",
}
mod.record = mod:persistent_table("record")

function mod.on_game_state_changed(status, state_name)
	if state_name == "StateGameplay" and status == "enter" then
		mod.record.elite_kill_time = nil
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
					if table.array_contains(elite_breeds, breed_name) then
						if Managers and Managers.time then
							mod.record.elite_kill_time = Managers.time:time("gameplay")
						end
					end
				end
			end
		end
	end
	return func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, ...)
end)
