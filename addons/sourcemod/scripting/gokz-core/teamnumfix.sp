static Handle H_RemovePlayer;
static int teamEntID[4];
static int oldTeam[MAXPLAYERS + 1];
static int realTeam[MAXPLAYERS + 1];

void OnPluginStart_TeamNumber()
{
	GameData gamedataConf = LoadGameConfigFile("gokz-core.games");
	if (gamedataConf == null)
	{
		SetFailState("Failed to load gokz-core gamedata");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetVirtual(gamedataConf.GetOffset("CCSTeam::RemovePlayer"));
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	H_RemovePlayer = EndPrepSDKCall();
	if (H_RemovePlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to prepare SDKCall for CCSTeam::RemovePlayer!");
	}
}

void OnMapStart_TeamNumber()
{
	// Fetch the entity ID of team entities and store them.
	int team = FindEntityByClassname(MaxClients + 1, "cs_team_manager");
	while (team != -1)
	{
		int teamNum = GetEntProp(team, Prop_Send, "m_iTeamNum");
		teamEntID[teamNum] = team;
		team = FindEntityByClassname(team, "cs_team_manager");
	}
}

void OnGameFrame_TeamNumber()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
		{
			continue;
		}
		int team = GetEntProp(client, Prop_Data, "m_iTeamNum");
		// If the entprop changed, remove the player from the old team, but make sure it's a valid team first
		if (team != oldTeam[client] && oldTeam[client] < 4 && oldTeam[client] > 0)
		{
			SDKCall(H_RemovePlayer, teamEntID[oldTeam[client]], client);
		}
		oldTeam[client] = team;
	}
}

void OnPlayerJoinTeam_TeamNumber(Event event, int client)
{
	// If the old team value is invalid, fix it.
	if (event.GetInt("oldteam") > 4 || event.GetInt("oldteam") < 0)
	{
		event.SetInt("oldteam", 0);
	}
	realTeam[client] = event.GetInt("team");
}

void OnPlayerDeath_TeamNumber(int client)
{
	// Switch the client's team to a valid team to prevent crashes.
	CS_SwitchTeam(client, realTeam[client]);
}