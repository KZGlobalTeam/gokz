/*
	Map Top
	
	Opens a menu with the top global times for the map course and given mode.
*/



static char mapTopMap[MAXPLAYERS + 1][64];
static int mapTopCourse[MAXPLAYERS + 1];
static int mapTopMode[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

void DisplayMapTopMenu(int client, const char[] map, int course, int mode)
{
	FormatEx(mapTopMap[client], sizeof(mapTopMap[]), map);
	mapTopMode[client] = mode;
	mapTopCourse[client] = course;
	
	Menu menu = new Menu(MenuHandler_MapTopMenu);
	if (course == 0)
	{
		menu.SetTitle("%T", "Global Map Top Menu - Title", client, map, gC_ModeNames[mode]);
	}
	else
	{
		menu.SetTitle("%T", "Global Map Top Menu - Title (Bonus)", client, map, course, gC_ModeNames[mode]);
	}
	MapTopMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayMapTopSubmenu(int client, const char[] top, int timeType)
{
	Menu menu = new Menu(MenuHandler_MapTopSubmenu);
	if (mapTopCourse[client] == 0)
	{
		menu.SetTitle("%T", "Global Map Top Submenu - Title", client, 
			gC_TimeTypeNames[timeType], mapTopMap[client], gC_ModeNames[mapTopMode[client]]);
	}
	else
	{
		menu.SetTitle("%T", "Global Map Top Submenu - Title (Bonus)", client, 
			gC_TimeTypeNames[timeType], mapTopMap[client], mapTopCourse[client], gC_ModeNames[mapTopMode[client]]);
	}
	
	if (MapTopSubmenuAddItems(menu, top) == 0)
	{  // If no records found
		if (timeType == TimeType_Pro)
		{
			GOKZ_PrintToChat(client, true, "%t", "No Global Times Found (PRO)");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "No Global Times Found");
		}
		DisplayMapTopMenu(client, mapTopMap[client], mapTopCourse[client], mapTopMode[client]);
	}
	else
	{
		menu.Pagination = 5;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}



// =========================  HANDLERS  ========================= //

public int MenuHandler_MapTopMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int timeType = StringToInt(info);
		GetMapTop(param1, mapTopMap[param1], mapTopMode[param1], timeType);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_MapTopSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

static void MapTopMenuAddItems(int client, Menu menu)
{
	for (int i = 0; i < TIMETYPE_COUNT; i++)
	{
		char display[128];
		FormatEx(display, sizeof(display), "%T", "Map Top Menu - Top 20", client, gC_TimeTypeNames[i]);
		menu.AddItem(IntToStringEx(i), display);
	}
}

static void GetMapTop(int client, const char[] map, int mode, int timeType)
{
	DataPack dp = new DataPack();
	dp.WriteCell(GetClientUserId(client));
	dp.WriteCell(timeType);
	
	GlobalAPI_GetRecordTopEx(map, 0, GetGlobalMode(mode), timeType == TimeType_Pro, 128, 20, GetMapTopCallback, dp);
}

public int GetMapTopCallback(bool failure, const char[] top, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int timeType = dp.ReadCell();
	delete dp;
	
	if (failure)
	{
		LogError("Failed to retrieve map top from global API.");
		return;
	}
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	DisplayMapTopSubmenu(client, top, timeType);
}

// Returns number of record times added to the menu
static int MapTopSubmenuAddItems(Menu menu, const char[] top)
{
	APIRecordList records = new APIRecordList(top);
	
	int recordCount = records.Count();
	
	if (recordCount <= 0)
	{
		return 0;
	}
	
	char buffer[2048];
	char playerName[MAX_NAME_LENGTH];
	char display[128];
	
	for (int i = 0; i < recordCount; i++)
	{
		records.GetByIndex(i, buffer, sizeof(buffer));
		APIRecord record = new APIRecord(buffer);
		
		record.PlayerName(playerName, sizeof(playerName));
		
		FormatEx(display, sizeof(display), "#%-2d   %11s   %s", 
			i + 1, GOKZ_FormatTime(record.Time()), playerName);
		
		menu.AddItem("", display, ITEMDRAW_DISABLED);
	}
	
	return recordCount;
} 