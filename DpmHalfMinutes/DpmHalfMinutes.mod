return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DpmHalfMinutes` encountered an error loading the Darktide Mod Framework.")

		new_mod("DpmHalfMinutes", {
			mod_script       = "DpmHalfMinutes/scripts/mods/DpmHalfMinutes/DpmHalfMinutes",
			mod_data         = "DpmHalfMinutes/scripts/mods/DpmHalfMinutes/DpmHalfMinutes_data",
			mod_localization = "DpmHalfMinutes/scripts/mods/DpmHalfMinutes/DpmHalfMinutes_localization",
		})
	end,
	packages = {},
}
