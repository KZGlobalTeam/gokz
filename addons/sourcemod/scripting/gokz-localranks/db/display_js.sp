/*
	Displays player's best jumpstats in a menu.
*/

static int jumpStatsTargetSteamID[MAXPLAYERS + 1];
static char jumpStatsTargetAlias[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static int jumpStatsMode[MAXPLAYERS + 1];



// =====[ JUMPSTATS MODE ]=====

void DB_OpenJumpStatsModeMenu(int client, int targetSteamID)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(targetSteamID);

	Transaction txn = SQL_CreateTransaction();

	// Retrieve name of target
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenJumpStatsModeMenu, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenJumpStatsModeMenu(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int targetSteamID = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	// Get name of target
	if (!SQL_FetchRow(results[0]))
	{
		return;
	}
	SQL_FetchString(results[0], 0, jumpStatsTargetAlias[client], sizeof(jumpStatsTargetAlias[]));
	
	jumpStatsTargetSteamID[client] = targetSteamID;
	DisplayJumpStatsModeMenu(client);
}

void DB_OpenJumpStatsModeMenu_FindPlayer(int client, const char[] target)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(target);
	
	DB_FindPlayer(target, DB_TxnSuccess_OpenJumpStatsModeMenu_FindPlayer, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenJumpStatsModeMenu_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char playerSearch[33];
	data.ReadString(playerSearch, sizeof(playerSearch));
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	else if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{
		DB_OpenJumpStatsModeMenu(client, SQL_FetchInt(results[0], 0));
	}
} 



// =====[ MENUS ]=====

static void DisplayJumpStatsModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_JumpStatsMode);
	menu.SetTitle("%T", "Jump Stats Mode Menu - Title", client, jumpStatsTargetAlias[client]);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void DisplayJumpStatsBlockTypeMenu(int client, int mode)
{
	jumpStatsMode[client] = mode;
	
	Menu menu = new Menu(MenuHandler_JumpStatsBlockType);
	menu.SetTitle("%T", "Jump Stats Block Type Menu - Title", client, jumpStatsTargetAlias[client], gC_ModeNames[jumpStatsMode[client]]);
	JumpStatsBlockTypeMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void JumpStatsBlockTypeMenuAddItems(int client, Menu menu)
{
	char str[64];
	FormatEx(str, sizeof(str), "%T", "Jump Records", client);
	menu.AddItem("jump", str);
	FormatEx(str, sizeof(str), "%T %T", "Block", client, "Jump Records", client);
	menu.AddItem("blockjump", str);
}



// =====[ JUMPSTATS ]=====

void DB_OpenJumpStats(int client, int targetSteamID, int mode, int blockType)
{
	char query[1024];
	Transaction txn = SQL_CreateTransaction();

	// Get alias
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	// Get jumpstat pbs
	if (blockType == 0)
	{
		FormatEx(query, sizeof(query), sql_jumpstats_getpbs, targetSteamID, mode);
	}
	else
	{
		FormatEx(query, sizeof(query), sql_jumpstats_getblockpbs, targetSteamID, mode);
	}
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(targetSteamID);
	datapack.WriteCell(mode);
	datapack.WriteCell(blockType);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenJumpStats, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_OpenJumpStats(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int targetSteamID = datapack.ReadCell();
	int mode = datapack.ReadCell();
	int blockType = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	// Get target name
	if (!SQL_FetchRow(results[0]))
	{
		return;
	}
	char alias[MAX_NAME_LENGTH];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));

	if (SQL_GetRowCount(results[1]) == 0)
	{
		if (blockType == 0)
		{
			GOKZ_PrintToChat(client, true, "%T", "Jump Stats Menu - No Jump Stats", client, alias);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%T", "Jump Stats Menu - No Block Jump Stats", client, alias);
		}
		
		DisplayJumpStatsBlockTypeMenu(client, mode);
		return;
	}

	Menu menu = new Menu(MenuHandler_JumpStatsSubmenu);
	if (blockType == 0)
	{
		menu.SetTitle("%T", "Jump Stats Submenu - Title (Jump)", client, alias, gC_ModeNames[mode]);
	}
	else
	{
		menu.SetTitle("%T", "Jump Stats Submenu - Title (Block Jump)", client, alias, gC_ModeNames[mode]);
	}

	char buffer[128], admin[64];
	bool clientIsAdmin = CheckCommandAccess(client, "sm_deletejump", ADMFLAG_ROOT, false);

	if (blockType == 0)
	{
		FormatEx(buffer, sizeof(buffer), "%T", "Jump Stats - Jump Console Header", 
			client, gC_ModeNames[mode], alias, targetSteamID & 1, targetSteamID >> 1);
		PrintToConsole(client, "%s", buffer);
		int titleLength = strlen(buffer);
		strcopy(buffer, sizeof(buffer), "----------------------------------------------------------------");
		buffer[titleLength] = '\0';
		PrintToConsole(client, "%s", buffer);

		while (SQL_FetchRow(results[1]))
		{
			int jumpid = SQL_FetchInt(results[1], JumpstatDB_PBMenu_JumpID);
			int jumpType = SQL_FetchInt(results[1], JumpstatDB_PBMenu_JumpType);
			float distance = SQL_FetchFloat(results[1], JumpstatDB_PBMenu_Distance) / GOKZ_DB_JS_DISTANCE_PRECISION;
			int strafes = SQL_FetchInt(results[1], JumpstatDB_PBMenu_Strafes);
			float sync = SQL_FetchFloat(results[1], JumpstatDB_PBMenu_Sync) / GOKZ_DB_JS_SYNC_PRECISION;
			float pre = SQL_FetchFloat(results[1], JumpstatDB_PBMenu_Pre) / GOKZ_DB_JS_PRE_PRECISION;
			float max = SQL_FetchFloat(results[1], JumpstatDB_PBMenu_Max) / GOKZ_DB_JS_MAX_PRECISION;
			float airtime = SQL_FetchFloat(results[1], JumpstatDB_PBMenu_Air) / GOKZ_DB_JS_AIRTIME_PRECISION;

			FormatEx(buffer, sizeof(buffer), "%0.4f  %s", distance, gC_JumpTypes[jumpType]);
			menu.AddItem("", buffer, ITEMDRAW_DISABLED);

			FormatEx(buffer, sizeof(buffer), "%8s", gC_JumpTypesShort[jumpType]);
			buffer[3] = '\0';

			if (clientIsAdmin)
			{
				FormatEx(admin, sizeof(admin), "<id: %d>", jumpid);
			}

			PrintToConsole(client, "%s  %0.4f  [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t]   %s", 
				buffer, distance, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", airtime, "Air", admin);
		}
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%T", "Jump Stats - Block Jump Console Header", 
			client, gC_ModeNames[mode], alias, targetSteamID & 1, targetSteamID >> 1);
		PrintToConsole(client, "%s", buffer);
		int titleLength = strlen(buffer);
		strcopy(buffer, sizeof(buffer), "----------------------------------------------------------------");
		buffer[titleLength] = '\0';
		PrintToConsole(client, "%s", buffer);

		while (SQL_FetchRow(results[1]))
		{
			int jumpid = SQL_FetchInt(results[1], JumpstatDB_BlockPBMenu_JumpID);
			int jumpType = SQL_FetchInt(results[1], JumpstatDB_BlockPBMenu_JumpType);
			int block = SQL_FetchInt(results[1], JumpstatDB_BlockPBMenu_Block);
			float distance = SQL_FetchFloat(results[1], JumpstatDB_BlockPBMenu_Distance) / GOKZ_DB_JS_DISTANCE_PRECISION;
			int strafes = SQL_FetchInt(results[1], JumpstatDB_BlockPBMenu_Strafes);
			float sync = SQL_FetchFloat(results[1], JumpstatDB_BlockPBMenu_Sync) / GOKZ_DB_JS_SYNC_PRECISION;
			float pre = SQL_FetchFloat(results[1], JumpstatDB_BlockPBMenu_Pre) / GOKZ_DB_JS_PRE_PRECISION;
			float max = SQL_FetchFloat(results[1], JumpstatDB_BlockPBMenu_Max) / GOKZ_DB_JS_MAX_PRECISION;
			float airtime = SQL_FetchFloat(results[1], JumpstatDB_BlockPBMenu_Air) / GOKZ_DB_JS_AIRTIME_PRECISION;

			FormatEx(buffer, sizeof(buffer), "%d %T (%0.4f)  %s", block, "Block", client, distance, gC_JumpTypes[jumpType]);
			menu.AddItem("", buffer, ITEMDRAW_DISABLED);

			FormatEx(buffer, sizeof(buffer), "%8s", gC_JumpTypesShort[jumpType]);
			buffer[3] = '\0';

			if (clientIsAdmin)
			{
				FormatEx(admin, sizeof(admin), "<id: %d>", jumpid);
			}

			PrintToConsole(client, "%s  %d %t (%0.4f)  [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t]   %s", 
				buffer, block, "Block", distance, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", airtime, "Air", admin);
		}
	}

	PrintToConsole(client, "");
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_JumpStatsMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = mode
		DisplayJumpStatsBlockTypeMenu(param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_JumpStatsBlockType(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = blockType
		DB_OpenJumpStats(param1, jumpStatsTargetSteamID[param1], jumpStatsMode[param1], param2);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayJumpStatsModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_JumpStatsSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayJumpStatsBlockTypeMenu(param1, jumpStatsMode[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}