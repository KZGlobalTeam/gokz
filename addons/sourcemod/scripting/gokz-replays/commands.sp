void RegisterCommands()
{
	RegConsoleCmd("sm_replaycontrols", CommandReplayControls, "[KZ] Toggle the replay control menu.");
	RegConsoleCmd("sm_rpcontrols", CommandReplayControls, "[KZ] Toggle the replay control menu.");
	RegConsoleCmd("sm_replaygoto", CommandReplayGoto, "[KZ] Skip to a specific time in the replay (hh:mm:ss).");
	RegConsoleCmd("sm_rpgoto", CommandReplayGoto, "[KZ] Skip to a specific time in the replay (hh:mm:ss).");
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
			return Plugin_Handled;
		}
	}
	
	TrySkipToTime(client, seconds);
	return Plugin_Handled;
}
