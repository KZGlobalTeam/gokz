/*
	Commands
	
	Commands for player and admin use.
*/



static float lastCommandTime[MAXPLAYERS + 1];



void CreateCommands()
{
	RegConsoleCmd("sm_top", CommandTop, "[KZ] Opens a menu showing the top record holders.");
	RegConsoleCmd("sm_maptop", CommandMapTop, "[KZ] Opens a menu showing the top times of a map. Usage: !maptop <map>");
	RegConsoleCmd("sm_bmaptop", CommandBMapTop, "[KZ] Opens a menu showing the top bonus times of a map. Usage: !btop <#bonus> <map>");
	RegConsoleCmd("sm_pb", CommandPB, "[KZ] Prints PB map times and ranks to chat. Usage: !pb <map> <player>");
	RegConsoleCmd("sm_bpb", CommandBPB, "[KZ] Prints PB bonus times and ranks to chat. Usage: !bpb <#bonus> <map> <player>");
	RegConsoleCmd("sm_wr", CommandWR, "[KZ] Prints map record times to chat. Usage: !wr <map>");
	RegConsoleCmd("sm_bwr", CommandBWR, "[KZ] Prints bonus record times to chat. Usage: !bwr <#bonus> <map>");
	RegConsoleCmd("sm_avg", CommandAVG, "[KZ] Prints the average map run time to chat. Usage !avg <map>");
	RegConsoleCmd("sm_bavg", CommandBAVG, "[KZ] Prints the average bonus run time to chat. Usage !bavg <#bonus> <map>");
	RegConsoleCmd("sm_pc", CommandPC, "[KZ] Prints map completion to chat. Usage: !pc <player>");
	RegConsoleCmd("sm_rr", CommandRecentRecords, "[KZ] Opens a menu showing recently broken records.");
	RegConsoleCmd("sm_latest", CommandRecentRecords, "[KZ] Opens a menu showing recently broken records.");
	
	RegAdminCmd("sm_updatemappool", CommandUpdateMapPool, ADMFLAG_ROOT, "[KZ] Updates the ranked map pool with the list of maps in cfg/sourcemod/gokz/mappool.cfg.");
}



// =========================  COMMAND HANDLERS  ========================= //

public Action CommandTop(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	// Open player top for the player's selected mode
	DisplayPlayerTopMenu(client, GOKZ_GetOption(client, Option_Mode));
	return Plugin_Handled;
}

public Action CommandMapTop(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Open map top for current map and their current mode
		DB_OpenMapTop(client, GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args >= 1)
	{  // Open map top for specified map and their current mode
		char specifiedMap[33];
		GetCmdArg(1, specifiedMap, sizeof(specifiedMap));
		DB_OpenMapTop_FindMap(client, specifiedMap, 0, GOKZ_GetOption(client, Option_Mode));
	}
	return Plugin_Handled;
}

public Action CommandBMapTop(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Open Bonus 1 top for current map and their current mode		
		DB_OpenMapTop(client, GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args == 1)
	{  // Open specified Bonus # top for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_OpenMapTop(client, GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args >= 2)
	{  // Open specified bonus top for specified map and their current mode
		char argBonus[4], argMap[33];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_OpenMapTop_FindMap(client, argMap, bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}

public Action CommandPB(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Print their PBs for current map and their current mode
		DB_PrintPBs(client, GetSteamAccountID(client), GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args == 1)
	{  // Print their PBs for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DB_PrintPBs_FindMap(client, GetSteamAccountID(client), argMap, 0, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args >= 2)
	{  // Print specified player's PBs for specified map and their current mode
		char argMap[33], argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argMap, sizeof(argMap));
		GetCmdArg(2, argPlayer, sizeof(argPlayer));
		DB_PrintPBs_FindPlayerAndMap(client, argPlayer, argMap, 0, GOKZ_GetOption(client, Option_Mode));
	}
	return Plugin_Handled;
}

public Action CommandBPB(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Print their Bonus 1 PBs for current map and their current mode
		DB_PrintPBs(client, GetSteamAccountID(client), GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args == 1)
	{  // Print their specified Bonus # PBs for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintPBs(client, GetSteamAccountID(client), GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args == 2)
	{  // Print their specified Bonus # PBs for specified map and their current mode
		char argBonus[4], argMap[33];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintPBs_FindMap(client, GetSteamAccountID(client), argMap, bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args >= 3)
	{  // Print specified player's specified Bonus # PBs for specified map and their current mode
		char argBonus[4], argMap[33], argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		GetCmdArg(3, argPlayer, sizeof(argPlayer));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintPBs_FindPlayerAndMap(client, argPlayer, argMap, bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}

public Action CommandWR(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Print record times for current map and their current mode
		DB_PrintRecords(client, GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args >= 1)
	{  // Print record times for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DB_PrintRecords_FindMap(client, argMap, 0, GOKZ_GetOption(client, Option_Mode));
	}
	return Plugin_Handled;
}

public Action CommandBWR(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Print Bonus 1 record times for current map and their current mode
		DB_PrintRecords(client, GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args == 1)
	{  // Print specified Bonus # record times for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintRecords(client, GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args >= 2)
	{  // Print specified Bonus # record times for specified map and their current mode
		char argBonus[4], argMap[33];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintRecords_FindMap(client, argMap, bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}

public Action CommandAVG(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Print average times for current map and their current mode
		DB_PrintAverage(client, GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args >= 1)
	{  // Print average times for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DB_PrintAverage_FindMap(client, argMap, 0, GOKZ_GetOption(client, Option_Mode));
	}
	return Plugin_Handled;
}

public Action CommandBAVG(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{  // Print Bonus 1 average times for current map and their current mode
		DB_PrintAverage(client, GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetOption(client, Option_Mode));
	}
	else if (args == 1)
	{  // Print specified Bonus # average times for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintAverage(client, GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args >= 2)
	{  // Print specified Bonus # average times for specified map and their current mode
		char argBonus[4], argMap[33];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		int bonus = StringToInt(argBonus);
		if (bonus > 0)
		{
			DB_PrintAverage_FindMap(client, argMap, bonus, GOKZ_GetOption(client, Option_Mode));
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}

public Action CommandPC(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		DB_GetCompletion(client, GetSteamAccountID(client), GOKZ_GetOption(client, Option_Mode), true);
	}
	else if (args >= 1)
	{  // Print record times for specified map and their current mode
		char argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argPlayer, sizeof(argPlayer));
		DB_GetCompletion_FindPlayer(client, argPlayer, GOKZ_GetOption(client, Option_Mode));
	}
	return Plugin_Handled;
}

public Action CommandRecentRecords(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}
	
	// Open recent records for the player's selected mode
	DisplayRecentRecordsMenu(client, GOKZ_GetOption(client, Option_Mode));
	return Plugin_Handled;
}



// =========================  ADMIN COMMAND HANDLERS  ========================= //

public Action CommandUpdateMapPool(int client, int args)
{
	DB_UpdateRankedMapPool(client);
}



// =========================  PRIVATE  ========================= //

bool IsSpammingCommands(int client, bool printMessage = true)
{
	float currentTime = GetEngineTime();
	float timeSinceLastCommand = currentTime - lastCommandTime[client];
	if (timeSinceLastCommand < COMMAND_COOLDOWN)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command", COMMAND_COOLDOWN - timeSinceLastCommand);
		}
		return true;
	}
	
	// Not spamming commands - all good!
	lastCommandTime[client] = currentTime;
	return false;
} 