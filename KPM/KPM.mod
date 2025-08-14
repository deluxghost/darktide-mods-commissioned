return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`KPM` encountered an error loading the Darktide Mod Framework.")

		new_mod("KPM", {
			mod_script       = "KPM/scripts/mods/KPM/KPM",
			mod_data         = "KPM/scripts/mods/KPM/KPM_data",
			mod_localization = "KPM/scripts/mods/KPM/KPM_localization",
		})
	end,
	packages = {},
}
