/*---------------------------------------------------------
  Make sure client gets all the needed lua files.
---------------------------------------------------------*/
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "base_scoreboard.lua" )
include( 'shared.lua' )
/*---------------------------------------------------------
  Make sure client gets all the texture files
---------------------------------------------------------*/
resource.AddFile("materials/traps/trap_building.vmt")
resource.AddFile("materials/traps/trap_building.vtf")
resource.AddFile("materials/traps/trap_testing.vmt")
resource.AddFile("materials/traps/trap_testing.vtf")

/*---------------------------------------------------------
Some shit
---------------------------------------------------------*/
timer.Create( "adverts", 120, 0, function()
	for k,v in pairs(player.GetAll()) do
		if (GAME_STATUS == "Trap Building") then
			v:SendLua("chat.AddText(Color(255, 255, 255, 255), 'Type ', Color(100, 255, 100, 255), '/ready', Color(255, 255, 255, 255), ' in chat if you are done building your traps')")
		end
	end
end)

timer.Create( "adverts2", 180, 0, function()
	for k,v in pairs(player.GetAll()) do
		v:SendLua("chat.AddText(Color(255, 255, 255, 255), 'Bind a key to ', Color(100, 255, 100, 255), '+teamtalk', Color(255, 255, 255, 255), ' to talk only to your teammates')")
	end
end)
/*---------------------------------------------------------
  Set stuff up on server startup
---------------------------------------------------------*/
GAME_STATUS = "Trap Building"
RunConsoleCommand("sv_alltalk", "0")
RunConsoleCommand("sbox_godmode", "1")
RunConsoleCommand("sbox_noclip", "1")
RunConsoleCommand("sbox_plpldamage", "0")
for k,ply in pairs(player.GetAll()) do
	ply:SetDeaths(0)
end
/*---------------------------------------------------------
  Global chat print function
---------------------------------------------------------*/
function printAction( mssg )
	for k,ply in pairs(player.GetAll()) do
		ply:ChatPrint( mssg )
	end
end

/*---------------------------------------------------------
  Open the team menu for the player when he
  spawns for the first time
---------------------------------------------------------*/
function GM:PlayerInitialSpawn( ply )
	ply:SetTeam(TEAM_GUEST)
	ply:ConCommand( "team_menu" )
end 

/*---------------------------------------------------------
  If all players are ready before the time pases,
  they can type "/ready" in chat and when all
  players say that, the new round will begin.
---------------------------------------------------------*/
GAME_PLAYERVOTES = 0
for k,ply in pairs(player.GetAll()) do
	ply["ready"] = 0
