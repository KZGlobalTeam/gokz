/*
	Opens a menu with the top times for a map course and mode.
*/



#define ITEM_INFO_GLOBAL_TOP_NUB "gn"
#define ITEM_INFO_GLOBAL_TOP_PRO "gp"

static char mapTopMap[MAXPLAYERS + 1][64];
static int mapTopMapID[MAXPLAYERS + 1];
static int mapTopCourse[MAXPLAYERS + 1];
static int mapTopMode[MAXPLAYERS + 1];



// =====[ MAP TOP MODE ]=====

void DB_OpenMapTopModeMenu(int client, int mapID, int course)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(mapID);
	data.WriteCell(course);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Retrieve Map Name of MapID
	FormatEx(query, sizeof(query), sql_maps_getname, mapID);
	txn.AddQuery(query);
	// Check for existence of map course with that MapID and Course
	FormatEx(query, sizeof(query), sql_mapcourses_findid, mapID, course);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenMapTopModeMenu, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenMapTopModeMenu(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int mapID = data.ReadCell();
	int course = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	// Get name of map
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, mapTopMap[client], sizeof(mapTopMap[]));
	}
	// Check if the map course exists in the database
	if (SQL_GetRowCount(results[1]) == 0)
	{
		if (course == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Main Course Not Found", mapTopMap[client]);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Bonus Not Found", mapTopMap[client], course);
		}
		return;
	}
	
	mapTopMapID[client] = mapID;
	mapTopCourse[client] = course;
	DisplayMapTopModeMenu(client);
}

void DB_OpenMapTopModeMenu_FindMap(int client, const char[] mapSearch, int course)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(mapSearch);
	data.WriteCell(course);
	
	DB_FindMap(mapSearch, DB_TxnSuccess_OpenMapTopModeMenu_FindMap, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenMapTopModeMenu_FindMap(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char mapSearch[33];
	data.ReadString(mapSearch, sizeof(mapSearch));
	int course = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Map Not Found", mapSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{  // Result is the MapID
		DB_OpenMapTopModeMenu(client, SQL_FetchInt(results[0], 0), course);
	}
}



// =====[ MAP TOP ]=====

void DB_OpenMapTop(int client, int mapID, int course, int mode, int timeType)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(course);
	data.WriteCell(mode);
	data.WriteCell(timeType);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Get map name
	FormatEx(query, sizeof(query), sql_maps_getname, mapID);
	txn.AddQuery(query);
	// Check for existence of map course with that MapID and Course
	FormatEx(query, sizeof(query), sql_mapcourses_findid, mapID, course);
	txn.AddQuery(query);
	
	// Get top times for each time type
	switch (timeType)
	{
		case TimeType_Nub:FormatEx(query, sizeof(query), sql_getmaptop, mapID, course, mode, LR_MAP_TOP_CUTOFF);
		case TimeType_Pro:FormatEx(query, sizeof(query), sql_getmaptoppro, mapID, course, mode, LR_MAP_TOP_CUTOFF);
	}
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenMapTop, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenMapTop(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int course = data.ReadCell();
	int mode = data.ReadCell();
	int timeType = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	// Get map name from results
	char mapName[64];
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, mapName, sizeof(mapName));
	}
	// Check if the map course exists in the database
	if (SQL_GetRowCount(results[1]) == 0)
	{
		if (course == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Main Course Not Found", mapName);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Bonus Not Found", mapName, course);
		}
		return;
	}
	
	// Check if there are any times
	if (SQL_GetRowCount(results[2]) == 0)
	{
		switch (timeType)
		{
			case TimeType_Nub:GOKZ_PrintToChat(client, true, "%t", "No Times Found");
			case TimeType_Pro:GOKZ_PrintToChat(client, true, "%t", "No Times Found (PRO)");
		}
		DisplayMapTopMenu(client, mode);
		return;
	}

	Menu menu = new Menu(MenuHandler_MapTopSubmenu);
	menu.Pagination = 5;
	
	// Set submenu title
	if (course == 0)
	{
		menu.SetTitle("%T", "Map Top Submenu - Title", client, 
			LR_MAP_TOP_CUTOFF, gC_TimeTypeNames[timeType], mapName, gC_ModeNames[mode]);
	}
	else
	{
		menu.SetTitle("%T", "Map Top Submenu - Title (Bonus)", client, 
			LR_MAP_TOP_CUTOFF, gC_TimeTypeNames[timeType], mapName, course, gC_ModeNames[mode]);
	}
	
	// Add submenu items
	char display[128], title[65], admin[65];
	char playerName[MAX_NAME_LENGTH];
	float runTime;
	int timeid, steamid, teleports, rank = 0;

	bool clientIsAdmin = CheckCommandAccess(client, "sm_deletetime", ADMFLAG_ROOT, false);

	FormatEx(title, sizeof(title), "%s %s %s %T", gC_ModeNames[mode], mapName, gC_TimeTypeNames[timeType], "Top", client);
	strcopy(display, sizeof(display), "----------------------------------------------------------------");
	display[strlen(title)] = '\0';
	PrintToConsole(client, title);
	PrintToConsole(client, display);
	
	while (SQL_FetchRow(results[2]))
	{
		rank++;
		timeid = SQL_FetchInt(results[2], 0);
		steamid = SQL_FetchInt(results[2], 1);
		SQL_FetchString(results[2], 2, playerName, sizeof(playerName));
		runTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[2], 3));

		if (clientIsAdmin)
		{
			FormatEx(admin, sizeof(admin), "<id: %d>", timeid);
		}

		switch (timeType)
		{
			case TimeType_Nub:
			{
				teleports = SQL_FetchInt(results[2], 4);
				FormatEx(display, sizeof(display), "#%-2d   %11s  %3d TP	  %s", 
					rank, GOKZ_FormatTime(runTime), teleports, playerName);

				PrintToConsole(client, "#%-2d   %11s  %3d TP   %s <STEAM_1:%d:%d>   %s", 
					rank, GOKZ_FormatTime(runTime), teleports, playerName, steamid & 1, steamid >> 1, admin);
			}
			case TimeType_Pro:
			{
				FormatEx(display, sizeof(display), "#%-2d   %11s   %s", 
					rank, GOKZ_FormatTime(runTime), playerName);

				PrintToConsole(client, "#%-2d   %11s   %s <STEAM_1:%d:%d>   %s", 
					rank, GOKZ_FormatTime(runTime), playerName, steamid & 1, steamid >> 1, admin);
			}
		}
		menu.AddItem("", display, ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENUS ]=====

void DisplayMapTopModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MapTopMode);
	MapTopModeMenuSetTitle(client, menu);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void MapTopModeMenuSetTitle(int client, Menu menu)
{
	if (mapTopCourse[client] == 0)
	{
		menu.SetTitle("%T", "Map Top Mode Menu - Title", client, mapTopMap[client]);
	}
	else
	{
		menu.SetTitle("%T", "Map Top Mode Menu - Title (Bonus)", client, mapTopMap[client], mapTopCourse[client]);
	}
}

void DisplayMapTopMenu(int client, int mode)
{
	mapTopMode[client] = mode;
	
	Menu menu = new Menu(MenuHandler_MapTop);
	if (mapTopCourse[client] == 0)
	{
		menu.SetTitle("%T", "Map Top Menu - Title", client, 
			mapTopMap[client], gC_ModeNames[mapTopMode[client]]);
	}
	else
	{
		menu.SetTitle("%T", "Map Top Menu - Title (Bonus)", client, 
			mapTopMap[client], mapTopCourse[client], gC_ModeNames[mapTopMode[client]]);
	}
	MapTopMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void MapTopMenuAddItems(int client, Menu menu)
{
	char display[32];
	for (int i = 0; i < TIMETYPE_COUNT; i++)
	{
		FormatEx(display, sizeof(display), "%T", "Map Top Menu - Top", client, LR_MAP_TOP_CUTOFF, gC_TimeTypeNames[i]);
		menu.AddItem(IntToStringEx(i), display);
	}
	if (gB_GOKZGlobal)
	{
		FormatEx(display, sizeof(display), "%T", "Map Top Menu - Global Top", client, gC_TimeTypeNames[TimeType_Nub]);
		menu.AddItem(ITEM_INFO_GLOBAL_TOP_NUB, display);
		
		FormatEx(display, sizeof(display), "%T", "Map Top Menu - Global Top", client, gC_TimeTypeNames[TimeType_Pro]);
		menu.AddItem(ITEM_INFO_GLOBAL_TOP_PRO, display);
	}
}

void ReopenMapTopMenu(int client)
{
	DisplayMapTopMenu(client, mapTopMode[client]);
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_MapTopMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = mode
		DisplayMapTopMenu(param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_MapTop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		
		if (gB_GOKZGlobal && StrEqual(info, ITEM_INFO_GLOBAL_TOP_NUB))
		{
			GOKZ_GL_DisplayMapTopMenu(param1, mapTopMap[param1], mapTopCourse[param1], mapTopMode[param1], TimeType_Nub);
		}
		else if (gB_GOKZGlobal && StrEqual(info, ITEM_INFO_GLOBAL_TOP_PRO))
		{
			GOKZ_GL_DisplayMapTopMenu(param1, mapTopMap[param1], mapTopCourse[param1], mapTopMode[param1], TimeType_Pro);
		}
		else
		{
			int timeType = StringToInt(info);
			DB_OpenMapTop(param1, mapTopMapID[param1], mapTopCourse[param1], mapTopMode[param1], timeType);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayMapTopModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_MapTopSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	// TODO Menu item info is player's SteamID32, but is currently not used
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		ReopenMapTopMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
} 