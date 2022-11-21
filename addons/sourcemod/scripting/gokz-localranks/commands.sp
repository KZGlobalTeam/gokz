static float lastCommandTime[MAXPLAYERS + 1];



void RegisterCommands()
{
	RegConsoleCmd("sm_top", CommandTop, "[KZ] Open a menu showing the top record holders.");
	RegConsoleCmd("sm_maptop", CommandMapTop, "[KZ] Open a menu showing the top main course times of a map. Usage: !maptop <map>");
	RegConsoleCmd("sm_bmaptop", CommandBMapTop, "[KZ] Open a menu showing the top bonus times of a map. Usage: !bmaptop <#bonus> <map>");
	RegConsoleCmd("sm_bonustop", CommandBMapTop, "[KZ] Open a menu showing the top bonus times of a map. Usage: !bonustop <#bonus> <map>");
	RegConsoleCmd("sm_btop", CommandBMapTop, "[KZ] Open a menu showing the top bonus times of a map. Usage: !btop <#bonus> <map>");
	RegConsoleCmd("sm_pb", CommandPB, "[KZ] Show PB main course times and ranks in chat. Usage: !pb <map> <player>");
	RegConsoleCmd("sm_bpb", CommandBPB, "[KZ] Show PB bonus times and ranks in chat. Usage: !bpb <#bonus> <map> <player>");
	RegConsoleCmd("sm_wr", CommandWR, "[KZ] Show main course record times in chat. Usage: !wr <map>");
	RegConsoleCmd("sm_bwr", CommandBWR, "[KZ] Show bonus record times in chat. Usage: !bwr <#bonus> <map>");
	RegConsoleCmd("sm_avg", CommandAVG, "[KZ] Show the average main course run time in chat. Usage !avg <map>");
	RegConsoleCmd("sm_bavg", CommandBAVG, "[KZ] Show the average bonus run time in chat. Usage !bavg <#bonus> <map>");
	RegConsoleCmd("sm_pc", CommandPC, "[KZ] Show course completion in chat. Usage: !pc <player>");
	RegConsoleCmd("sm_rr", CommandRecentRecords, "[KZ] Open a menu showing recently broken records.");
	RegConsoleCmd("sm_latest", CommandRecentRecords, "[KZ] Open a menu showing recently broken records.");

	RegConsoleCmd("sm_ljpb", CommandLJPB, "[KZ] Show PB Long Jump in chat. Usage: !ljpb <jumper>");
	RegConsoleCmd("sm_bhpb", CommandBHPB, "[KZ] Show PB Bunnyhop in chat. Usage: !bhpb <jumper>");
	RegConsoleCmd("sm_lbhpb", CommandLBHPB, "[KZ] Show PB Lowpre Bunnyhop in chat. Usage: !lbhpb <jumper>");
	RegConsoleCmd("sm_mbhpb", CommandMBHPB, "[KZ] Show PB Multi Bunnyhop in chat. Usage: !mbhpb <jumper>");
	RegConsoleCmd("sm_wjpb", CommandWJPB, "[KZ] Show PB Weird Jump in chat. Usage: !wjpb <jumper>");
	RegConsoleCmd("sm_lwjpb", CommandLWJPB, "[KZ] Show PB Lowpre Weird Jump in chat. Usage: !lwjpb <jumper>");
	RegConsoleCmd("sm_lajpb", CommandLAJPB, "[KZ] Show PB Ladder Jump in chat. Usage: !lajpb <jumper>");
	RegConsoleCmd("sm_lahpb", CommandLAHPB, "[KZ] Show PB Ladderhop in chat. Usage: !lahpb <jumper>");
	RegConsoleCmd("sm_jbpb", CommandJBPB, "[KZ] Show PB Jumpbug in chat. Usage: !jbpb <jumper>");
	RegConsoleCmd("sm_js", CommandJS, "[KZ] Open a menu showing jumpstat PBs. Usage: !js <jumper>");
	RegConsoleCmd("sm_jumpstats", CommandJS, "[KZ] Open a menu showing jumpstat PBs. Usage: !jumpstats <jumper>");
	RegConsoleCmd("sm_jstop", CommandJSTop, "[KZ] Open a menu showing the top jumpstats.");
	RegConsoleCmd("sm_jumptop", CommandJSTop, "[KZ] Open a menu showing the top jumpstats.");

	RegAdminCmd("sm_updatemappool", CommandUpdateMapPool, ADMFLAG_ROOT, "[KZ] Update the ranked map pool with the list of maps in cfg/sourcemod/gokz/gokz-localranks-mappool.cfg.");
}

