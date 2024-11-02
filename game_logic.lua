-- game_logic.lua
print("Game Version:", GAME_VERSION)
print("Max Health:", MAX_HEALTH)

-- Test calling Odin functions
local result = add_numbers(5, 3)
print("5 + 3 =", result)

local player_name = get_player_name()
print("Player name:", player_name)

set_game_score(1000)

-- Game configuration
GameConfig = {
	difficulty = "normal",
	sound_enabled = true,

	init = function()
		print("Initializing game...")
		-- Call some Odin functions
		local player = get_player_name()
		print("Starting game with player:", player)
	end,

	calculate_damage = function(base, modifier)
		return add_numbers(base, modifier)
	end,
}

-- Initialize the game
GameConfig.init()

-- Test damage calculation
local damage = GameConfig.calculate_damage(10, 5)
print("Calculated damage:", damage)
