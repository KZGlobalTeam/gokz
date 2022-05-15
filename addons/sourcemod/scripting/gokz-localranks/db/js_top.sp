
static int jumpTopMode[MAXPLAYERS + 1];
static int jumpTopType[MAXPLAYERS + 1];
static int blockNums[MAXPLAYERS + 1][JS_TOP_RECORD_COUNT];
static int jumpInfo[MAXPLAYERS + 1][JS_TOP_RECORD_COUNT][3];



void DB_OpenJumpTop(int client, int mode, int jumpType, int blockType)
{
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();

	FormatEx(query, sizeof(query), sql_jumpstats_gettop, jumpType, mode, blockType, jumpType, mode, blockType, JS_TOP_RECORD_COUNT);
	txn.AddQuery(query);

	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(mode);
	data.WriteCell(jumpType);
	data.WriteCell(blockType);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_GetJumpTop, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

void DB_TxnSuccess_GetJumpTop(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int mode = data.ReadCell();
	int type = data.ReadCell();
	int blockType = data.ReadCell();
	delete data;

	if (!IsValidClient(client))
	{
		return;
	}

	jumpTopMode[client] = mode;
	jumpTopType[client] = type;

	int rows = SQL_GetRowCount(results[0]);
	if (rows == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Jumpstats Found");
		DisplayJumpTopBlockTypeMenu(client, mode, type);
		return;
	}
	
	char display[128], alias[33], title[65], admin[65];
	int jumpid, steamid, block, strafes;
	float distance, sync, pre, max, airtime;

	bool clientIsAdmin = CheckCommandAccess(client, "sm_deletejump", ADMFLAG_ROOT, false);

	Menu menu = new Menu(MenuHandler_JumpTopList);
	menu.Pagination = 5;
	
	if (blockType == 0)
	{
		menu.SetTitle("%T", "Jump Top Submenu - Title (Jump)", client, gC_ModeNames[mode], gC_JumpTypes[type]);

		FormatEx(title, sizeof(title), "%s %s %T", gC_ModeNames[mode], gC_JumpTypes[type], "Top", client);
		strcopy(display, sizeof(display), "----------------------------------------------------------------");
		display[strlen(title)] = '\0';
		
		PrintToConsole(client, title);
		PrintToConsole(client, display);
		
		for (int i = 0; i < rows; i++)
		{
			SQL_FetchRow(results[0]);
			jumpid = SQL_FetchInt(results[0], JumpstatDB_Top20_JumpID);
			steamid = SQL_FetchInt(results[0], JumpstatDB_Top20_SteamID);
			SQL_FetchString(results[0], JumpstatDB_Top20_Alias, alias, sizeof(alias));
			distance = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Distance)) / GOKZ_DB_JS_DISTANCE_PRECISION;
			strafes = SQL_FetchInt(results[0], JumpstatDB_Top20_Strafes);
			sync = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Sync)) / GOKZ_DB_JS_SYNC_PRECISION;
			pre = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Pre)) / GOKZ_DB_JS_PRE_PRECISION;
			max = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Max)) / GOKZ_DB_JS_MAX_PRECISION;
			airtime = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Air)) / GOKZ_DB_JS_AIRTIME_PRECISION;
			
			FormatEx(display, sizeof(display), "#%-2d   %.4f   %s", i + 1, distance, alias);

			menu.AddItem(IntToStringEx(i), display);

			if (clientIsAdmin)
			{
				FormatEx(admin, sizeof(admin), "<id: %d>", jumpid);
			}

			PrintToConsole(client, "#%-2d   %.4f   %s <STEAM_1:%d:%d>   [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t]   %s", 
				i + 1, distance, alias, steamid & 1, steamid >> 1, 
				strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", airtime, "Air",
				admin);

			jumpInfo[client][i][0] = steamid;
			jumpInfo[client][i][1] = type;
			jumpInfo[client][i][2] = mode;
			blockNums[client][i] = 0;
		}
	}
	else
	{
		menu.SetTitle("%T", "Jump Top Submenu - Title (Block Jump)", client, gC_ModeNames[mode], gC_JumpTypes[type]);

		FormatEx(title, sizeof(title), "%s %T %s %T", gC_ModeNames[mode], "Block", client, gC_JumpTypes[type], "Top", client);
		strcopy(display, sizeof(display), "----------------------------------------------------------------");
		display[strlen(title)] = '\0';
		
		PrintToConsole(client, title);
		PrintToConsole(client, display);
		
		for (int i = 0; i < rows; i++)
		{
			SQL_FetchRow(results[0]);
			jumpid = SQL_FetchInt(results[0], JumpstatDB_Top20_JumpID);
			steamid = SQL_FetchInt(results[0], JumpstatDB_Top20_SteamID);
			SQL_FetchString(results[0], JumpstatDB_Top20_Alias, alias, sizeof(alias));
			block = SQL_FetchInt(results[0], JumpstatDB_Top20_Block);
			distance = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Distance)) / GOKZ_DB_JS_DISTANCE_PRECISION;
			strafes = SQL_FetchInt(results[0], JumpstatDB_Top20_Strafes);
			sync = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Sync)) / GOKZ_DB_JS_SYNC_PRECISION;
			pre = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Pre)) / GOKZ_DB_JS_PRE_PRECISION;
			max = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Max)) / GOKZ_DB_JS_MAX_PRECISION;
			airtime = float(SQL_FetchInt(results[0], JumpstatDB_Top20_Air)) / GOKZ_DB_JS_AIRTIME_PRECISION;
			
			FormatEx(display, sizeof(display), "#%-2d   %d %T (%.4f)   %s", i + 1, block, "Block", client, distance, alias);
			menu.AddItem(IntToStringEx(i), display);
			
			if (clientIsAdmin)
			{
				FormatEx(admin, sizeof(admin), "<id: %d>", jumpid);
			}
			
			PrintToConsole(client, "#%-2d   %d %t (%.4f)   %s <STEAM_1:%d:%d>   [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t]   %s", 
				i + 1, block, "Block", distance, alias, steamid & 1, steamid >> 1, 
				strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", airtime, "Air", 
				admin);

			jumpInfo[client][i][0] = steamid;
			jumpInfo[client][i][1] = type;
			jumpInfo[client][i][2] = mode;
			blockNums[client][i] = block;
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	PrintToConsole(client, "");
}

