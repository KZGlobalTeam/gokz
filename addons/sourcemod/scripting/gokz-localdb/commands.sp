void RegisterCommands()
{
	RegAdminCmd("sm_setcheater", CommandSetCheater, ADMFLAG_ROOT, "[KZ] Set a SteamID as a cheater. Usage: !setcheater <STEAM_1:X:X>");
	RegAdminCmd("sm_setnotcheater", CommandSetNotCheater, ADMFLAG_ROOT, "[KZ] Set a SteamID as not a cheater. Usage: !setnotcheater <STEAM_1:X:X>");
}

public Action CommandSetCheater(int client, int args)
{
	if (args == 0)
	{
		return; // TODO User-friendliness?
	}
	
	char steamID2[64];
	GetCmdArgString(steamID2, sizeof(steamID2));
	int steamAccountID = Steam2ToSteamAccountID(steamID2);
	if (steamAccountID == -1)
	{
		// TODO Translation phrases?
		if (client == 0)
		{
			LogMessage("The SteamID could not be parsed - use 'STEAM_1:X:X'.");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "{grey}The SteamID could not be parsed - use '{default}STEAM_1:X:X{grey}'.");
		}
	}
	else
	{
		DB_SetCheaterSteamID(client, steamAccountID, true);
	}
}

public Action CommandSetNotCheater(int client, int args)
{
	if (args == 0)
	{
		return; // TODO User-friendliness?
	}
	
	char steamID2[64];
	GetCmdArgString(steamID2, sizeof(steamID2));
	int steamAccountID = Steam2ToSteamAccountID(steamID2);
	if (steamAccountID == -1)
	{
		// TODO Translation phrases?
		if (client == 0)
		{
			LogMessage("The SteamID could not be parsed - use 'STEAM_1:X:X'.");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "{grey}The SteamID could not be parsed - use '{default}STEAM_1:X:X{grey}'.");
		}
	}
	else
	{
		DB_SetCheaterSteamID(client, steamAccountID, false);
	}
} 