include( 'shared.lua' )
include( 'base_scoreboard.lua' )

/*---------------------------------------------------------
 To avoid the errors :D penis
---------------------------------------------------------*/
GM_Timer = 0
GM_Game = "Waiting for players"
/*---------------------------------------------------------
 The VGUI menu for the team menu
---------------------------------------------------------*/
function set_team()

	local frame = vgui.Create( "DFrame" )
    frame:SetPos( 400,400 )
    frame:SetSize( 200, 320 )
    frame:SetTitle( "Team Selection" )
    frame:SetVisible( true )
    frame:SetDraggable( true )
    frame:ShowCloseButton( true )
    frame:MakePopup() 

	team_1 = vgui.Create( "DButton" )
    team_1:SetParent( frame )
    team_1:SetText( "Spectator" )
    team_1:SetPos( 25, 50 )
    team_1:SetSize( 150, 50 )
    team_1.DoClick = function ()
		RunConsoleCommand( "team_1" )
		frame:SetVisible( false )
    end 
		
	team_2 = vgui.Create( "DButton" )
    team_2:SetParent( frame )
    team_2:SetText( "Team A" )
    team_2:SetPos( 25, 120 )
    team_2:SetSize( 150, 50 )
    team_2.DoClick = function ()
		RunConsoleCommand( "team_2" )
		frame:SetVisible( false )
    end

	team_3 = vgui.Create( "DButton" )
    team_3:SetParent( frame )
    team_3:SetText( "Team B" )
    team_3:SetPos( 25, 190 )
    team_3:SetSize( 150, 50 )
    team_3.DoClick = function ()
		RunConsoleCommand( "team_3" )
		frame:SetVisible( false )
    end
	team_4 = vgui.Create( "DButton" )
    team_4:SetParent( frame )
    team_4:SetText( "Auto-Assign" )
    team_4:SetPos(25, 260 )
    team_4:SetSize( 150, 50 )
    team_4.DoClick = function ()
		RunConsoleCommand( "team_4" )
		frame:SetVisible( false )
    end
end

/*---------------------------------------------------------
  Get the server timer and game data and 
  synchronize it with the client
---------------------------------------------------------*/
function TimerDataHook( um )
	GM_Timer = um:ReadLong()
	GM_Game = um:ReadString()
	if (GM_Timer < 0) then
		GM_Timer = 0
	end
	if (GM_Game == "Trap Building") then
		GM_Texture = surface.GetTextureID("traps/trap_building")
	elseif (GM_Game == "Trap Testing") then
		GM_Texture = surface.GetTextureID("traps/trap_testing")
	end
end

function TimerDataBckHook( um )
	GM_Timer = um:ReadLong()
	GM_Game = um:ReadString()
end

/*---------------------------------------------------------
  HUD for the timer
---------------------------------------------------------*/
local function drawTime()
	//Draw 2 boxes
	local posx = ScrW() / 3
	local posy = ScrH() - 80
	draw.RoundedBox( 4, posx, posy, 250, 45, Color( 40, 40, 40, 255 ) )
	draw.RoundedBox( 4, posx-10, posy-25, 60, 60, Color( 50, 50, 50, 255 ) )
	draw.RoundedBox( 0, posx+50, posy+21, 200, 3, Color( 200, 200, 200, 255 ) )
	
	//Draw the text
	draw.DrawText( "Game: "..GM_Game, "ScoreboardText", posx+55, posy, Color(120,120,120,120), 0 )
	local minutes = tostring(math.floor(GM_Timer / 60) % 60)
	local seconds = tostring(math.floor(GM_Timer) % 60)
	if(tonumber(seconds) < 10) then
		seconds = "0" .. seconds
	end
	draw.DrawText( "Time Left: "..minutes..":"..seconds, "ScoreboardText", posx+55, posy+25, Color(120,120,120,120), 0 )
	
	//Draw the texture
	surface.SetTexture(GM_Texture)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(posx-7,posy-22,54,54)
end

/*---------------------------------------------------------
  Here we remove the original HUD for health
  and armor
---------------------------------------------------------*/
function hidehud(name)
	for k, v in pairs{"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo"} do
		if name == v then return false end
	end
end

/*---------------------------------------------------------
  Draw health HUD
---------------------------------------------------------*/
local function drawHealth()
	local Health = math.Clamp(LocalPlayer():Health(), 0, 100)
	local MoveH = (LocalPlayer():Health() * 3) - 1
	scrx = 50
	scry = ScrH() - 90
	local Green = (Health * 2)
	local Red = (Health * -2) + 200
	draw.RoundedBox( 2, scrx, scry, 305, 25, Color( 0, 0, 0, 180 ) )
	if (Health > 0) then
		draw.RoundedBox( 2, scrx + 2.8, scry + 2.8, MoveH, 20, Color( Red, Green, 0, 180 ) )
	end
	draw.DrawText( tostring(Health).."% HP", "ScoreboardText", 170, scry + 4, Color( 255, 255, 255, 245 ), 0 )
end

/*---------------------------------------------------------
  Draw armor HUD
---------------------------------------------------------*/
local function drawArmor()
	local Armor = math.Clamp(LocalPlayer():Armor(), 0, 100)
	MoveA = (LocalPlayer():Armor() * 3) - 1
	scrxa = 50
	scrya = ScrH() - 60
	local Blue = (Armor * 2)
	local Red = (Armor * -2) + 200
	draw.RoundedBox( 2, scrxa, scrya, 305, 25, Color( 0, 0, 0, 180 ) )
	if (Armor > 0) then
		draw.RoundedBox( 2, scrxa + 2.8, scrya + 2.8, MoveA, 20, Color( Red, 0, Blue, 180 ) )
	end
	draw.DrawText( tostring(Armor).."% AP", "ScoreboardText", 170, scrya + 4, Color( 255, 255, 255, 245 ), 0 )
end

/*---------------------------------------------------------
  Here we block the "Q" menu if the teams are
  testing traps and enable the "Q" menu when
  the teams are building traps
---------------------------------------------------------*/
function GM:SpawnMenuOpen()
	if (GM_Game == "Trap Building" and LocalPlayer():Team() != TEAM_SPECTATORS) then
		return true
	else
		return false
	end
end

/*---------------------------------------------------------
  Needed hooks and console commands
---------------------------------------------------------*/
usermessage.Hook("TimerData", TimerDataHook)
usermessage.Hook("TimerDataBck", TimerDataBckHook)
concommand.Add( "team_menu", set_team )
hook.Add("HUDPaint","DrawHealth",drawHealth)
hook.Add("HUDPaint","DrawArmor",drawArmor)
hook.Add("HUDShouldDraw", "hidehud", hidehud)
hook.Add("HUDPaint","DrawTime",drawTime)