// =====[ MENUS ]=====

void DisplayJumpTopModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_JumpTopMode);
	menu.SetTitle("%T", "Jump Top Mode Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayJumpTopTypeMenu(int client, int mode)
{
	jumpTopMode[client] = mode;
	
	Menu menu = new Menu(MenuHandler_JumpTopType);
	menu.SetTitle("%T", "Jump Top Type Menu - Title", client, gC_ModeNames[jumpTopMode[client]]);
	JumpTopTypeMenuAddItems(menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void JumpTopTypeMenuAddItems(Menu menu)
{
	char display[32];
	for (int i = 0; i < JUMPTYPE_COUNT - 3; i++)
	{
		FormatEx(display, sizeof(display), "%s", gC_JumpTypes[i]);
		menu.AddItem(IntToStringEx(i), display);
	}
}

void DisplayJumpTopBlockTypeMenu(int client, int mode, int type)
{
	jumpTopMode[client] = mode;
	jumpTopType[client] = type;
	
	Menu menu = new Menu(MenuHandler_JumpTopBlockType);
	menu.SetTitle("%T", "Jump Top Block Type Menu - Title", client, gC_ModeNames[jumpTopMode[client]], gC_JumpTypes[jumpTopType[client]]);
	JumpTopBlockTypeMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void JumpTopBlockTypeMenuAddItems(int client, Menu menu)
{
	char str[64];
	FormatEx(str, sizeof(str), "%T", "Jump Records", client);
	menu.AddItem("jump", str);
	FormatEx(str, sizeof(str), "%T %T", "Block", client, "Jump Records", client);
	menu.AddItem("blockjump", str);
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_JumpTopMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = mode
		DisplayJumpTopTypeMenu(param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_JumpTopType(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = type
		DisplayJumpTopBlockTypeMenu(param1, jumpTopMode[param1], param2);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayJumpTopModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_JumpTopBlockType(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = block type
		DB_OpenJumpTop(param1, jumpTopMode[param1], jumpTopType[param1], param2);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayJumpTopTypeMenu(param1, jumpTopMode[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_JumpTopList(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char path[PLATFORM_MAX_PATH];
		if (blockNums[param1][param2] == 0)
		{
			BuildPath(Path_SM, path, sizeof(path), 
				"%s/%d/%d_%s_%s.%s", 
				RP_DIRECTORY_JUMPS, jumpInfo[param1][param2][0], jumpTopType[param1], gC_ModeNamesShort[jumpInfo[param1][param2][2]], gC_StyleNamesShort[0], RP_FILE_EXTENSION);
		}
		else
		{
			BuildPath(Path_SM, path, sizeof(path), 
				"%s/%d/%s/%d_%d_%s_%s.%s", 
				RP_DIRECTORY_JUMPS, jumpInfo[param1][param2][0], RP_DIRECTORY_BLOCKJUMPS, jumpTopType[param1], blockNums[param1][param2], gC_ModeNamesShort[jumpInfo[param1][param2][2]], gC_StyleNamesShort[0], RP_FILE_EXTENSION);
		}
		GOKZ_RP_LoadJumpReplay(param1, path);
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayJumpTopBlockTypeMenu(param1, jumpTopMode[param1], jumpTopType[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

// =====[ UTILITY ]=====

public Action Timer_ResetSpectate(Handle timer, int clientUID)
{
	int client = GetClientOfUserId(clientUID);
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iObserverMode", -1);
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	}
}
public Action Timer_SpectateBot(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int botClient = GetClientOfUserId(data.ReadCell());
	delete data;
	
	if (IsValidClient(client) && IsValidClient(botClient))
	{
		GOKZ_JoinTeam(client, CS_TEAM_SPECTATOR);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", botClient);
	}
	return Plugin_Continue;
}