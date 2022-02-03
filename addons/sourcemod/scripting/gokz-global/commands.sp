void RegisterCommands()
{
	RegConsoleCmd("sm_globalcheck", CommandGlobalCheck, "[KZ] Show whether global records are currently enabled in chat.");
	RegConsoleCmd("sm_gc", CommandGlobalCheck, "[KZ] Show whether global records are currently enabled in chat.");
	RegConsoleCmd("sm_tier", CommandTier, "[KZ] Show the map's tier in chat.");
	RegConsoleCmd("sm_gpb", CommandPrintPBs, "[KZ] Show main course global personal best in chat. Usage: !gpb <map>");
	RegConsoleCmd("sm_gr", CommandPrintRecords, "[KZ] Show main course global record times in chat. Usage: !gr <map>");
	RegConsoleCmd("sm_gwr", CommandPrintRecords, "[KZ] Show main course global record times in chat. Usage: !gwr <map>");
	RegConsoleCmd("sm_gbpb", CommandPrintBonusPBs, "[KZ] Show bonus global personal best in chat. Usage: !gbpb <#bonus> <map>");
	RegConsoleCmd("sm_gbr", CommandPrintBonusRecords, "[KZ] Show bonus global record times in chat. Usage: !bgr <#bonus> <map>");
	RegConsoleCmd("sm_gbwr", CommandPrintBonusRecords, "[KZ] Show bonus global record times in chat. Usage: !bgwr <#bonus> <map>");
	RegConsoleCmd("sm_gmaptop", CommandMapTop, "[KZ] Open a menu showing the top global main course times of a map. Usage: !gmaptop <map>");
	RegConsoleCmd("sm_gbmaptop", CommandBonusMapTop, "[KZ] Open a menu showing the top global bonus times of a map. Usage: !gbmaptop <#bonus> <map>");
}

public Action CommandGlobalCheck(int client, int args)
{
	PrintGlobalCheckToChat(client);
	return Plugin_Handled;
}

public Action CommandTier(int client, int args)
{
	if (gI_MapTier != -1)
	{
		GOKZ_PrintToChat(client, true, "%t", "Map Tier", gC_CurrentMap, gI_MapTier);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Map Tier (Unknown)", gC_CurrentMap);
	}
	return Plugin_Handled;
}

public Action CommandPrintPBs(int client, int args)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	return CommandPrintRecordsHelper(client, args, steamid);
}

public Action CommandPrintRecords(int client, int args)
{
	return CommandPrintRecordsHelper(client, args);
}

static Action CommandPrintRecordsHelper(int client, int args, const char[] steamid = DEFAULT_STRING)
{
	KZPlayer player = KZPlayer(client);
	int mode = player.Mode;
	
	if (args == 0)
	{  // Print record times for current map and their current mode
		PrintRecords(client, gC_CurrentMap, 0, mode, steamid);
	}
	else if (args >= 1)
	{  // Print record times for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		PrintRecords(client, argMap, 0, mode, steamid);
	}
	return Plugin_Handled;
}

public Action CommandPrintBonusPBs(int client, int args)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	return CommandPrintBonusRecordsHelper(client, args, steamid);
}

public Action CommandPrintBonusRecords(int client, int args)
{
	return CommandPrintBonusRecordsHelper(client, args);
}

static Action CommandPrintBonusRecordsHelper(int client, int args, const char[] steamid = DEFAULT_STRING)
{
	KZPlayer player = KZPlayer(client);
	int mode = player.Mode;
	
	if (args == 0)
	{  // Print Bonus 1 record times for current map and their current mode
		PrintRecords(client, gC_CurrentMap, 1, mode, steamid);
	}
	else if (args == 1)
	{  // Print specified Bonus # record times for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			PrintRecords(client, gC_CurrentMap, bonus, mode, steamid);
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
		if (GOKZ_IsValidCourse(bonus, true))
		{
			PrintRecords(client, argMap, bonus, mode, steamid);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}

public Action CommandMapTop(int client, int args)
{
	if (args <= 0)
	{  // Open global map top for current map
		DisplayMapTopModeMenu(client, gC_CurrentMap, 0);
	}
	else if (args >= 1)
	{  // Open global map top for specified map
		char argMap[64];
		GetCmdArg(1, argMap, sizeof(argMap));
		DisplayMapTopModeMenu(client, argMap, 0);
	}
	return Plugin_Handled;
}

public Action CommandBonusMapTop(int client, int args)
{
	if (args == 0)
	{  // Open global Bonus 1 top for current map		
		DisplayMapTopModeMenu(client, gC_CurrentMap, 1);
	}
	else if (args == 1)
	{  // Open specified global Bonus # top for current map
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DisplayMapTopModeMenu(client, gC_CurrentMap, bonus);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args >= 2)
	{  // Open specified global Bonus # top for specified map
		char argBonus[4], argMap[33];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DisplayMapTopModeMenu(client, argMap, bonus);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}
