return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`AmmoEffi` encountered an error loading the Darktide Mod Framework.")

		new_mod("AmmoEffi", {
			mod_script       = "AmmoEffi/scripts/mods/AmmoEffi/AmmoEffi",
			mod_data         = "AmmoEffi/scripts/mods/AmmoEffi/AmmoEffi_data",
			mod_localization = "AmmoEffi/scripts/mods/AmmoEffi/AmmoEffi_localization",
		})
	end,
	packages = {},
}
