return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TimeSinceLastEliteKill` encountered an error loading the Darktide Mod Framework.")

		new_mod("TimeSinceLastEliteKill", {
			mod_script       = "TimeSinceLastEliteKill/scripts/mods/TimeSinceLastEliteKill/TimeSinceLastEliteKill",
			mod_data         = "TimeSinceLastEliteKill/scripts/mods/TimeSinceLastEliteKill/TimeSinceLastEliteKill_data",
			mod_localization = "TimeSinceLastEliteKill/scripts/mods/TimeSinceLastEliteKill/TimeSinceLastEliteKill_localization",
		})
	end,
	packages = {},
}
