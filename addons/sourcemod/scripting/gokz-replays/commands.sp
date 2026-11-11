void RegisterCommands()
{
	RegConsoleCmd("sm_replay", CommandReplay, "[KZ] Open the replay loading menu.");
	RegConsoleCmd("sm_replaycontrols", CommandReplayControls, "[KZ] Toggle the replay control menu.");
	RegConsoleCmd("sm_rpcontrols", CommandReplayControls, "[KZ] Toggle the replay control menu.");
	RegConsoleCmd("sm_replaygoto", CommandReplayGoto, "[KZ] Skip to a specific time in the replay (hh:mm:ss).");
	RegConsoleCmd("sm_rpgoto", CommandReplayGoto, "[KZ] Skip to a specific time in the replay (hh:mm:ss).");
	RegAdminCmd("sm_replayadmin", CommandReplayAdmin, ADMFLAG_ROOT, "[KZ] Open the menu of imported and cheater replays. Usage: !replayadmin [name or STEAM_1:X:X]");
}

public Action CommandReplay(int client, int args)
{
	DisplayReplayModeMenu(client);
	return Plugin_Handled;
}

public Action CommandReplayAdmin(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	char filter[MAX_NAME_LENGTH];
	GetCmdArgString(filter, sizeof(filter));
	StripQuotes(filter);
	TrimString(filter);
	DisplayReplayAdminMenu(client, filter);
	return Plugin_Handled;
}

public Action CommandReplayControls(int client, int args)
{
	ToggleReplayControls(client);
	return Plugin_Handled;
}

public Action CommandReplayGoto(int client, int args)
{
	int seconds;
	char timeString[32], split[3][32];
	
	GetCmdArgString(timeString, sizeof(timeString));
	int res = ExplodeString(timeString, ":", split, 3, 32, false);
	switch (res)
	{
		case 1:
		{
			seconds = StringToInt(split[0]);
		}
		
		case 2:
		{
			seconds = StringToInt(split[0]) * 60 + StringToInt(split[1]);
		}
		
		case 3:
		{
			seconds = StringToInt(split[0]) * 3600 + StringToInt(split[1]) * 60 + StringToInt(split[2]);
		}
		
		default:
		{
			GOKZ_PrintToChat(client, true, "%t", "Replay Controls - Invalid Time");
			GOKZ_PlayErrorSound(client);
			return Plugin_Handled;
		}
	}
	
	TrySkipToTime(client, seconds);
	return Plugin_Handled;
}
