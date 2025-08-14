local CircumstanceTemplates = require("scripts/settings/circumstance/circumstance_templates")

local unit_template = {
	{
		reach = 1000000,
		multiplier = 1/1000000,
		suffix = "M",
		digit = 3,
	},
	{
		reach = 10000,
		multiplier = 1/1000,
		suffix = "K",
		digit = 3,
	},
}

local format_func_template = {
	integer = function (value)
		return string.format("%d", value)
	end,
	float = function (value, digit)
		if digit == nil then
			digit = 3
		end
		return string.format("%." .. tostring(digit) .. "f", value)
	end,
}

local dataset = {
	{
		name = "timer",
		display = "任务计时",
		realtime_default = true,
		endgame_default = true,
		get_func = function (data, timer, timer_min)
			if timer and timer > 0 then
				local t_sec = math.floor(timer)
				local t_ms = timer - t_sec
				local t_min = math.floor(t_sec / 60)
				t_sec = t_sec % 60
				t_ms = math.floor(t_ms * 10)
				return string.format("%d:%02d.%d", t_min, t_sec, t_ms)
			end
			return nil
		end,
		end_func = function (data, timer, timer_min)
			if timer and timer > 0 then
				local t_sec = math.floor(timer)
				local t_ms = timer - t_sec
				local t_min = math.floor(t_sec / 60)
				t_sec = t_sec % 60
				t_ms = math.floor(t_ms * 10)
				return string.format("%d:%02d.%d (%.2f 分)", t_min, t_sec, t_ms, timer_min)
			end
			return nil
		end,
	},
	{
		name = "progress",
		display = "任务进程",
		realtime_default = true,
		endgame_default = true,
		non_ascii = true,
		get_func = function (data, timer, timer_min)
			if data.won then
				return "通关"
			end
			if data.node2 then
				return "节点 2"
			end
			if data.node1 then
				return "节点 1"
			end
			return "开局"
		end,
	},
	{
		name = "special_kpm",
		display = "特感击杀/分",
		desc = "包含非弱化特感、弱化特感",
		realtime_default = true,
		endgame_default = true,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = (data.normal_special_kills or 0) + (data.weak_special_kills or 0)
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "normal_special_kpm",
		display = "非弱化特感击杀/分",
		realtime_default = true,
		endgame_default = true,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = data.normal_special_kills or 0
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "weak_special_kpm",
		display = "弱化特感击杀/分",
		realtime_default = false,
		endgame_default = false,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = data.weak_special_kills or 0
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "elite_kpm",
		display = "精英击杀/分",
		desc = "包含近战精英、远程精英",
		realtime_default = false,
		endgame_default = false,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = (data.melee_elite_kills or 0) + (data.ranged_elite_kills or 0)
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "melee_elite_kpm",
		display = "近战精英击杀/分",
		desc = "包含近战欧格林精英",
		realtime_default = true,
		endgame_default = true,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = data.melee_elite_kills or 0
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "ranged_elite_kpm",
		display = "远程精英击杀/分",
		desc = "包含远程欧格林精英",
		realtime_default = true,
		endgame_default = true,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = data.ranged_elite_kills or 0
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "ogryn_elite_kpm",
		display = "欧格林精英击杀/分",
		realtime_default = false,
		endgame_default = false,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			local kills = data.ogryn_elite_kills or 0
			if timer_min and timer_min > 0 then
				return kills / timer_min
			end
			return nil
		end,
	},
	{
		name = "boss_damage",
		display = "Boss 伤害",
		desc = "包含满血 Boss、虚弱 Boss",
		realtime_default = true,
		endgame_default = true,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			return data.boss_damage or 0
		end,
	},
	{
		name = "normal_boss_damage",
		display = "满血 Boss 伤害",
		realtime_default = false,
		endgame_default = false,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			return data.normal_boss_damage or 0
		end,
	},
	{
		name = "weak_boss_damage",
		display = "虚弱 Boss 伤害",
		realtime_default = false,
		endgame_default = false,
		use_unit = true,
		format_func = format_func_template.float,
		get_func = function (data, timer, timer_min)
			return data.weak_boss_damage or 0
		end,
	},
}

local score_template = {
	{
		name = "random_build_trio",
		display = "随机 BD 三通",
		calc_func = function (data, timer, timer_min)
			local calc_type = "金漩涡/其他"
			local special_mul, melite_mul, relite_mul, boss_mul, timer_max, timer_mul = 150, 100, 120, 5, 50, 30
			if Managers.mechanism and Managers.mechanism._mechanism and Managers.mechanism._mechanism._mechanism_data then
				local mechanism_data = Managers.mechanism._mechanism._mechanism_data
				if mechanism_data.havoc_data then
					calc_type = "浩劫"
					special_mul, melite_mul, relite_mul, boss_mul, timer_max, timer_mul = 200, 100, 120, 3, 60, 20
				elseif mechanism_data.circumstance_name == "flash_mission_07" or mechanism_data.circumstance_name == "high_flash_mission_07" then
					calc_type = "近战大漩涡"
					special_mul, melite_mul, relite_mul, boss_mul, timer_max, timer_mul = 200, 150, 0, 3, 50, 20
				end
			end

			local score = 0
			if not timer_min or timer_min <= 0 then
				return nil
			end

			score = score + ((data.normal_special_kills or 0) / timer_min) * special_mul
			score = score + ((data.melee_elite_kills or 0) / timer_min) * melite_mul
			score = score + ((data.ranged_elite_kills or 0) / timer_min) * relite_mul
			score = score + (data.boss_damage or 0) / 1000 * boss_mul
			score = score + (timer_max - timer_min) * timer_mul
			if data.won then
				score = score + 200 + 200 + 500
			elseif data.node2 then
				score = score + 200 + 200
			elseif data.node1 then
				score = score + 200
			end

			return score, calc_type, "请手动添加 撤离人数×300 分"
		end,
	},
	{
		name = "duo",
		display = "普通双通",
		calc_func = function (data, timer, timer_min)
			local calc_type = "非怪专"
			local special_mul, melite_mul, relite_mul, boss_mul, timer_max, timer_mul = 130, 100, 120, 3, 50, 30
			if Managers.mechanism and Managers.mechanism._mechanism and Managers.mechanism._mechanism._mechanism_data then
				local mechanism_data = Managers.mechanism._mechanism._mechanism_data
				local circumstance_name = mechanism_data.circumstance_name
				local template = CircumstanceTemplates[circumstance_name]
				if template and template.mutators and table.array_contains(template.mutators, "mutator_monster_specials") then
					calc_type = "怪专"
					boss_mul = 2
				end
			end

			local score = 0
			if not timer_min or timer_min <= 0 then
				return nil
			end

			score = score + ((data.normal_special_kills or 0) / timer_min) * special_mul
			score = score + ((data.melee_elite_kills or 0) / timer_min) * melite_mul
			score = score + ((data.ranged_elite_kills or 0) / timer_min) * relite_mul
			score = score + (data.boss_damage or 0) / 1000 * boss_mul
			score = score + (timer_max - timer_min) * timer_mul
			if data.won then
				score = score + 200 + 200 + 500
			elseif data.node2 then
				score = score + 200 + 200
			elseif data.node1 then
				score = score + 200
			end

			return score, calc_type, "请手动添加 撤离人数×300 分"
		end,
	}
}

return {
	unit_template = unit_template,
	dataset = dataset,
	score_template = score_template,
}
