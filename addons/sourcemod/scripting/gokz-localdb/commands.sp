void RegisterCommands()
{
	RegConsoleCmd("sm_savetimersetup", Command_SaveTimerSetup, "[KZ] Save the current timer setup (virtual buttons and start position).");
	RegConsoleCmd("sm_sts", Command_SaveTimerSetup, "[KZ] Save the current timer setup (virtual buttons and start position).");
	RegConsoleCmd("sm_loadtimersetup", Command_LoadTimerSetup, "[KZ] Load the saved timer setup (virtual buttons and start position).");
	RegConsoleCmd("sm_lts", Command_LoadTimerSetup, "[KZ] Load the saved timer setup (virtual buttons and start position).");
	
	RegAdminCmd("sm_setcheater", CommandSetCheater, ADMFLAG_ROOT, "[KZ] Set a SteamID as a cheater. Usage: !setcheater <STEAM_1:X:X>");
	RegAdminCmd("sm_setnotcheater", CommandSetNotCheater, ADMFLAG_ROOT, "[KZ] Set a SteamID as not a cheater. Usage: !setnotcheater <STEAM_1:X:X>");
	RegAdminCmd("sm_deletejump", CommandDeleteJump, ADMFLAG_ROOT, "[KZ] Remove the top jumpstat of a SteamID. Usage: !deletejump <STEAM_1:X:X> <mode> <jump type> <block?>");
}

public Action Command_SaveTimerSetup(int client, int args)
{
	DB_SaveTimerSetup(client);
	return Plugin_Handled;
}

public Action Command_LoadTimerSetup(int client, int args)
{
	DB_LoadTimerSetup(client, true);
	return Plugin_Handled;
}

public Action CommandSetCheater(int client, int args)
{
	if (args == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No SteamID specified");
		return Plugin_Handled;
	}
	
	char steamID2[64];
	GetCmdArgString(steamID2, sizeof(steamID2));
	int steamAccountID = Steam2ToSteamAccountID(steamID2);
	if (steamAccountID == -1)
	{
		GOKZ_PrintToChat(client, true, "%t", "Invalid SteamID");
	}
	else
	{
		DB_SetCheaterSteamID(client, steamAccountID, true);
	}
	
	return Plugin_Handled;
}

public Action CommandSetNotCheater(int client, int args)
{
	if (args == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No SteamID specified");
	}
	
	char steamID2[64];
	GetCmdArgString(steamID2, sizeof(steamID2));
	int steamAccountID = Steam2ToSteamAccountID(steamID2);
	if (steamAccountID == -1)
	{
		GOKZ_PrintToChat(client, true, "%t", "Invalid SteamID");
	}
	else
	{
		DB_SetCheaterSteamID(client, steamAccountID, false);
	}
	
	return Plugin_Handled;
}

public Action CommandDeleteJump(int client, int args)
{
	if (args < 3)
	{
		GOKZ_PrintToChat(client, true, "%t", "Delete Jump Usage");
		return Plugin_Handled;
	}
	
	int steamAccountID, isBlock, mode, jumpType;
	char query[1024], split[4][32];
	
	// Get arguments
	split[3][0] = '\0';
	GetCmdArgString(query, sizeof(query));
	ExplodeString(query, " ", split, 4, 32, false);
	
	// SteamID32
	steamAccountID = Steam2ToSteamAccountID(split[0]);
	if (steamAccountID == -1)
	{
		GOKZ_PrintToChat(client, true, "%t", "Invalid SteamID");
		return Plugin_Handled;
	}
	
	// Mode
	for (mode = 0; mode < MODE_COUNT; mode++)
	{
		if (StrEqual(split[1], gC_ModeNames[mode]) || StrEqual(split[1], gC_ModeNamesShort[mode], false))
		{
			break;
		}
	}
	if (mode == MODE_COUNT)
	{
		GOKZ_PrintToChat(client, true, "%t", "Invalid Mode");
		return Plugin_Handled;
	}
	
	// Jumptype
	for (jumpType = 0; jumpType < JUMPTYPE_COUNT; jumpType++)
	{
		if (StrEqual(split[2], gC_JumpTypes[jumpType]) || StrEqual(split[2], gC_JumpTypesShort[jumpType], false))
		{
			break;
		}
	}
	if (jumpType == JUMPTYPE_COUNT)
	{
		GOKZ_PrintToChat(client, true, "%t", "Invalid Jumptype");
		return Plugin_Handled;
	}
	
	// Is it a block jump?
	isBlock = StrEqual(split[3], "yes", false) || StrEqual(split[3], "true", false) || StrEqual(split[3], "1");
	
	DB_DeleteJump(client, steamAccountID, jumpType, mode, isBlock);
	
	return Plugin_Handled;
}
