DeriveGamemode("sandbox")
GM.Name = "Traps"
GM.Author = "d3cr1pt0r"
GM.Email = "d3cr1pt0r@gmail.com"
GM.Website = "N/A"

/*---------------------------------------------------------
   Name: gamemode:CreateTeams()
   Desc: Note - HAS to be shared.
---------------------------------------------------------*/
function GM:CreateTeams()
	TEAM_SPECTATORS = 1
	team.SetUp( TEAM_SPECTATORS, "Guests", Color( 125, 125, 125, 255 ) )
	team.SetSpawnPoint( TEAM_SPECTATORS, "info_player_counterterrorist" )
	
	TEAM_A = 2
	team.SetUp( TEAM_A, "Team A", Color( 225, 40, 40 , 225 ) )
	team.SetSpawnPoint( TEAM_A, "info_player_terrorist" )

	TEAM_B = 3
	team.SetUp( TEAM_B, "Team B", Color( 40, 40, 225 , 225 ) )
	team.SetSpawnPoint( TEAM_B, "info_player_counterterrorist" )
	
	TEAM_A_DEAD = 4
	team.SetUp( TEAM_A_DEAD, "Team A Dead", Color( 100, 40, 40 , 224 ) )

	TEAM_B_DEAD = 5
	team.SetUp( TEAM_B_DEAD, "Team B Dead", Color( 40, 40, 100 , 225 ) )
end