public Action CommandTop(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}

	DisplayPlayerTopModeMenu(client);
	return Plugin_Handled;
}

public Action CommandMapTop(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}

	if (args == 0)
	{  // Open map top for current map
		DB_OpenMapTopModeMenu(client, GOKZ_DB_GetCurrentMapID(), 0);
	}
	else if (args >= 1)
	{  // Open map top for specified map
		char specifiedMap[33];
		GetCmdArg(1, specifiedMap, sizeof(specifiedMap));
		DB_OpenMapTopModeMenu_FindMap(client, specifiedMap, 0);
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
	{  // Open Bonus 1 top for current map
		DB_OpenMapTopModeMenu(client, GOKZ_DB_GetCurrentMapID(), 1);
	}
	else if (args == 1)
	{  // Open specified Bonus # top for current map
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_OpenMapTopModeMenu(client, GOKZ_DB_GetCurrentMapID(), bonus);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	else if (args >= 2)
	{  // Open specified bonus top for specified map
		char argBonus[4], argMap[33];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		GetCmdArg(2, argMap, sizeof(argMap));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_OpenMapTopModeMenu_FindMap(client, argMap, bonus);
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
		DB_PrintPBs(client, GetSteamAccountID(client), GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetCoreOption(client, Option_Mode));
		if (gB_GOKZGlobal)
		{
			char steamid[32];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			GOKZ_GL_PrintRecords(client, "", 0, GOKZ_GetCoreOption(client, Option_Mode), steamid);
		}
	}
	else if (args == 1)
	{  // Print their PBs for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DB_PrintPBs_FindMap(client, GetSteamAccountID(client), argMap, 0, GOKZ_GetCoreOption(client, Option_Mode));
	}
	else if (args >= 2)
	{  // Print specified player's PBs for specified map and their current mode
		char argMap[33], argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argMap, sizeof(argMap));
		GetCmdArg(2, argPlayer, sizeof(argPlayer));
		DB_PrintPBs_FindPlayerAndMap(client, argPlayer, argMap, 0, GOKZ_GetCoreOption(client, Option_Mode));
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
		DB_PrintPBs(client, GetSteamAccountID(client), GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetCoreOption(client, Option_Mode));
		if (gB_GOKZGlobal)
		{
			char steamid[32];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			GOKZ_GL_PrintRecords(client, "", 1, GOKZ_GetCoreOption(client, Option_Mode), steamid);
		}
	}
	else if (args == 1)
	{  // Print their specified Bonus # PBs for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_PrintPBs(client, GetSteamAccountID(client), GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetCoreOption(client, Option_Mode));
			if (gB_GOKZGlobal)
			{
				char steamid[32];
				GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
				GOKZ_GL_PrintRecords(client, "", bonus, GOKZ_GetCoreOption(client, Option_Mode), steamid);
			}
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
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_PrintPBs_FindMap(client, GetSteamAccountID(client), argMap, bonus, GOKZ_GetCoreOption(client, Option_Mode));
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
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_PrintPBs_FindPlayerAndMap(client, argPlayer, argMap, bonus, GOKZ_GetCoreOption(client, Option_Mode));
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
		DB_PrintRecords(client, GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetCoreOption(client, Option_Mode));
		if (gB_GOKZGlobal)
		{
			GOKZ_GL_PrintRecords(client, "", 0, GOKZ_GetCoreOption(client, Option_Mode));
		}
	}
	else if (args >= 1)
	{  // Print record times for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DB_PrintRecords_FindMap(client, argMap, 0, GOKZ_GetCoreOption(client, Option_Mode));
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
		DB_PrintRecords(client, GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetCoreOption(client, Option_Mode));
		if (gB_GOKZGlobal)
		{
			GOKZ_GL_PrintRecords(client, "", 1, GOKZ_GetCoreOption(client, Option_Mode));
		}
	}
	else if (args == 1)
	{  // Print specified Bonus # record times for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_PrintRecords(client, GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetCoreOption(client, Option_Mode));
			if (gB_GOKZGlobal)
			{
				GOKZ_GL_PrintRecords(client, "", bonus, GOKZ_GetCoreOption(client, Option_Mode));
			}
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
			DB_PrintRecords_FindMap(client, argMap, bonus, GOKZ_GetCoreOption(client, Option_Mode));
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
		DB_PrintAverage(client, GOKZ_DB_GetCurrentMapID(), 0, GOKZ_GetCoreOption(client, Option_Mode));
	}
	else if (args >= 1)
	{  // Print average times for specified map and their current mode
		char argMap[33];
		GetCmdArg(1, argMap, sizeof(argMap));
		DB_PrintAverage_FindMap(client, argMap, 0, GOKZ_GetCoreOption(client, Option_Mode));
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
		DB_PrintAverage(client, GOKZ_DB_GetCurrentMapID(), 1, GOKZ_GetCoreOption(client, Option_Mode));
	}
	else if (args == 1)
	{  // Print specified Bonus # average times for current map and their current mode
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_PrintAverage(client, GOKZ_DB_GetCurrentMapID(), bonus, GOKZ_GetCoreOption(client, Option_Mode));
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
		if (GOKZ_IsValidCourse(bonus, true))
		{
			DB_PrintAverage_FindMap(client, argMap, bonus, GOKZ_GetCoreOption(client, Option_Mode));
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
		DB_GetCompletion(client, GetSteamAccountID(client), GOKZ_GetCoreOption(client, Option_Mode), true);
	}
	else if (args >= 1)
	{  // Print record times for specified map and their current mode
		char argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argPlayer, sizeof(argPlayer));
		DB_GetCompletion_FindPlayer(client, argPlayer, GOKZ_GetCoreOption(client, Option_Mode));
	}
	return Plugin_Handled;
}

