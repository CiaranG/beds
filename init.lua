
-- Table of players currently in bed
--   key = player name, value = the bed node position
local players_in_bed = {}

local beds_list = {
	{ "Red Bed", "red"},
	{ "Orange Bed", "orange"},	
	{ "Yellow Bed", "yellow"},
	{ "Green Bed", "green"},
	{ "Blue Bed", "blue"},
	{ "Violet Bed", "violet"},
	{ "Black Bed", "black"},
	{ "Grey Bed", "grey"},
	{ "White Bed", "white"},
}

local remove_from_bed = function(player)
	local playername = player:get_player_name()
	if players_in_bed[playername] then
		local meta = minetest.get_meta(players_in_bed[playername])
		meta:set_string("player", "")
		players_in_bed[player] = nil

		player:setpos(beds_player_spawns[playername])
		if health then
			health.set_attr(playername, "asleep", 0)
		else
			player:set_physics_override(1, 1, 1)
		end
	end
end

for i in ipairs(beds_list) do
	local beddesc = beds_list[i][1]
	local colour = beds_list[i][2]

	minetest.register_node("beds:bed_bottom_"..colour, {
		description = beddesc,
		drawtype = "nodebox",
		tiles = {"beds_bed_top_bottom_"..colour..".png", "default_wood.png",  "beds_bed_side_"..colour..".png",  "beds_bed_side_"..colour..".png",  "beds_bed_side_"..colour..".png",  "beds_bed_side_"..colour..".png"},
		paramtype = "light",
		paramtype2 = "facedir",
		stack_max = 1,
		groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
		sounds = default.node_sound_wood_defaults(),
		node_box = {
			type = "fixed",
			fixed = {
						-- bed
						{-0.5, 0.0, -0.5, 0.5, 0.3125, 0.5},
						
						-- legs
						{-0.5, -0.5, -0.5, -0.4, 0.0, -0.4},
						{0.4, 0.0, -0.4, 0.5, -0.5, -0.5},
					}
		},
		selection_box = {
			type = "fixed",
			fixed = {
						{-0.5, -0.5, -0.5, 0.5, 0.3125, 1.5},
					}
		},

		after_place_node = function(pos, placer, itemstack)
			local node = minetest.env:get_node(pos)
			local p = {x=pos.x, y=pos.y, z=pos.z}
			local param2 = node.param2
			node.name = "beds:bed_top_"..colour
			if param2 == 0 then
				pos.z = pos.z+1
			elseif param2 == 1 then
				pos.x = pos.x+1
			elseif param2 == 2 then
				pos.z = pos.z-1
			elseif param2 == 3 then
				pos.x = pos.x-1
			end
			if minetest.registered_nodes[minetest.env:get_node(pos).name].buildable_to  then
				minetest.env:set_node(pos, node)
			else
				minetest.env:remove_node(p)
				return true
			end
		end,
			
		on_destruct = function(pos)
			local node = minetest.env:get_node(pos)

			-- If there's a player in a destroyed/dug bed, they need removing
			for playername, bedpos in pairs(players_in_bed) do
				if vector.equals(bedpos, pos) then
					local player = minetest.get_player_by_name(playername)
					if player then
						remove_from_bed(player)
					end
				end
			end

			local param2 = node.param2
			if param2 == 0 then
				pos.z = pos.z+1
			elseif param2 == 1 then
				pos.x = pos.x+1
			elseif param2 == 2 then
				pos.z = pos.z-1
			elseif param2 == 3 then
				pos.x = pos.x-1
			end
			if( minetest.env:get_node({x=pos.x, y=pos.y, z=pos.z}).name == "beds:bed_top_"..colour ) then
				if( minetest.env:get_node({x=pos.x, y=pos.y, z=pos.z}).param2 == param2 ) then
					minetest.env:remove_node(pos)
				end	
			end

		end,
		
		on_rightclick = function(pos, node, clicker)
			if not clicker:is_player() then
				return
			end

			local playername = clicker:get_player_name()

			local meta = minetest.get_meta(pos)
			local bedplayer = meta:get_string("player")

			if playername == bedplayer then

				remove_from_bed(clicker)

			elseif bedplayer == "" then

				-- Save the spawn position before we move the player into
				-- the bed.
				beds_player_spawns[playername] = clicker:getpos()
				local file = io.open(minetest.get_worldpath().."/beds_player_spawns", "w")
				if file then
					file:write(minetest.serialize(beds_player_spawns))
					file:close()
				end

				meta:set_string("player", playername)
				players_in_bed[playername] = vector.new(pos)

				if health then
					health.set_attr(playername, "asleep", 1)
				else
					clicker:set_physics_override(0, 0, 0)
				end

				local param2 = node.param2
				if param2 == 0 then
					pos.z = pos.z+1
					clicker:set_look_yaw(math.pi)
				elseif param2 == 1 then
					pos.x = pos.x+1
					clicker:set_look_yaw(0.5*math.pi)
				elseif param2 == 2 then
					pos.z = pos.z-1
					clicker:set_look_yaw(0)
				elseif param2 == 3 then
					pos.x = pos.x-1
					clicker:set_look_yaw(1.5*math.pi)
				end
				pos.y = pos.y - 0.5
				clicker:setpos(pos)

			end
		end
	})
	
	minetest.register_node("beds:bed_top_"..colour, {
		drawtype = "nodebox",
		tiles = {"beds_bed_top_top_"..colour..".png", "default_wood.png",  "beds_bed_side_top_r_"..colour..".png",  "beds_bed_side_top_l_"..colour..".png",  "beds_bed_top_front.png",  "beds_bed_side_"..colour..".png"},
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
		sounds = default.node_sound_wood_defaults(),
		node_box = {
			type = "fixed",
			fixed = {
						-- bed
						{-0.5, 0.0, -0.5, 0.5, 0.3125, 0.5},
						{-0.4375, 0.3125, 0.1, 0.4375, 0.4375, 0.5},
						
						-- legs
						{-0.4, 0.0, 0.4, -0.5, -0.5, 0.5},
						{0.5, -0.5, 0.5, 0.4, 0.0, 0.4},
					}
		},
		selection_box = {
			type = "fixed",
			fixed = {
						{0, 0, 0, 0, 0, 0},
					}
		},
	})
	
	minetest.register_alias("beds:bed_"..colour, "beds:bed_bottom_"..colour)
	
	minetest.register_craft({
		output = "beds:bed_"..colour,
		recipe = {
			{"wool:"..colour, "wool:"..colour, "wool:white", },
			{"default:stick", "", "default:stick", }
		}
	})
	
	minetest.register_craft({
		output = "beds:bed_"..colour,
		recipe = {
			{"wool:white", "wool:"..colour, "wool:"..colour, },
			{"default:stick", "", "default:stick", }
		}
	})
	
