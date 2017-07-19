/*
	Database - Open Map Top 20
	
	Opens the menu with the top 20 times for the map course and given mode.
	See also:
		menus/maptop.sp
*/



void DB_OpenMapTop20(int client, int mapID, int course, int mode, int timeType)
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
	
	// Get top 20 times for each time type
	switch (timeType)
	{
		case TimeType_Nub:FormatEx(query, sizeof(query), sql_getmaptop, mapID, course, mode, 20);
		case TimeType_Pro:FormatEx(query, sizeof(query), sql_getmaptoppro, mapID, course, mode, 20);
	}
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenMapTop20, DB_TxnFailure_Generic, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenMapTop20(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int course = data.ReadCell();
	int mode = data.ReadCell();
	int timeType = data.ReadCell();
	data.Close();
	
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
		MapTopMenuDisplay(client);
		return;
	}
	
	RemoveAllMenuItems(gH_MapTopSubMenu[client]);
	
	// Set submenu title
	if (course == 0)
	{
		SetMenuTitle(gH_MapTopSubMenu[client], "%T", "Map Top Submenu - Title", client, 
			gC_TimeTypeNames[timeType], mapName, gC_ModeNames[mode]);
	}
	else
	{
		SetMenuTitle(gH_MapTopSubMenu[client], "%T", "Map Top Submenu - Title (Bonus)", client, 
			gC_TimeTypeNames[timeType], mapName, course, gC_ModeNames[mode]);
	}
	
	// Add submenu items
	char newMenuItem[256], playerName[33];
	float runTime;
	int teleports, rank = 0;
	
	while (SQL_FetchRow(results[2]))
	{
		rank++;
		SQL_FetchString(results[2], 0, playerName, sizeof(playerName));
		runTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[2], 1));
		switch (timeType)
		{
			case TimeType_Nub:
			{
				teleports = SQL_FetchInt(results[2], 2);
				FormatEx(newMenuItem, sizeof(newMenuItem), "#%-2d   %11s  %d TP      %s", 
					rank, GOKZ_FormatTime(runTime), teleports, playerName);
			}
			case TimeType_Pro:
			{
				FormatEx(newMenuItem, sizeof(newMenuItem), "#%-2d   %11s   %s", 
					rank, GOKZ_FormatTime(runTime), playerName);
			}
		}
		AddMenuItem(gH_MapTopSubMenu[client], "", newMenuItem, ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(gH_MapTopSubMenu[client], client, MENU_TIME_FOREVER);
} 