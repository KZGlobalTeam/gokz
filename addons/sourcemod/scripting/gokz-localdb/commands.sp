void RegisterCommands()
{
	RegAdminCmd("sm_setcheater", CommandSetCheater, ADMFLAG_ROOT, "[KZ] Set a SteamID as a cheater. Usage: !setcheater <STEAM_1:X:X>");
	RegAdminCmd("sm_setnotcheater", CommandSetNotCheater, ADMFLAG_ROOT, "[KZ] Set a SteamID as not a cheater. Usage: !setnotcheater <STEAM_1:X:X>");
	RegAdminCmd("sm_deletejump", CommandDeleteJump, ADMFLAG_ROOT, "[KZ] Remove the top jumpstat of a SteamID. Usage: !deletejump <STEAM_1:X:X> <mode> <jump type> <block?>");
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

public Action CommandDeleteJump(int client, int args)
{
	if (args < 3)
	{
		LogMessage("Wrong number of arguments.");
		return;
	}
	
	int i, steamAccountID, isBlock, mode, jumpType;
	char query[1024], split[4][32];
	
	// Get arguments
	split[3][0] = '\0';
	GetCmdArgString(query, sizeof(query));
	ExplodeString(query, " ", split, 4, 32, false);
	
	// SteamID32
	steamAccountID = Steam2ToSteamAccountID(split[0]);
	if (steamAccountID == -1)
	{
		LogMessage("The SteamID could not be parsed - use 'STEAM_1:X:X'.");
		return;
	}
	
	// Mode
	for (i = 0; i < MODE_COUNT; i++)
	{
		if (StrEqual(split[1], gC_ModeNames[i]) || StrEqual(split[1], gC_ModeNamesShort[i]))
		{
			mode = i;
			break;
		}
	}
	if (i == MODE_COUNT)
	{
		LogMessage("Mode not found.");
		return;
	}
	
	// Jumptype
	for (i = 0; i < JUMPTYPE_COUNT; i++)
	{
		if (StrEqual(split[2], gC_JumpTypes[i]) || StrEqual(split[2], gC_JumpTypesShort[i]))
		{
			jumpType = i;
			break;
		}
	}
	if (i == JUMPTYPE_COUNT)
	{
		LogMessage("Jump type not found.");
		return;
	}
	
	// Is it a block jump?
	isBlock = (split[3][0] != '0' && split[3][0] != '\0');
	
	DB_DeleteJump(client, steamAccountID, jumpType, mode, isBlock);
} 