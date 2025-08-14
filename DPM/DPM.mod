return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DPM` encountered an error loading the Darktide Mod Framework.")

		new_mod("DPM", {
			mod_script       = "DPM/scripts/mods/DPM/DPM",
			mod_data         = "DPM/scripts/mods/DPM/DPM_data",
			mod_localization = "DPM/scripts/mods/DPM/DPM_localization",
		})
	end,
	packages = {},
}