end
function PlayerChat( ply, text, toall )
	if (text == "/ready") then
		if (ply["ready"] != 1 and ply:Team() != TEAM_GUEST) then
			GAME_PLAYERVOTES = GAME_PLAYERVOTES + 1
			mssg = tostring(#player.GetAll() - GAME_PLAYERVOTES).." votes left to change GamePlay"
			printAction( mssg )
		end
		ply["ready"] = 1
	end
	if (GAME_PLAYERVOTES == (#player.GetAll() - team.NumPlayers(1))) then
		GAME_PLAYERVOTES = 0
		for k,ply in pairs(player.GetAll()) do
			ply["ready"] = 0
		end
		if (GAME_STATUS == "Trap Building" or GAME_STATUS == "Trap Testing") then
			Timer = -1
		end
	end
end
				
/*---------------------------------------------------------
  Start the game timer, when there are at least
  2 players on the server
---------------------------------------------------------*/
function CheckPlyNum()
	if (team.NumPlayers(2) == 1 and team.NumPlayers(3) == 1) then
		StartTimer()
	end
	if (team.NumPlayers(2) == 0 or team.NumPlayers(3) == 0) then
		StopTimer()
	end
end

/*---------------------------------------------------------
  The actual timer itself
---------------------------------------------------------*/
function StartTimer()
	Timer = 1200
	timer.Create( "timer", 1, 0, function()
		Timer = Timer - 1
		
		umsg.Start("TimerData")
			umsg.Long( Timer )
			umsg.String( GAME_STATUS )
		umsg.End()

		if (Timer < 0 and GAME_STATUS == "Trap Building") then
			GAME_STATUS = "Trap Testing"
			team.SetSpawnPoint( TEAM_A, "info_player_counterterrorist" )
			team.SetSpawnPoint( TEAM_B, "info_player_terrorist" )
			RunConsoleCommand("sbox_godmode", "0")
			RunConsoleCommand("sbox_noclip", "0")
			Timer = 1200
			for k, ply in pairs(player.GetAll()) do
				ply:Spawn()
			end
			elseif(Timer < 0 and GAME_STATUS == "Trap Testing") then
			GAME_STATUS = "Trap Building"
			team.SetSpawnPoint( TEAM_A, "info_player_terrorist" )
			team.SetSpawnPoint( TEAM_B, "info_player_counterterrorist" )
			RunConsoleCommand("sbox_godmode", "1")
			RunConsoleCommand("sbox_noclip", "1")	
			Timer = 1200
			for k, ply in pairs(player.GetAll()) do
				if (ply:Team() != TEAM_A_DEAD or ply:Team() != TEAM_B_DEAD) then
					ply:Spawn()
				elseif (ply:Team() == TEAM_A_DEAD) then
					ply:SetTeam(TEAM_A)
				elseif (ply:Team() == TEAM_B_DEAD) then
					ply:SetTeam(TEAM_B)
				end
			end
		end
	end)
end

function StopTimer()
	timer.Stop("timer")
	umsg.Start("TimerDataBck")
		umsg.Long( 0 )
		umsg.String( "Waiting for players" )
	umsg.End()
end
/*---------------------------------------------------------
  Desc
---------------------------------------------------------*/
function CheckSpec( ply, newteam )
	for k,pl in pairs(player.GetAll()) do
		if (pl:Team() == TEAM_GUEST and pl["spectate"] == ply or pl:Team() == TEAM_GUEST and newteam == TEAM_GUEST) then
			pl:Spectate(6)
		end
	end
end
			
function GM:PlayerDisconnected( ply )
	ply:SetTeam(TEAM_GUEST)
	CheckSpec( ply, NONE )
	CheckPlyNum()
end

function GM:PlayerSelectSpawn( ply )
	local spawnpoints = ents.FindByClass(team.GetSpawnPoint(ply:Team())[1])
	local rs = math.random(#spawnpoints)
	return spawnpoints[rs]
end

function GM:PlayerDeathThink( ply )
	if (GAME_STATUS == "Trap Testing") then
		if (ply:Team() == TEAM_A) then
			ply:SetTeam(TEAM_A_DEAD)
		elseif(ply:Team() == TEAM_B) then
			ply:SetTeam(TEAM_B_DEAD)
		elseif (ply:Team() == TEAM_A_DEAD and GAME_STATUS == "Trap Testing" or ply:Team() == TEAM_B_DEAD and GAME_STATUS == "Trap Testing") then
			ply:Spectate( OBS_MODE_ROAMING )
			if ply.SpawnSpecPos then
				ply:SetPos(ply.SpawnSpecPos)
				ply:SetEyeAngles(ply.SpawnSpecAng)
				ply.SpawnSpecPos = nil
				ply.SpawnSpecAng = nil
			end
		end
		return false
	elseif (GAME_STATUS == "Trap Building" and ply:Team() != TEAM_GUEST) then
		ply:Spawn()
	end
end

function GM:PlayerDeath( ply )
	if (GAME_STATUS == "Trap Testing") then
		if (team.TotalDeaths(4) == team.NumPlayers(4)) then
			for k,v in pairs(player.GetAll()) do
				v:ChatPrint("Team A has lost the game. The round will restart in a few seconds.")
			end
			timer.Create( "alldied", 4, 0, function()
				Timer = -1
				for _,player in pairs(player.GetAll()) do
					player:SetDeaths(0)
				end
				timer.Destroy("alldied")
			end)
		elseif (team.TotalDeaths(5) == team.NumPlayers(5)) then
			for k,v in pairs(player.GetAll()) do
				v:ChatPrint("Team B has lost the game. The round will restart in a few seconds.")
			end
			timer.Create( "alldied", 4, 0, function()
				Timer = -1
				for _,player in pairs(player.GetAll()) do
					player:SetDeaths(0)
				end
				timer.Destroy("alldied")
			end)
		end
	end
end

function GM:DoPlayerDeath( ply )
	ply.SpawnSpecPos = ply:GetPos() + Vector(0,0,64)
	ply.SpawnSpecAng = ply:GetAimVector():Angle()
end

function GM:PlayerCanHearPlayersVoice( listener, talker )
	if(talker["alltalk"]) then
		return true
	else
		if(listener:Team() != talker:Team()) then
			return false
		else
			return true
		end
	end
end

concommand.Add("+teamtalk", function( ply )
	ply["alltalk"] = false
	ply:ConCommand("+voicerecord")
end)

concommand.Add("-teamtalk", function( ply )
	ply:ConCommand("-voicerecord")
	ply["alltalk"] = true
end)

function GM:CanPlayerSuicide( ply )
	if (ply:Team() == TEAM_GUEST) then
		return false
	end
	return true
end

function GM:CanTool( ply, tr, toolmode )
	if (toolmode == "adv_duplicator") then
		ply:ChatPrint("Advanced Duplicator is not allowed!")
		return false
	end
	return true
end

function GM:PlayerGiveSWEP( ply, class, wep )
	ply:ChatPrint("You are not allowed to use weapons!")
	return false
end

function GM:PlayerSpawnEffect( ply, mdl )
	if (GAME_STATUS == "Trap Testing") then
		ply:ChatPrint("You are not allowed to spawn that when testing traps!")
		return false
	end
	return true
end

function GM:PlayerSpawnNPC( ply, npc, npcwep )
	if (GAME_STATUS == "Trap Testing") then
		ply:ChatPrint("You are not allowed to spawn that when testing traps!")
		return false
	end
	return true
end

function GM:PlayerSpawnProp( ply, mdl )
	if (GAME_STATUS == "Trap Testing") then
		ply:ChatPrint("You are not allowed to spawn that when testing traps!")
		return false
	end
	return true
end

function GM:PlayerSpawnRagdoll( ply, mdl, ent )
	if (GAME_STATUS == "Trap Testing") then
		ply:ChatPrint("You are not allowed to spawn that when testing traps!")
		return false
	end
	return true
end

function GM:PlayerSpawnSENT( ply, sent )
	if (GAME_STATUS == "Trap Testing") then
		ply:ChatPrint("You are not allowed to spawn that when testing traps!")
		return false
	end
	return true
end

function GM:PlayerSpawnSWEP( ply, wep )
	ply:ChatPrint("You are not allowed to use weapons!")
	return false
end

function GM:PlayerUse( ply, ent )
	if (ply:Team() == TEAM_GUEST) then
		return false
	end
	return true
end

local specmode = 3
local index = 1

function GM:KeyPress( ply, key )
	if (ply:Team() == TEAM_GUEST) then
		local players = player.GetAll()
		local specmodes = { 4, 5, 6 }
		for k,v in pairs(players) do
			if (v:Team() == TEAM_GUEST) then
				table.remove(players, k)
			end
		end
		if (key == IN_USE) then
			if (#players >= 1) then
				index = ((index - 1) % #players) + 1
				ply["spectate"] = players[index]
				if (specmode == 1) then
					ply:SetPos(ply["spectate"]:GetShootPos())
				elseif (specmode == 2) then
					ply:SpectateEntity(ply["spectate"])
				elseif (specmode == 3) then
					ply:SpectateEntity(ply["spectate"])
				end
			end
		elseif (key == IN_ATTACK or key == IN_RELOAD) then
			if (#players >= 1) then
				index = ((index + 1) % #players) + 1
				ply["spectate"] = players[index]
				if (specmode == 1) then
					ply:SetPos(ply["spectate"]:GetShootPos())
				elseif (specmode == 2) then
					ply:SpectateEntity(ply["spectate"])
				elseif (specmode == 3) then
					ply:SpectateEntity(ply["spectate"])
				end
			end
		elseif (key == IN_ATTACK2 or key == IN_JUMP) then
			if (#players >= 1) then
				specmode = ((specmode + 1) % #specmodes) + 1
				ply:Spectate(specmodes[specmode])
			end
		end
	end
end
/*---------------------------------------------------------
  Sets player weapons acording to theyr team
  when they spawn
---------------------------------------------------------*/
function GM:PlayerSpawn( ply )
	for k,ply in pairs(player.GetAll()) do
		ply["ready"] = 0
		ply:ConCommand("-menu")
	end
	if ply:Team() == TEAM_GUEST then
		ply:StripWeapons()
	elseif ply:Team() == TEAM_A and GAME_STATUS == "Trap Building" then
		ply:UnSpectate()
		ply:SetModel("models/player/Combine_Soldier_PrisonGuard.mdl")
		ply:StripWeapons()
		ply:Give( "weapon_physgun" )
		ply:Give( "weapon_physcannon" )
		ply:Give( "gmod_tool" )
		ply:SelectWeapon( "weapon_physgun" )
	elseif ply:Team() == TEAM_A and GAME_STATUS == "Trap Testing" then
		ply:UnSpectate()
		ply:SetModel("models/player/Combine_Soldier_PrisonGuard.mdl")
		ply:StripWeapons()
		ply:Give( "weapon_physcannon" )
		ply:SelectWeapon( "weapon_physcannon" )
	elseif ply:Team() == TEAM_B and GAME_STATUS == "Trap Building" then
		ply:UnSpectate()
		ply:SetModel("models/player/police.mdl")
		ply:StripWeapons()
		ply:Give( "weapon_physgun" )
		ply:Give( "weapon_physcannon" )
		ply:Give( "gmod_tool" )
		ply:SelectWeapon( "weapon_physgun" )
	elseif ply:Team() == TEAM_B and GAME_STATUS == "Trap Testing" then
		ply:UnSpectate()
		ply:SetModel("models/player/Combine_Soldier_PrisonGuard.mdl")
		ply:StripWeapons()
		ply:Give( "weapon_physcannon" )
		ply:SelectWeapon( "weapon_physcannon" )
	end
end

/*---------------------------------------------------------
  Set player weapons when they join the team
---------------------------------------------------------*/
function team_1( ply )
	CheckSpec(ply, TEAM_GUEST)
	ply:SetTeam(TEAM_GUEST)
	mssg = ply:Name().." joined Spectator"
	printAction( mssg )
	ply:Spawn()
	ply:Spectate( OBS_MODE_ROAMING )
	if ply.SpawnSpecPos then
		ply:SetPos(ply.SpawnSpecPos)
		ply:SetEyeAngles(ply.SpawnSpecAng)
		ply.SpawnSpecPos = nil
		ply.SpawnSpecAng = nil
	end
	ply:SendLua("chat.AddText(Color(151, 211, 255), '- Press the ', Color(255, 255, 255, 255), 'USE', Color(151, 211, 255, 255), ' and ', Color(255, 255, 255, 255), 'RELOAD', Color(151, 211, 255, 255), ' or ', Color(255, 255, 255, 255), 'ATTACK')")
	ply:SendLua("chat.AddText(Color(151, 211, 255, 255), 'to scroll through players.')")
	ply:SendLua("chat.AddText(Color(151, 211, 255), '- Press ', Color(255, 255, 255, 255), 'ATTACK2', Color(151, 211, 255, 255), ' or ', Color(255, 255, 255, 255), 'JUMP', Color(151, 211, 255, 255), ' to switch spectate modes.')")
	CheckPlyNum()
end
function team_2( ply )
	TEAM_LIMIT = math.Round(#player.GetAll() / 2)
	if (#team.GetPlayers(2) >= TEAM_LIMIT) then
		ply:ChatPrint("The team is full!")
		ply:ConCommand( "team_menu" )
	else
		ply:SetTeam(TEAM_A)
		mssg = ply:Name().." joined Team A"
		printAction( mssg )
		ply:Spawn()
		CheckPlyNum()
	end
end
function team_3( ply )
    TEAM_LIMIT = math.Round(#player.GetAll() / 2)
	if (#team.GetPlayers(3) >= TEAM_LIMIT) then
		ply:ChatPrint("The team is full!")
		ply:ConCommand( "team_menu" )
	else
		ply:SetTeam(TEAM_B)
		mssg = ply:Name().." joined Team B"
		printAction( mssg )
		ply:Spawn()
		CheckPlyNum()
	end
end
function team_4( ply )
	if (#team.GetPlayers(2) == #team.GetPlayers(3)) then
			local randteam = math.random(2, 3)
			ply:SetTeam(randteam)
			mssg = Format("%s joined %s", ply:Name(), team.GetName(randteam))
	elseif (#team.GetPlayers(2) < #team.GetPlayers(3)) then
		ply:SetTeam(2)
		mssg = ply:Name().." was auto-assigned to Team A"
	else
		ply:SetTeam(3)
		mssg = ply:Name().." was auto-assigned to Team B"
	end
	printAction( mssg )
	ply:Spawn()
	CheckPlyNum()
end
concommand.Add( "team_1", team_1 )
concommand.Add( "team_2", team_2 )
concommand.Add( "team_3", team_3 )
concommand.Add( "team_4", team_4 )
hook.Add( "PlayerSay", "PlySay", PlayerChat )