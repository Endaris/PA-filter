require("consts")
require("queue")
require("sound_util")

-- keyboard assignment vars
K = {{up="up", down="down", left="left", right="right",
      swap1="z", swap2="x", taunt_up="y", taunt_down="u", raise1="c", raise2="v", pause="p"},
      {},{},{}}
keys = {}
this_frame_keys = {}
this_frame_unicodes = {}
this_frame_messages = {}

score_mode = SCOREMODE_TA

gfx_q = Queue()

themes = {} -- initialized in theme.lua

characters = {} -- initialized in character.lua
characters_ids = {} -- initialized in character.lua
characters_ids_for_current_theme = {} -- initialized in character.lua
characters_ids_by_display_names = {} -- initialized in character.lua

stages = {} -- initialized in stage.lua
stages_ids = {} -- initialized in stage.lua
stages_ids_for_current_theme = {} -- initialized in stage.lua

panels = {} -- initialized in panel_set.lua
panels_ids = {} -- initialized in panel_set.lua

current_stage = nil

-- win counters
my_win_count = 0
op_win_count = 0

-- sfx play
SFX_Fanfare_Play = 0
SFX_GarbageThud_Play = 0
SFX_GameOver_Play = 0

global_my_state = nil
global_op_state = nil

-- game can be paused while playing on local
game_is_paused = false

large_font = love.graphics.newFont(22)
large_font:setFilter("nearest", "nearest")
main_font = love.graphics.getFont() -- default size is 12
main_font:setFilter("nearest", "nearest")
small_font = love.graphics.newFont(9)
small_font:setFilter("nearest", "nearest")
zero_sound = load_sound_from_supported_extensions("zero_music")

  -- Default configuration values
config = {
	-- The lastly used version
	version                       = VERSION,

	theme                         = default_theme_dir,
	panel_set                     = default_panels_dir,
	character                     = random_character_special_value,
	stage                         = random_stage_special_value,

	use_music_from                = "stage",
	-- Level (2P modes / 1P vs yourself mode)
	level                         = 5,
	endless_speed                 = 1,
	endless_difficulty            = 1,
	-- Player name
	name                          = "defaultname",
	-- Volume settings
	master_volume                 = 100,
	SFX_volume                    = 100,
	music_volume                  = 100,
	-- Debug mode flag
	debug_mode                    = false,
	-- Show FPS in the top-left corner of the screen
	show_fps                      = false,
	-- Enable ready countdown flag
	ready_countdown_1P            = true,
	-- Change danger music back later flag
	danger_music_changeback_delay = false,
	-- analytics
	enable_analytics              = false,
	-- Save replays setting
	save_replays_publicly         = "with my name",
}