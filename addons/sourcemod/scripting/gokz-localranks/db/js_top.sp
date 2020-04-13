
static int jumpTopMode[MAXPLAYERS + 1];
static int jumpTopType[MAXPLAYERS + 1];
static int jumpTopBlockType[MAXPLAYERS + 1];



void DB_GetJumpTop(int client)
{
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();

	FormatEx(query, sizeof(query), sql_jumpstats_gettop, jumpTopType[client], jumpTopMode[client], jumpTopBlockType[client], jumpTopType[client], jumpTopMode[client], jumpTopBlockType[client], JS_TOP_RECORD_COUNT);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_GetJumpTop, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_Low);
}

void DB_TxnSuccess_GetJumpTop(Handle db, int userID, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userID);
	if (!IsValidClient(client))
	{
		return;
	}

	int rows = SQL_GetRowCount(results[0]);
	if (rows == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Jumpstats Found");
		return;
	}
	
	char display[128], alias[33], title[65];
	int steamid, block, strafes;
	float distance, sync, pre, max, airtime;
	
	Menu menu = new Menu(MenuHandler_JumpTopList);
	menu.Pagination = 5;
	
	if (jumpTopBlockType[client] == 0)
	{
		FormatEx(title, sizeof(title), "%s %s %T", gC_ModeNames[jumpTopMode[client]], gC_JumpTypes[jumpTopType[client]], "Top", client);
		strcopy(display, sizeof(display), "----------------------------------------------------------------");
		display[strlen(title)] = '\0';
		
		PrintToConsole(client, title);
		PrintToConsole(client, display);
		
		for (int i = 0; i < rows; i++)
		{
			SQL_FetchRow(results[0]);
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
			
			PrintToConsole(client, "#%-2d   %.4f   %s <STEAM_1:%d:%d>   [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t]", 
				i + 1, distance, alias, steamid & 1, steamid >> 1, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", airtime, "Air");
		}
	}
	else
	{
		FormatEx(title, sizeof(title), "%s %T %s %T", gC_ModeNames[jumpTopMode[client]], "Block", client, gC_JumpTypes[jumpTopType[client]], "Top", client);
		strcopy(display, sizeof(display), "----------------------------------------------------------------");
		display[strlen(title)] = '\0';
		
		PrintToConsole(client, title);
		PrintToConsole(client, display);
		
		for (int i = 0; i < rows; i++)
		{
			SQL_FetchRow(results[0]);
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
			
			PrintToConsole(client, "#%-2d   %d %t (%.4f)   %s <STEAM_1:%d:%d>   [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t]", 
				i + 1, block, "Block", distance, alias, steamid & 1, steamid >> 1, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", airtime, "Air");
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	PrintToConsole(client, "");
}

// =====[ MENUS ]=====

void DisplayJumpTopModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_JumpTopMode);
	menu.SetTitle("%T %T", "Jumpstats", client, "Top", client);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayJumpTopTypeMenu(int client, int mode)
{
	jumpTopMode[client] = mode;
	
	Menu menu = new Menu(MenuHandler_JumpTopType);
	menu.SetTitle("%s %T %T", gC_ModeNames[jumpTopMode[client]], "Jumpstats", client, "Top", client);
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

void DisplayJumpTopBlockTypeMenu(int client, int type)
{
	jumpTopType[client] = type;
	
	Menu menu = new Menu(MenuHandler_JumpTopBlockType);
	menu.SetTitle("%s %s %T", gC_ModeNames[jumpTopMode[client]], gC_JumpTypes[jumpTopType[client]], "Top", client);
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

void DisplayJumpTopMenu(int client, int blockType)
{
	jumpTopBlockType[client] = blockType;
	DB_GetJumpTop(client);
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
		DisplayJumpTopBlockTypeMenu(param1, param2);
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
		DisplayJumpTopMenu(param1, param2);
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
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		if (jumpTopType[param1] == JumpType_LadderJump)
		{
			DisplayJumpTopTypeMenu(param1, jumpTopMode[param1]);
		}
		else
		{
			DisplayJumpTopBlockTypeMenu(param1, jumpTopType[param1]);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
