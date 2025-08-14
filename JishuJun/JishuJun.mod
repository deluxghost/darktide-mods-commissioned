return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`JishuJun` encountered an error loading the Darktide Mod Framework.")

		new_mod("JishuJun", {
			mod_script       = "JishuJun/scripts/mods/JishuJun/JishuJun",
			mod_data         = "JishuJun/scripts/mods/JishuJun/JishuJun_data",
			mod_localization = "JishuJun/scripts/mods/JishuJun/JishuJun_localization",
		})
	end,
	packages = {},
}
