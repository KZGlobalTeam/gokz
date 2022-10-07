/*
	Opens a menu with top record holders of a time type and mode.
*/



static int playerTopMode[MAXPLAYERS + 1];



void DB_OpenPlayerTop(int client, int timeType, int mode)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(timeType);
	data.WriteCell(mode);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Get top players
	switch (timeType)
	{
		case TimeType_Nub:
		{
			FormatEx(query, sizeof(query), sql_gettopplayers, mode, LR_PLAYER_TOP_CUTOFF);
			txn.AddQuery(query);
		}
		case TimeType_Pro:
		{
			FormatEx(query, sizeof(query), sql_gettopplayerspro, mode, LR_PLAYER_TOP_CUTOFF);
			txn.AddQuery(query);
		}
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenPlayerTop, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenPlayerTop(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int timeType = data.ReadCell();
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		switch (timeType)
		{
			case TimeType_Nub:GOKZ_PrintToChat(client, true, "%t", "Player Top - No Times");
			case TimeType_Pro:GOKZ_PrintToChat(client, true, "%t", "Player Top - No Times (PRO)");
		}
		DisplayPlayerTopMenu(client, playerTopMode[client]);
		return;
	}
	
	Menu menu = new Menu(MenuHandler_PlayerTopSubmenu);
	menu.Pagination = 5;
	
	// Set submenu title
	menu.SetTitle("%T", "Player Top Submenu - Title", client, 
		LR_PLAYER_TOP_CUTOFF, gC_TimeTypeNames[timeType], gC_ModeNames[mode]);
	
	// Add submenu items
	char display[256];
	int rank = 0;
	while (SQL_FetchRow(results[0]))
	{
		rank++;
		char playerString[33];
		SQL_FetchString(results[0], 1, playerString, sizeof(playerString));
		FormatEx(display, sizeof(display), "#%-2d   %s (%d)", rank, playerString, SQL_FetchInt(results[0], 2));
		menu.AddItem(IntToStringEx(SQL_FetchInt(results[0], 0)), display, ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENUS ]=====

void DisplayPlayerTopModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PlayerTopMode);
	menu.SetTitle("%T", "Player Top Mode Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayPlayerTopMenu(int client, int mode)
{
	playerTopMode[client] = mode;
	
	Menu menu = new Menu(MenuHandler_PlayerTop);
	menu.SetTitle("%T", "Player Top Menu - Title", client, gC_ModeNames[mode]);
	PlayerTopMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void PlayerTopMenuAddItems(int client, Menu menu)
{
	char display[32];
	for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
	{
		FormatEx(display, sizeof(display), "%T", "Player Top Menu - Top", client, 
			LR_PLAYER_TOP_CUTOFF, gC_TimeTypeNames[timeType]);
		menu.AddItem("", display, ITEMDRAW_DEFAULT);
	}
}



// =====[ MENU HANLDERS ]=====

public int MenuHandler_PlayerTopMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		DisplayPlayerTopMenu(param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_PlayerTop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		DB_OpenPlayerTop(param1, param2, playerTopMode[param1]);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayPlayerTopModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_PlayerTopSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	// Menu item info is player's SteamID32, but is currently not used
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayPlayerTopMenu(param1, playerTopMode[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
} 