/*
	Menu with the top global times for a map course and mode.
*/

static bool cameFromLocalRanks[MAXPLAYERS + 1];
static char mapTopMap[MAXPLAYERS + 1][64];
static int mapTopCourse[MAXPLAYERS + 1];
static int mapTopMode[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

void DisplayMapTopModeMenu(int client, const char[] map, int course)
{
	FormatEx(mapTopMap[client], sizeof(mapTopMap[]), map);
	mapTopCourse[client] = course;
	
	Menu menu = new Menu(MenuHandler_MapTopModeMenu);
	MapTopModeMenuSetTitle(client, menu);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayMapTopMenu(int client, const char[] map, int course, int mode)
{
	FormatEx(mapTopMap[client], sizeof(mapTopMap[]), map);
	mapTopCourse[client] = course;
	mapTopMode[client] = mode;
	
	Menu menu = new Menu(MenuHandler_MapTopMenu);
	MapTopMenuSetTitle(client, menu);
	MapTopMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayMapTopSubmenu(int client, const char[] map, int course, int mode, int timeType, bool fromLocalRanks = false)
{
	char modeStr[32];
	
	cameFromLocalRanks[client] = fromLocalRanks;
	
	DataPack dp = new DataPack();
	dp.WriteCell(GetClientUserId(client));
	dp.WriteCell(timeType);
	
	FormatEx(mapTopMap[client], sizeof(mapTopMap[]), map);
	mapTopCourse[client] = course;
	mapTopMode[client] = mode;
	GOKZ_GL_GetModeString(mode, modeStr, sizeof(modeStr));
	
	// TODO Hard coded 128 tick
	// TODO Hard coded cap at top 20
	// TODO Not true NUB yet
	GlobalAPI_GetRecordsTop(DisplayMapTopSubmenuCallback, dp, _, _, _, map, 128, course, modeStr,
							timeType == TimeType_Nub ? DEFAULT_BOOL : false, _, 0, 20);
}



// =====[ EVENTS ]=====

public int MenuHandler_MapTopModeMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = mode
		DisplayMapTopMenu(param1, mapTopMap[param1], mapTopCourse[param1], param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_MapTopMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int timeType = StringToInt(info);
		DisplayMapTopSubmenu(param1, mapTopMap[param1], mapTopCourse[param1], mapTopMode[param1], timeType);
	}
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayMapTopModeMenu(param1, mapTopMap[param1], mapTopCourse[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_MapTopSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		if (cameFromLocalRanks[param1])
		{
			GOKZ_LR_ReopenMapTopMenu(param1);
		}
		else
		{
			DisplayMapTopMenu(param1, mapTopMap[param1], mapTopCourse[param1], mapTopMode[param1]);
		}
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}



// =====[ PRIVATE ]=====

static void MapTopModeMenuSetTitle(int client, Menu menu)
{
	if (mapTopCourse[client] == 0)
	{
		menu.SetTitle("%T", "Global Map Top Mode Menu - Title", client, mapTopMap[client]);
	}
	else
	{
		menu.SetTitle("%T", "Global Map Top Mode Menu - Title (Bonus)", client, mapTopMap[client], mapTopCourse[client]);
	}
}

static void MapTopMenuSetTitle(int client, Menu menu)
{
	if (mapTopCourse[client] == 0)
	{
		menu.SetTitle("%T", "Global Map Top Menu - Title", client, mapTopMap[client], gC_ModeNames[mapTopMode[client]]);
	}
	else
	{
		menu.SetTitle("%T", "Global Map Top Menu - Title (Bonus)", client, mapTopMap[client], mapTopCourse[client], gC_ModeNames[mapTopMode[client]]);
	}
}

static void MapTopMenuAddItems(int client, Menu menu)
{
	char display[32];
	for (int i = 0; i < TIMETYPE_COUNT; i++)
	{
		FormatEx(display, sizeof(display), "%T", "Global Map Top Menu - Top", client, gC_TimeTypeNames[i]);
		menu.AddItem(IntToStringEx(i), display);
	}
}

public int DisplayMapTopSubmenuCallback(JSON_Object top, GlobalAPIRequestData request, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int timeType = dp.ReadCell();
	delete dp;
	
	if (request.Failure)
	{
		LogError("Failed to get top records with Global API.");
		return 0;
	}
	
	if (!top.IsArray)
	{
		LogError("GlobalAPI returned a malformed response while looking up the top records.");
		return 0;
	}
	
	if (!IsValidClient(client))
	{
		return 0;
	}
	
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
	
	if (MapTopSubmenuAddItems(menu, top, timeType) == 0)
	{  // If no records found
		if (timeType == TimeType_Pro)
		{
			GOKZ_PrintToChat(client, true, "%t", "No Global Times Found (PRO)");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "No Global Times Found");
		}
		
		if (cameFromLocalRanks[client])
		{
			GOKZ_LR_ReopenMapTopMenu(client);
		}
		else
		{
			DisplayMapTopMenu(client, mapTopMap[client], mapTopCourse[client], mapTopMode[client]);
		}
	}
	else
	{
		menu.Pagination = 5;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return 0;
}

// Returns number of record times added to the menu
static int MapTopSubmenuAddItems(Menu menu, JSON_Object records, int timeType)
{
	char playerName[MAX_NAME_LENGTH];
	char display[128];
	
	for (int i = 0; i < records.Length; i++)
	{
		APIRecord record = view_as<APIRecord>(records.GetObjectIndexed(i));
		
		record.GetPlayerName(playerName, sizeof(playerName));
		
		switch (timeType)
		{
			case TimeType_Nub:
			{
				FormatEx(display, sizeof(display), "#%-2d   %11s  %3d TP	  %s", 
					i + 1, GOKZ_FormatTime(record.Time), record.Teleports, playerName);
			}
			case TimeType_Pro:
			{
				FormatEx(display, sizeof(display), "#%-2d   %11s   %s", 
					i + 1, GOKZ_FormatTime(record.Time), playerName);
			}
		}
		
		menu.AddItem("", display, ITEMDRAW_DISABLED);
	}
	
	return records.Length;
} 