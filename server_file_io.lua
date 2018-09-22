local lfs = require("lfs")
local csvfile = require("simplecsv")

function isFile(name)
    if type(name)~="string" then return false end
    if not isDir(name) then
        return os.rename(name,name) and true or false
        -- note that the short evaluation is to
        -- return false instead of a possible nil
    end
    return false
end

function isFileOrDir(name)
    if type(name)~="string" then return false end
    return os.rename(name, name) and true or false
end

function isDir(name)
    if type(name)~="string" then return false end
    local cd = lfs.currentdir()
    local is = lfs.chdir(name) and true or false
    lfs.chdir(cd)
    return is
end

function mkDir(path)
  print("mkDir(path)")
  local sep, pStr = package.config:sub(1, 1), ""
  for dir in path:gmatch("[^" .. sep .. "]+") do
    pStr = pStr .. dir .. sep
    lfs.mkdir(pStr)
  end
  print("got to the end of mkDir(path)")
end

function write_players_file() pcall(function()
  local f = assert(io.open("players.txt", "w"))
  io.output(f)
  io.write(json.encode(playerbase.players))
  io.close(f)
end) end

function read_players_file() pcall(function()
  local f = assert(io.open("players.txt", "r"))
  io.input(f)
  playerbase.players = json.decode(io.read("*all"))
  io.close(f)
end) end

function write_deleted_players_file() pcall(function()
  local f = assert(io.open("deleted_players.txt", "w"))
  io.output(f)
  io.write(json.encode(playerbase.players))
  io.close(f)
end) end

function read_deleted_players_file() pcall(function()
  local f = assert(io.open("deleted_players.txt", "r"))
  io.input(f)
  playerbase.deleted_players = json.decode(io.read("*all"))
  io.close(f)
end) end

function write_leaderboard_file() pcall(function()
  -- local f = assert(io.open("leaderboard.txt", "w"))
  -- io.output(f)
  -- io.write(json.encode(leaderboard.players))
  -- io.close(f)
  --now also write a CSV version of the file
  --local csv = "user_id,user_name,rating,placement_done,placement_matches,final_placement_rating,ranked_games_played,ranked_games_won"
  local leaderboard_table = {}
  leaderboard_table[#leaderboard_table+1] = {"user_id","user_name","rating","placement_done","placement_matches","final_placement_rating","ranked_games_played","ranked_games_won"}
  
  for user_id,v in pairs(leaderboard.players) do
    leaderboard_table[#leaderboard_table+1] = 
    {user_id, v.user_name,v.rating,tostring(v.placement_done or ""),json.encode(v.placement_matches) or "",v.final_placement_rating,v.ranked_games_played,v.ranked_games_won}
  end
  csvfile.write('./leaderboard.csv', leaderboard_table)
end) end

function read_leaderboard_file() pcall(function()
  -- local f = assert(io.open("leaderboard.txt", "r"))
  -- io.input(f)
  -- leaderboard.players = json.decode(io.read("*all"))
  -- io.close(f)
  
  local csv_table = csvfile.read('./leaderboard.csv')
  for row=2,#csv_table do
    csv_table[row][1] = tostring(csv_table[row][1])
    leaderboard.players[csv_table[row][1]] = {}
    for col=1, #csv_table[1] do
      --Note csv_table[row][1] will be the player's user_id
      --csv_table[1][col] will be a property name such as "rating"
      if csv_table[row][col] == '' then
        csv_table[row][col] = nil
      end
      --player with this user_id gets this property equal to the csv_table cell's value
      if csv_table[1][col] == "user_name" then
        leaderboard.players[csv_table[row][1]][csv_table[1][col]] = tostring(csv_table[row][col])
      elseif csv_table[1][col] == "rating" then
        leaderboard.players[csv_table[row][1]][csv_table[1][col]] = tonumber(csv_table[row][col])
      elseif csv_table[1][col] == "placement_done" then
        leaderboard.players[csv_table[row][1]][csv_table[1][col]] = csv_table[row][col] and true and string.lower(csv_table[row][col]) ~= "false"
      elseif csv_table[1][col] == "placement_matches" then
        leaderboard.players[csv_table[row][1]][csv_table[1][col]] = json.decode(csv_table[row][col])
      else
        leaderboard.players[csv_table[row][1]][csv_table[1][col]] = csv_table[row][col]
      end
    end
  end

end) end

function write_replay_file(replay, path, filename) pcall(function()
  print("about to open new replay file for writing")
  mkDir(path)
  local f = assert(io.open(path.."/"..filename, "w"))
  print("past file open")
  io.output(f)
  io.write(json.encode(replay))
  io.close(f)
  print("finished write_replay_file()")
end) end

function read_csprng_seed_file() pcall(function()
  local f = io.open("csprng_seed.txt", "r")
  if f then
    io.input(f)
    csprng_seed = io.read("*all")
    io.close(f)
  else
    print("csprng_seed.txt could not be read.  Writing a new default (2000) csprng_seed.txt")
    local new_file = io.open("csprng_seed.txt", "w")
    io.output(new_file)
    io.write("2000")
    io.close(new_file)
    csprng_seed = "2000"
  end
  if tonumber(csprng_seed) then
    local tempvar = tonumber(csprng_seed)
    csprng_seed = tempvar
  else 
    print("ERROR: csprng_seed.txt content is not numeric.  Using default (2000) as csprng_seed")
    csprng_seed = 2000
  end
end) end

--old
-- function write_replay_file(replay_table, file_name) pcall(function()
  -- local f = io.open(file_name, "w")
  -- io.output(f)
  -- io.write(json.encode(replay_table))
  -- io.close(f)
-- end) end