public Action CommandRecentRecords(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}

	DisplayRecentRecordsModeMenu(client);
	return Plugin_Handled;
}

public Action CommandUpdateMapPool(int client, int args)
{
	DB_UpdateRankedMapPool(client);
	return Plugin_Handled;
}

public Action CommandLJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_LongJump);
	return Plugin_Handled;
}

public Action CommandBHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_Bhop);
	return Plugin_Handled;
}

public Action CommandLBHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_LowpreBhop);
	return Plugin_Handled;
}

public Action CommandMBHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_MultiBhop);
	return Plugin_Handled;
}

public Action CommandWJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_WeirdJump);
	return Plugin_Handled;
}

public Action CommandLWJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_LowpreWeirdJump);
	return Plugin_Handled;
}

public Action CommandLAJPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_LadderJump);
	return Plugin_Handled;
}

public Action CommandLAHPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_Ladderhop);
	return Plugin_Handled;
}

public Action CommandJBPB(int client, int args)
{
	DisplayJumpstatRecordCommand(client, args, JumpType_Jumpbug);
	return Plugin_Handled;
}

public Action CommandJS(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		DB_OpenJumpStatsModeMenu(client, GetSteamAccountID(client));
	}
	else if (args >= 1)
	{
		char argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argPlayer, sizeof(argPlayer));
		DB_OpenJumpStatsModeMenu_FindPlayer(client, argPlayer);
	}
	return Plugin_Handled;
}

public Action CommandJSTop(int client, int args)
{
	DisplayJumpTopModeMenu(client);
	return Plugin_Handled;
}

void DisplayJumpstatRecordCommand(int client, int args, int jumpType)
{
	if (args >= 1)
	{
		char argJumper[33];
		GetCmdArg(1, argJumper, sizeof(argJumper));
		DisplayJumpstatRecord(client, jumpType, argJumper);
	}
	else
	{
		DisplayJumpstatRecord(client, jumpType);
	}
}



// =====[ PRIVATE ]=====

bool IsSpammingCommands(int client, bool printMessage = true)
{
	float currentTime = GetEngineTime();
	float timeSinceLastCommand = currentTime - lastCommandTime[client];
	if (timeSinceLastCommand < LR_COMMAND_COOLDOWN)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command", LR_COMMAND_COOLDOWN - timeSinceLastCommand + 0.1);
		}
		return true;
	}

	// Not spamming commands - all good!
	lastCommandTime[client] = currentTime;
	return false;
}