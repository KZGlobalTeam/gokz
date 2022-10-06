/*
	Lets player select a replay bot to play back.
*/



static int selectedReplayMode[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

void DisplayReplayModeMenu(int client)
{
	if (g_ReplayInfoCache.Length == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Replays Found (Map)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	Menu menu = new Menu(MenuHandler_ReplayMode);
	menu.SetTitle("%T", "Replay Menu (Mode) - Title", client, gC_CurrentMap);
	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ EVENTS ]=====

public int MenuHandler_ReplayMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		selectedReplayMode[param1] = param2;
		DisplayReplayMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_Replay(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(param2, info, sizeof(info));
		int replayIndex = StringToInt(info);
		int replayInfo[RP_CACHE_BLOCKSIZE];
		g_ReplayInfoCache.GetArray(replayIndex, replayInfo);

		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path),
			"%s/%s/%d_%s_%s_%s.%s",
			RP_DIRECTORY_RUNS, gC_CurrentMap, replayInfo[0], gC_ModeNamesShort[replayInfo[1]], gC_StyleNamesShort[replayInfo[2]], gC_TimeTypeNames[replayInfo[3]], RP_FILE_EXTENSION);
		if (!FileExists(path))
		{
			BuildPath(Path_SM, path, sizeof(path),
				"%s/%d_%s_%s_%s.%s",
				RP_DIRECTORY, gC_CurrentMap, replayInfo[0], gC_ModeNamesShort[replayInfo[1]], gC_StyleNamesShort[replayInfo[2]], gC_TimeTypeNames[replayInfo[3]], RP_FILE_EXTENSION);
			if (!FileExists(path))
			{
				LogError("Failed to load file: \"%s\".", path);
				GOKZ_PrintToChat(param1, true, "%t", "Replay Menu - No File");
				return 0;
			}
		}
		
		LoadReplayBot(param1, path);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayReplayModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}



// =====[ PRIVATE ]=====

static void DisplayReplayMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Replay);
	menu.SetTitle("%T", "Replay Menu - Title", client, gC_CurrentMap, gC_ModeNames[selectedReplayMode[client]]);
	if (ReplayMenuAddItems(client, menu) > 0)
	{
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "No Replays Found (Mode)", gC_ModeNames[selectedReplayMode[client]]);
		GOKZ_PlayErrorSound(client);
		DisplayReplayModeMenu(client);
	}
}

// Returns the number of replay menu items added
static int ReplayMenuAddItems(int client, Menu menu)
{
	int replaysAdded = 0;
	int replayCount = g_ReplayInfoCache.Length;
	int replayInfo[RP_CACHE_BLOCKSIZE];
	char temp[32], indexString[4];
	
	menu.RemoveAllItems();
	
	for (int i = 0; i < replayCount; i++)
	{
		IntToString(i, indexString, sizeof(indexString));
		g_ReplayInfoCache.GetArray(i, replayInfo);
		if (replayInfo[1] != selectedReplayMode[client]) // Wrong mode!
		{
			continue;
		}
		
		if (replayInfo[0] == 0)
		{
			FormatEx(temp, sizeof(temp), "Main %s", gC_TimeTypeNames[replayInfo[3]]);
		}
		else
		{
			FormatEx(temp, sizeof(temp), "Bonus %d %s", replayInfo[0], gC_TimeTypeNames[replayInfo[3]]);
		}
		menu.AddItem(indexString, temp, ITEMDRAW_DEFAULT);
		
		replaysAdded++;
	}
	
	return replaysAdded;
} 