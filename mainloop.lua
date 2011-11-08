local wait = coroutine.yield

local main_select_mode, main_endless, make_main_puzzle, main_net_vs_setup,
  main_replay_endless, main_replay_puzzle, main_net_vs,
  main_config_input, main_dumb_transition, main_select_puzz,
  menu_up, menu_down, menu_left, menu_right, menu_enter, menu_escape,
  main_replay_vs, main_local_vs_setup, main_local_vs, menu_key_func,
  multi_func, normal_key

function fmainloop()
  local func, arg = main_select_mode, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

-- Changes the behavior of menu_foo functions.
-- In a menu that doesn't specifically pertain to multiple players,
-- up, down, left, right should always work.  But in a multiplayer
-- menu, those keys should definitely not move many cursors each.
local multi = false
function multi_func(func)
  return function(...)
    multi = true
    local res = {func(...)}
    multi = false
    return unpack(res)
  end
end

-- Keys that have a fixed function in menus can be bound to other
-- meanings, but should continue working the same way in menus.
local menu_reserved_keys = {}

function repeating_key(key)
  local key_time = keys[key]
  return this_frame_keys[key] or
    (key_time and key_time > 25 and key_time % 3 ~= 0)
end

function normal_key(key) return this_frame_keys[key] end

function menu_key_func(fixed, configurable, rept)
  local query = normal_key
  if rept then
    query = repeating_key
  end
  for i=1,#fixed do
    menu_reserved_keys[#menu_reserved_keys+1] = fixed[i]
  end
  return function(k)
    local res = false
    if multi then
      for i=1,#configurable do
        res = res or query(k[configurable[i]])
      end
    else
      for i=1,#fixed do
        res = res or query(fixed[i])
      end
      for i=1,#configurable do
        local keyname = k[configurable[i]]
        res = res or query(keyname) and
            not menu_reserved_keys[keyname]
      end
    end
    return res
  end
end

menu_up = menu_key_func({"up"}, {"up"}, true)
menu_down = menu_key_func({"down"}, {"down"}, true)
menu_left = menu_key_func({"left"}, {"left"}, true)
menu_right = menu_key_func({"right"}, {"right"}, true)
menu_enter = menu_key_func({"return","kenter","z"}, {"swap1"}, false)
menu_escape = menu_key_func({"escape","x"}, {"swap2"}, false)

do
  local active_idx = 1
  function main_select_mode()
    local items = {{"1P endless", main_select_speed_99, {main_endless}},
        {"1P puzzle", main_select_puzz},
        {"1P time attack", main_select_speed_99, {main_time_attack}},
        {"2P fakevs at dustinho.com", main_net_vs_setup, {"dustinho.com"}},
        {"2P fakevs local game", main_local_vs_setup},
        {"Replay of 1P endless", main_replay_endless},
        {"Replay of 1P puzzle", main_replay_puzzle},
        {"Replay of 2P fakevs", main_replay_vs},
        {"Configure input", main_config_input},
        {"Quit", os.exit}}
    local k = K[1]
    while true do
      local to_print = ""
      local arrow = ""
      for i=1,#items do
        if active_idx == i then
          arrow = arrow .. ">"
        else
          arrow = arrow .. "\n"
        end
        to_print = to_print .. "   " .. items[i][1] .. "\n"
      end
      gprint(arrow, 300, 280)
      gprint(to_print, 300, 280)
      wait()
      if menu_up(k) then
        active_idx = wrap(1, active_idx-1, #items)
      elseif menu_down(k) then
        active_idx = wrap(1, active_idx+1, #items)
      elseif menu_enter(k) then
        return items[active_idx][2], items[active_idx][3]
      elseif menu_escape(k) then
        if active_idx == #items then
          return items[active_idx][2], items[active_idx][3]
        else
          active_idx = #items
        end
      end
    end
  end
end

function main_select_speed_99(next_func, ...)
  local difficulties = {"Easy", "Normal", "Hard"}
  local items = {{"Speed"},
                {"Difficulty"},
                {"Go!", next_func},
                {"Back", main_select_mode}}
  local speed, difficulty, active_idx = 1,1,1
  local k = K[1]
  while true do
    local to_print, to_print2, arrow = "", "", ""
    for i=1,#items do
      if active_idx == i then
        arrow = arrow .. ">"
      else
        arrow = arrow .. "\n"
      end
      to_print = to_print .. "   " .. items[i][1] .. "\n"
    end
    to_print2 = "                  " .. speed .. "\n                  "
      .. difficulties[difficulty]
    gprint(arrow, 300, 280)
    gprint(to_print, 300, 280)
    gprint(to_print2, 300, 280)
    wait()
    if menu_up(k) then
      active_idx = wrap(1, active_idx-1, #items)
    elseif menu_down(k) then
      active_idx = wrap(1, active_idx+1, #items)
    elseif menu_right(k) then
      if active_idx==1 then speed = bound(1,speed+1,99)
      elseif active_idx==2 then difficulty = bound(1,difficulty+1,3) end
    elseif menu_left(k) then
      if active_idx==1 then speed = bound(1,speed-1,99)
      elseif active_idx==2 then difficulty = bound(1,difficulty-1,3) end
    elseif menu_enter(k) then
      if active_idx == 3 then
        return items[active_idx][2], {speed, difficulty, ...}
      elseif active_idx == 4 then
        return items[active_idx][2], items[active_idx][3]
      else
        active_idx = wrap(1, active_idx + 1, #items)
      end
    elseif menu_escape(k) then
      if active_idx == #items then
        return items[active_idx][2], items[active_idx][3]
      else
        active_idx = #items
      end
    end
  end
end

function main_endless(...)
  replay.endless = {}
  local replay=replay.endless
  replay.pan_buf = ""
  replay.in_buf = ""
  replay.gpan_buf = ""
  replay.mode = "endless"
  P1 = Stack(1, "endless", ...)
  replay.speed = P1.speed
  replay.difficulty = P1.difficulty
  make_local_panels(P1, "000000")
  make_local_gpanels(P1, "000000")
  while true do
    P1:render()
    wait()
    if P1.game_over then
    -- TODO: proper game over.
      write_replay_file()
      return main_dumb_transition, {main_select_mode, "You scored "..P1.score}
    end
    P1:local_run()
    --groundhogday mode
    --[[if P1.CLOCK == 1001 then
      local prev_states = P1.prev_states
      P1 = prev_states[600]
      P1.prev_states = prev_states
    end--]]
  end
end

function main_time_attack(...)
  P1 = Stack(1, "time", ...)
  make_local_panels(P1, "000000")
  while true do
    P1:render()
    wait()
    if P1.game_over or P1.CLOCK == 120*60 then
    -- TODO: proper game over.
      return main_dumb_transition, {main_select_mode, "You scored "..P1.score}
    end
    P1:local_run()
  end
end

function main_net_vs_setup(ip)
  P1, P1_level, P2_level, got_opponent = nil, nil, nil, nil, nil
  P2 = {panel_buffer="", gpanel_buffer=""}
  network_init(ip)
  local my_level, to_print, fake_P2 = 5, nil, P2
  local k = K[1]
  while got_opponent == nil do
    gprint("Waiting for opponent...", 300, 280)
    do_messages()
    wait()
  end
  while P1_level == nil or P2_level == nil do
    to_print = (P1_level and "L" or"Choose l") .. "evel: "..my_level..
        "\nOpponent's level: "..(P2_level or "???")
    gprint(to_print, 300, 280)
    wait()
    do_messages()
    if P1_level then
    elseif menu_enter(k) then
      P1_level = my_level
      net_send("L"..(({[10]=0})[my_level] or my_level))
    elseif menu_up(k) or menu_right(k) then
      my_level = bound(1,my_level+1,10)
    elseif menu_down(k) or menu_left(k) then
      my_level = bound(1,my_level-1,10)
    end
  end
  P1 = Stack(1, "vs", P1_level)
  P2 = Stack(2, "vs", P2_level)
  P2.panel_buffer = fake_P2.panel_buffer
  P2.gpanel_buffer = fake_P2.gpanel_buffer
  P1.garbage_target = P2
  P2.garbage_target = P1
  P2.pos_x = 172
  P2.score_x = 410
  replay.vs = {P="",O="",I="",Q="",R="",in_buf="",
              P1_level=P1_level,P2_level=P2_level}
  ask_for_gpanels("000000")
  ask_for_panels("000000")
  to_print = "Level: "..my_level.."\nOpponent's level: "..(P2_level or "???")
  for i=1,30 do
    gprint(to_print,300, 280)
    do_messages()
    wait()
  end
  while P1.panel_buffer == "" or P2.panel_buffer == ""
    or P1.gpanel_buffer == "" or P2.gpanel_buffer == "" do
    gprint(to_print,300, 280)
    do_messages()
    wait()
  end
  P1:starting_state()
  P2:starting_state()
  return main_net_vs
end

function main_net_vs()
  --STONER_MODE = true
  local end_text = nil
  while true do
    P1:render()
    P2:render()
    wait()
    do_messages()
    if not P1.game_over then
      P1:local_run()
    end
    if not P2.game_over then
      P2:foreign_run()
    end
    if P1.game_over and P2.game_over and P1.CLOCK == P2.CLOCK then
      end_text = "Draw"
    elseif P1.game_over and P1.CLOCK <= P2.CLOCK then
      end_text = "You lose :("
    elseif P2.game_over and P2.CLOCK <= P1.CLOCK then
      end_text = "You win ^^"
    end
    if end_text then
      undo_stonermode()
      write_replay_file()
      close_socket()
      return main_dumb_transition, {main_select_mode, end_text, 45}
    end
  end
end

main_local_vs_setup = multi_func(function()
  local K = K
  local chosen, maybe = {}, {5,5}
  local P1_level, P2_level = nil, nil
  while chosen[1] == nil or chosen[2] == nil do
    to_print = (chosen[1] and "" or "Choose ") .. "P1 level: "..maybe[1].."\n"
        ..(chosen[2] and "" or "Choose ") .. "P2 level: "..(maybe[2])
    gprint(to_print, 300, 280)
    wait()
    for i=1,2 do
      local k=K[i]
      if menu_escape(k) then
        if chosen[i] then
          chosen[i] = nil
        else
          return main_select_mode
        end
      elseif menu_enter(k) then
        chosen[i] = maybe[i]
      elseif menu_up(k) or menu_right(k) then
        if not chosen[i] then
          maybe[i] = bound(1,maybe[i]+1,10)
        end
      elseif menu_down(k) or menu_left(k) then
        if not chosen[i] then
          maybe[i] = bound(1,maybe[i]-1,10)
        end
      end
    end
  end
  to_print = "P1 level: "..maybe[1].."\nP2 level: "..(maybe[2])
  P1 = Stack(1, "vs", chosen[1])
  P2 = Stack(2, "vs", chosen[2])
  P1.garbage_target = P2
  P2.garbage_target = P1
  P2.pos_x = 172
  P2.score_x = 410
  make_local_panels(P1, "000000")
  make_local_gpanels(P1, "000000")
  make_local_panels(P2, "000000")
  make_local_gpanels(P2, "000000")
  for i=1,30 do
    gprint(to_print,300, 280)
    wait()
  end
  P1:starting_state()
  P2:starting_state()
  return main_local_vs
end)

function main_local_vs()
  -- TODO: replay!
  local end_text = nil
  while true do
    P1:render()
    P2:render()
    wait()
    if not P1.game_over then
      P1:local_run()
    end
    if not P2.game_over then
      P2:local_run()
    end
    if P1.game_over and P2.game_over and P1.CLOCK == P2.CLOCK then
      end_text = "Draw"
    elseif P1.game_over and P1.CLOCK <= P2.CLOCK then
      end_text = "P2 wins ^^"
    elseif P2.game_over and P2.CLOCK <= P1.CLOCK then
      end_text = "P1 wins ^^"
    end
    if end_text then
      return main_dumb_transition, {main_select_mode, end_text, 45}
    end
  end
end

function main_replay_vs()
  local replay = replay.vs
  P1 = Stack(1, "vs", replay.P1_level or 5)
  P2 = Stack(2, "vs", replay.P2_level or 5)
  P1.ice = true
  P1.garbage_target = P2
  P2.garbage_target = P1
  P2.pos_x = 172
  P2.score_x = 410
  P1.input_buffer = replay.in_buf
  P1.panel_buffer = replay.P
  P1.gpanel_buffer = replay.Q
  P2.input_buffer = replay.I
  P2.panel_buffer = replay.O
  P2.gpanel_buffer = replay.R
  P1.max_runs_per_frame = 1
  P2.max_runs_per_frame = 1
  P1:starting_state()
  P2:starting_state()
  local end_text = nil
  local run = true
  while true do
    mouse_panel = nil
    P1:render()
    P2:render()
    if mouse_panel then
      local str = "Panel info:\nrow: "..mouse_panel[1].."\ncol: "..mouse_panel[2]
      for k,v in spairs(mouse_panel[3]) do
        str = str .. "\n".. k .. ": "..tostring(v)
      end
      gprint(str, 350, 400)
    end
    wait()
    if this_frame_keys["return"] then
      run = not run
    end
    if this_frame_keys["\\"] then
      run = false
    end
    if run or this_frame_keys["\\"] then
      if not P1.game_over then
        P1:foreign_run()
      end
      if not P2.game_over then
        P2:foreign_run()
      end
    end
    if P1.game_over and P2.game_over and P1.CLOCK == P2.CLOCK then
      end_text = "Draw"
    elseif P1.game_over and P1.CLOCK <= P2.CLOCK then
      end_text = "You lose :("
    elseif P2.game_over and P2.CLOCK <= P1.CLOCK then
      end_text = "You win ^^"
    end
    if end_text then
      return main_dumb_transition, {main_select_mode, end_text}
    end
  end
end

function main_replay_endless()
  local replay = replay.endless
  if replay == nil or replay.speed == nil then
    return main_dumb_transition,
      {main_select_mode, "I don't have an endless replay :("}
  end
  P1 = Stack(1, "endless", replay.speed, replay.difficulty)
  P1.max_runs_per_frame = 1
  P1.input_buffer = table.concat({replay.in_buf})
  P1.panel_buffer = replay.pan_buf
  P1.gpanel_buffer = replay.gpan_buf
  P1.speed = replay.speed
  P1.difficulty = replay.difficulty
  while true do
    P1:render()
    wait()
    if P1.game_over then
    -- TODO: proper game over.
      return main_dumb_transition, {main_select_mode, "You scored "..P1.score}
    end
    P1:foreign_run()
  end
end

function main_replay_puzzle()
  local replay = replay.puzzle
  if replay.in_buf == nil or replay.in_buf == "" then
    return main_dumb_transition,
      {main_select_mode, "I don't have a puzzle replay :("}
  end
  P1 = Stack(1, "puzzle")
  P1.max_runs_per_frame = 1
  P1.input_buffer = replay.in_buf
  P1:set_puzzle_state(unpack(replay.puzzle))
  local run = true
  while true do
    mouse_panel = nil
    P1:render()
    if mouse_panel then
      local str = "Panel info:\nrow: "..mouse_panel[1].."\ncol: "..mouse_panel[2]
      for k,v in spairs(mouse_panel[3]) do
        str = str .. "\n".. k .. ": "..tostring(v)
      end
      gprint(str, 350, 400)
    end
    wait()
    if this_frame_keys["return"] then
      run = not run
    end
    if this_frame_keys["\\"] then
      run = false
    end
    if run or this_frame_keys["\\"] then
      if P1.n_active_panels == 0 and
          P1.prev_active_panels == 0 then
        if P1:puzzle_done() then
          return main_dumb_transition, {main_select_mode, "You win!"}
        elseif P1.puzzle_moves == 0 then
          return main_dumb_transition, {main_select_mode, "You lose :("}
        end
      end
      P1:foreign_run()
    end
  end
end

function make_main_puzzle(puzzles)
  local awesome_idx, ret = 1, nil
  function ret()
    replay.puzzle = {}
    local replay = replay.puzzle
    P1 = Stack(1, "puzzle")
    if awesome_idx == nil then
      awesome_idx = math.random(#puzzles)
    end
    P1:set_puzzle_state(unpack(puzzles[awesome_idx]))
    replay.puzzle = puzzles[awesome_idx]
    replay.in_buf = ""
    while true do
      P1:render()
      wait()
      if P1.n_active_panels == 0 and
          P1.prev_active_panels == 0 then
        if P1:puzzle_done() then
          awesome_idx = (awesome_idx % #puzzles) + 1
          write_replay_file()
          if awesome_idx == 1 then
            return main_dumb_transition, {main_select_puzz, "You win!"}
          else
            return main_dumb_transition, {ret, "You win!"}
          end
        elseif P1.puzzle_moves == 0 then
          write_replay_file()
          return main_dumb_transition, {main_select_puzz, "You lose :("}
        end
      end
      P1:local_run()
    end
  end
  return ret
end

do
  local items = {}
  for key,val in spairs(puzzle_sets) do
    items[#items+1] = {key, make_main_puzzle(val)}
  end
  items[#items+1] = {"Back", main_select_mode}
  function main_select_puzz()
    local active_idx = 1
    local k = K[1]
    while true do
      local to_print = ""
      local arrow = ""
      for i=1,#items do
        if active_idx == i then
          arrow = arrow .. ">"
        else
          arrow = arrow .. "\n"
        end
        to_print = to_print .. "   " .. items[i][1] .. "\n"
      end
      gprint(arrow, 300, 280)
      gprint(to_print, 300, 280)
      wait()
      if menu_up(k) then
        active_idx = wrap(1, active_idx-1, #items)
      elseif menu_down(k) then
        active_idx = wrap(1, active_idx+1, #items)
      elseif menu_enter(k) then
        return items[active_idx][2], items[active_idx][3]
      elseif menu_escape(k) then
        if active_idx == #items then
          return items[active_idx][2], items[active_idx][3]
        else
          active_idx = #items
        end
      end
    end
  end
end

function main_config_input()
  local pretty_names = {"Up", "Down", "Left", "Right", "A", "B", "L", "R"}
  local items, active_idx = {}, 1
  local k = K[1]
  local active_player = 1
  local function get_items()
    items = {[0]={"Player ", ""..active_player}}
    for i=1,#key_names do
      items[#items+1] = {pretty_names[i], k[key_names[i]] or "none"}
    end
    items[#items+1] = {"Set all keys", ""}
    items[#items+1] = {"Back", "", main_select_mode}
  end
  local function print_stuff()
    local to_print, to_print2, arrow = "", "", ""
    for i=0,#items do
      if active_idx == i then
        arrow = arrow .. ">"
      else
        arrow = arrow .. "\n"
      end
      to_print = to_print .. "   " .. items[i][1] .. "\n"
      to_print2 = to_print2 .. "                  " .. items[i][2] .. "\n"
    end
    gprint(arrow, 300, 280)
    gprint(to_print, 300, 280)
    gprint(to_print2, 300, 280)
  end
  local function set_key(idx)
    local brk = false
    while not brk do
      get_items()
      items[idx][2] = "___"
      print_stuff()
      wait()
      for key,val in pairs(this_frame_keys) do
        if val then
          k[key_names[idx]] = key
          brk = true
        end
      end
    end
  end
  while true do
    get_items()
    print_stuff()
    wait()
    if menu_up(K[1]) then
      active_idx = wrap(1, active_idx-1, #items)
    elseif menu_down(K[1]) then
      active_idx = wrap(1, active_idx+1, #items)
    elseif menu_left(K[1]) then
      active_player = wrap(1, active_player-1, 2)
      k=K[active_player]
    elseif menu_right(K[1]) then
      active_player = wrap(1, active_player+1, 2)
      k=K[active_player]
    elseif menu_enter(K[1]) then
      if active_idx <= #key_names then
        set_key(active_idx)
        write_key_file()
      elseif active_idx == #key_names + 1 then
        for i=1,8 do
          set_key(i)
          write_key_file()
        end
      else
        return items[active_idx][3], items[active_idx][4]
      end
    elseif menu_escape(K[1]) then
      if active_idx == #items then
        return items[active_idx][3], items[active_idx][4]
      else
        active_idx = #items
      end
    end
  end
end

function main_dumb_transition(next_func, text, time)
  text = text or ""
  time = time or 0
  local t = 0
  local k = K[1]
  while true do
    gprint(text, 300, 280)
    wait()
    if t >= time and (menu_enter(k) or menu_escape(k)) then
      return next_func
    end
    t = t + 1
  end
end
