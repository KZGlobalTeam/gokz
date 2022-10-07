/*
	Opens the menu with a list of recently broken records for the given mode 
	and time type.
*/



static int recentRecordsMode[MAXPLAYERS + 1];



void DB_OpenRecentRecords(int client, int mode, int timeType)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(mode);
	data.WriteCell(timeType);
	
	Transaction txn = SQL_CreateTransaction();
	
	switch (timeType)
	{
		case TimeType_Nub:FormatEx(query, sizeof(query), sql_getrecentrecords, mode, LR_PLAYER_TOP_CUTOFF);
		case TimeType_Pro:FormatEx(query, sizeof(query), sql_getrecentrecords_pro, mode, LR_PLAYER_TOP_CUTOFF);
	}
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenRecentRecords, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenRecentRecords(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int mode = data.ReadCell();
	int timeType = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	// Check if there are any times
	if (SQL_GetRowCount(results[0]) == 0)
	{
		switch (timeType)
		{
			case TimeType_Nub:GOKZ_PrintToChat(client, true, "%t", "No Times Found");
			case TimeType_Pro:GOKZ_PrintToChat(client, true, "%t", "No Times Found (PRO)");
		}
		return;
	}
	
	Menu menu = new Menu(MenuHandler_RecentRecordsSubmenu);
	menu.Pagination = 5;
	
	// Set submenu title
	menu.SetTitle("%T", "Recent Records Submenu - Title", client, 
		gC_TimeTypeNames[timeType], gC_ModeNames[mode]);
	
	// Add submenu items
	char display[256], mapName[64], playerName[33];
	int course;
	float runTime;
	
	while (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, mapName, sizeof(mapName));
		course = SQL_FetchInt(results[0], 1);
		SQL_FetchString(results[0], 3, playerName, sizeof(playerName));
		runTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[0], 4));
		
		if (course == 0)
		{
			FormatEx(display, sizeof(display), "%s - %s (%s)", 
				mapName, playerName, GOKZ_FormatTime(runTime));
		}
		else
		{
			FormatEx(display, sizeof(display), "%s B%d - %s (%s)", 
				mapName, course, playerName, GOKZ_FormatTime(runTime));
		}
		
		menu.AddItem(IntToStringEx(SQL_FetchInt(results[0], 2)), display, ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENUS ]=====

void DisplayRecentRecordsModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_RecentRecordsMode);
	menu.SetTitle("%T", "Recent Records Mode Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayRecentRecordsTimeTypeMenu(int client, int mode)
{
	recentRecordsMode[client] = mode;

	Menu menu = new Menu(MenuHandler_RecentRecordsTimeType);
	menu.SetTitle("%T", "Recent Records Menu - Title", client, gC_ModeNames[recentRecordsMode[client]]);
	RecentRecordsTimeTypeAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void RecentRecordsTimeTypeAddItems(int client, Menu menu)
{
	char display[32];
	for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
	{
		FormatEx(display, sizeof(display), "%T", "Recent Records Menu - Record Type", client, gC_TimeTypeNames[timeType]);
		menu.AddItem("", display, ITEMDRAW_DEFAULT);
	}
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_RecentRecordsMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		DisplayRecentRecordsTimeTypeMenu(param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_RecentRecordsTimeType(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		DB_OpenRecentRecords(param1, recentRecordsMode[param1], param2);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayRecentRecordsModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_RecentRecordsSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	// TODO Menu item info is course's MapCourseID, but is currently not used
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayRecentRecordsTimeTypeMenu(param1, recentRecordsMode[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
} 
