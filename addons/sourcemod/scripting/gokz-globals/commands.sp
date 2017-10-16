/*
	Commands
	
	Commands for player use.
*/



// =========================  PUBLIC  ========================= //

void CreateCommands()
{
	RegConsoleCmd("sm_globalcheck", CommandGlobalCheck, "[KZ] Prints whether global records are currently enabled.");
	RegConsoleCmd("sm_gc", CommandGlobalCheck, "[KZ] Prints whether global records are currently enabled.");
	RegConsoleCmd("sm_tier", CommandTier, "[KZ] Prints the map's tier to chat.");
	RegConsoleCmd("sm_gr", CommandPrintRecords, "[KZ] Prints a map's global record times. Usage: !gr <map>");
	RegConsoleCmd("sm_gwr", CommandPrintRecords, "[KZ] Prints a map's global record times. Usage: !gr <map>");
	RegConsoleCmd("sm_gbr", CommandPrintBonusRecords, "[KZ] Prints a map's global bonus record times. Usage: !bgr <#bonus> <map>");
	RegConsoleCmd("sm_gbwr", CommandPrintBonusRecords, "[KZ] Prints a map's global bonus record times. Usage: !bgr <#bonus> <map>");
	RegConsoleCmd("sm_gmaptop", CommandMapTop, "[KZ] Opens a menu showing the top global times of a map. Usage: !gmaptop <map>");
	RegConsoleCmd("sm_gbmaptop", CommandBonusMapTop, "[KZ] Opens a menu showing the top global bonus times of a map. Usage: !gbmaptop <#bonus> <map>");
}



// =========================  COMMAND HANDLERS  ========================= //

public Action CommandGlobalCheck(int client, int args)
{
	PrintGlobalCheck(client);
	return Plugin_Handled;
}

public Action CommandTier(int client, int args)
{
	GOKZ_PrintToChat(client, true, "%t", "Map Tier", gC_CurrentMap, GlobalAPI_GetMapTier());
	return Plugin_Handled;
}

public Action CommandPrintRecords(int client, int args)
{
	KZPlayer player = new KZPlayer(client);
	int mode = player.mode;
	
	if (args == 0)
	{  // Print record times for current map and their current mode
		PrintRecords(client, gC_CurrentMap, 0, mode);
	}
	else if (args >= 1)
	{  // Print record times for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		PrintRecords(client, argMap, 0, mode);
	}
	return Plugin_Handled;
}

public Action CommandPrintBonusRecords(int client, int args)
{
	KZPlayer player = new KZPlayer(client);
	int mode = player.mode;
	
	if (args == 0)
	{  // Print Bonus 1 record times for current map and their current mode
		PrintRecords(client, gC_CurrentMap, 1, mode);
	}
	else if (args == 1)
	{  // Print specified Bonus # record times for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (bonus > 0 && bonus < MAX_COURSES)
		{
			PrintRecords(client, gC_CurrentMap, bonus, mode);
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
		if (bonus > 0 && bonus < MAX_COURSES)
		{
			PrintRecords(client, argMap, bonus, mode);
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
		if (bonus > 0)
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
		if (bonus > 0)
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