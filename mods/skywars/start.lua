
local start = {}
function skywars.may_start_game(lobby)
  local playercount = #skywars.get_lobby_players(lobby)
  if playercount >=2 and not start[lobby] and lobby ~= 0 then
    start[lobby] = true
    skywars.chat_send_all_lobby(lobby, "Game starts in 15 seconds!")
    for _,player in ipairs(skywars.get_lobby_players(lobby)) do
      subgames.add_bothud(player, "Game starts in 15 seconds!", 0xFFAE19, 2)
    end
    minetest.after(5, function()
      skywars.chat_send_all_lobby(lobby, "Game starts in 10 seconds!")
      for _,player in ipairs(skywars.get_lobby_players(lobby)) do
        subgames.add_bothud(player, "Game starts in 10 seconds!", 0xFFAE19, 2)
      end
      minetest.after(5, function()
        skywars.chat_send_all_lobby(lobby, "Game starts in 5 seconds!")
        for _,player in ipairs(skywars.get_lobby_players(lobby)) do
          subgames.add_bothud(player, "Game starts in 5 seconds!", 0xFFAE19, 2)
        end
        minetest.after(5, function()
          playercount = #skywars.get_lobby_players(lobby)
          if playercount >= 2 then
            local msg = core.colorize("red", "Game Start now!")
            skywars.chat_send_all_lobby(lobby, msg)
            for _,player in ipairs(skywars.get_lobby_players(lobby)) do
              subgames.add_mithud(player, "Game starts now!", 0xFF0000, 2)
            end
            skywars.start_game(lobby)
          else start[lobby] = false
            skywars.chat_send_all_lobby(lobby, "Game start stoped, becouse there are not enough players.")
          end
        end)
      end)
    end)
  end
end

function skywars.reset_map(lobby)
  for pos, node in pairs(skywars.lobbys[lobby].mapblocks) do
    minetest.set_node(minetest.string_to_pos(pos), node)
  end
  worldedit.clear_objects(skywars.lobbys[lobby].mappos1, skywars.lobbys[lobby].mappos2)
  skywars.lobbys[lobby].mapblocks = {}
end

function skywars.start_game(lobby)
  minetest.log("warning", "Skywars: Starting Game of the lobby "..lobby)
  local players = skywars.get_lobby_players(lobby)
  local playercount = #players
  local seekercount
  if lobby == 0 then
    return
  end
  skywars.lobbys[lobby].ingame = true
  skywars.fill_chests(lobby)
  local used = {}
  for _, player in pairs(skywars.get_lobby_players(lobby)) do
    local place = math.random(1, skywars.lobbys[lobby].playercount)
    while used[place] do
      place = math.random(1, skywars.lobbys[lobby].playercount)
    end
    used[place] = true
    local name = player:get_player_name()
    skywars.lobbys[lobby].players[name] = true
    subgames.clear_inv(player)
    skywars.give_kit_items(name)
    player:set_pos(skywars.lobbys[lobby].pos[place])
    sfinv.set_page(player, "3d_armor:armor")
    subgames.add_bothud(player, "Teaming is not allowed!", 0xFF0000, 100000)
  end
  local starttime = os.time()
  skywars.lobbys[lobby].starttime = starttime
  minetest.after(900, function() --  Time when game times out 60*15
    if starttime == skywars.lobbys[lobby].starttime and skywars.lobbys[lobby].ingame then
      -- Game timed out (was longer then 15min)
      local msg = minetest.colorize("red", "Restarting Game (Game timed out!)")
      skywars.chat_send_all_lobby(lobby, msg)
      for _,player in ipairs(skywars.get_lobby_players(lobby)) do
        skywars.leave_game(player)
        skywars.join_game(player, lobby)
      end
      skywars.win(lobby)
    end
  end)
end

function skywars.get_player_count(lobby)
  local player = 0
  local lastname
  if lobby ~= 0 then
    for name, role in pairs(skywars.lobbys[lobby].players) do
      if role == true then
        player = player+1
        lastname = name
      end
    end
  end
  return player, lastname
end

function skywars.win(lobby)
  if lobby and lobby ~= 0 and skywars.lobbys[lobby].ingame then
    local count, winner = skywars.get_player_count(lobby)
    if count <= 1 then
      if count > 0 then
        skywars.chat_send_all_lobby(lobby, winner.." has won!")
        minetest.log("warning", "Skywars: "..winner.." won the Game of the lobby "..lobby)
        money.set_money(winner, money.get_money(winner)+20)
      	minetest.chat_send_player(winner, "[CoinSystem] You have receive 20 Coins!")
        skywars.chat_send_all_lobby(lobby, "Server Restarts in 5 sec.")
        for _,player in ipairs(skywars.get_lobby_players(lobby)) do
          subgames.add_mithud(player, winner.." has won!", 0xFF0000, 3)
        end
      end
      minetest.after(5, function()
        for _, player in pairs(skywars.get_lobby_players(lobby)) do
          local name = player:get_player_name()
          player:set_pos(skywars.lobbys[lobby].specpos)
          subgames.clear_inv(player)
          subgames.unspectate(player)
          skywars.lobbys[lobby].players[name] = true
          sfinv.set_page(player, "skywars:maps")
          subgames.add_bothud(player, "Teaming is not allowed!", 0xFF0000, 0)
        end
        skywars.reset_map(lobby)
        skywars.win(lobby)
      end)
      skywars.lobbys[lobby].ingame = false
      start[lobby] = false
    end
  else skywars.may_start_game(lobby)
  end
end