end

minetest.register_alias("beds:bed_bottom", "beds:bed_bottom_blue")
minetest.register_alias("beds:bed_top", "beds:bed_top_blue")
minetest.register_alias("beds:bed", "beds:bed_bottom_blue")

beds_player_spawns = {}
local file = io.open(minetest.get_worldpath().."/beds_player_spawns", "r")
if file then
	beds_player_spawns = minetest.deserialize(file:read("*all"))
	file:close()
end

local timer = 0
local wait = false
minetest.register_globalstep(function(dtime)

	if wait then return end

	if timer < 4 then
		timer = timer+dtime
		return
	end
	timer = 0

	if minetest.env:get_timeofday() < 0.2 or minetest.env:get_timeofday() > 0.805 then

		local players = minetest.get_connected_players()
		-- Don't want to do this when nobody is online...
		if #players > 0 then
			allinbed = true
			for _, player in pairs(players) do
				if not players_in_bed[player:get_player_name()] then
					allinbed = false
					break
				end
			end

			if allinbed then
				minetest.chat_send_all("Good night!!!")
				minetest.after(2, function()
					minetest.env:set_timeofday(0.23)
					wait = false
				end)
				wait = true
			end

		end
	end
end)

minetest.register_on_shutdown(function(player)
	local players = minetest.get_connected_players()
	for _, player in pairs(players) do
		if players_in_bed[player:get_player_name()] then
			remove_from_bed(player)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	remove_from_bed(player)
end)

minetest.register_on_respawnplayer(function(player)
	local playername = player:get_player_name()
	remove_from_bed(player)
	if beds_player_spawns[playername] then
		player:setpos(beds_player_spawns[playername])
		return true
	end
	return false
end)

if minetest.setting_get("log_mods") then
	minetest.log("action", "beds loaded")
end

