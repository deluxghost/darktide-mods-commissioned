return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`AUPM` encountered an error loading the Darktide Mod Framework.")

		new_mod("AUPM", {
			mod_script       = "AUPM/scripts/mods/AUPM/AUPM",
			mod_data         = "AUPM/scripts/mods/AUPM/AUPM_data",
			mod_localization = "AUPM/scripts/mods/AUPM/AUPM_localization",
		})
	end,
	packages = {},
}
