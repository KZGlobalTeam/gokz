/*
	Lets players easily use teleport functionality.
	
	This menu is displayed whenever the player is alive and there is
	currently no other menu displaying.
*/



#define ITEM_INFO_CHECKPOINT "cp"
#define ITEM_INFO_TELEPORT "tp"
#define ITEM_INFO_PREV "prev"
#define ITEM_INFO_NEXT "next"
#define ITEM_INFO_UNDO "undo"
#define ITEM_INFO_PAUSE "pause"
#define ITEM_INFO_START "start"

static bool TPMenuIsShowing[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

void OnPlayerSpawn_TPMenu(client)
{
	UpdateTPMenu(client);
}

void OnPlayerRunCmdPost_TPMenu(int client, int cmdnum)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	// Checks option and that no other menu is open instead of rudely interrupting it
	if (GetClientMenu(client) == MenuSource_None)
	{
		DisplayTPMenu(client);
	}
	else if (cmdnum % 6 == 0 && GOKZ_GetTimerRunning(client)
		 && GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
	{
		UpdateTPMenu(client);
	}
}

void OnOptionChanged_TPMenu(int client, HUDOption option)
{
	if (option == HUDOption_TPMenu)
	{
		UpdateTPMenu(client);
	}
}

void OnTimerStart_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnTimerEnd_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnTimerStopped_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnPause_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnResume_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnMakeCheckpoint_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnCountedTeleport_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnJoinTeam_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnCustomStartPositionSet_TPMenu(int client)
{
	UpdateTPMenu(client);
}

void OnCustomStartPositionCleared_TPMenu(int client)
{
	UpdateTPMenu(client);
}

public int MenuHandler_TPMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, ITEM_INFO_CHECKPOINT, false))
		{
			GOKZ_MakeCheckpoint(param1);
		}
		else if (StrEqual(info, ITEM_INFO_TELEPORT, false))
		{
			GOKZ_TeleportToCheckpoint(param1);
		}
		else if (StrEqual(info, ITEM_INFO_PREV, false))
		{
			GOKZ_PrevCheckpoint(param1);
		}
		else if (StrEqual(info, ITEM_INFO_NEXT, false))
		{
			GOKZ_NextCheckpoint(param1);
		}
		else if (StrEqual(info, ITEM_INFO_UNDO, false))
		{
			GOKZ_UndoTeleport(param1);
		}
		else if (StrEqual(info, ITEM_INFO_PAUSE, false))
		{
			GOKZ_TogglePause(param1);
		}
		else if (StrEqual(info, ITEM_INFO_START, false))
		{
			GOKZ_TeleportToStart(param1);
		}
		
		// Menu closes when player selects something, so...
		TPMenuIsShowing[param1] = false;
	}
	else if (action == MenuAction_Cancel)
	{
		TPMenuIsShowing[param1] = false;
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int PanelHandler_TPMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		TPMenuIsShowing[param1] = false;
	}
}



// =====[ PRIVATE ]=====

// Update the TP menu i.e. item text, item disabled/enabled
static void UpdateTPMenu(int client)
{
	// Only cancel the menu if we know it's the TP menu
	if (TPMenuIsShowing[client])
	{
		CancelClientMenu(client);
	}
}

static void DisplayTPMenu(int client)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_TPMenu) != TPMenu_Disabled)
	{
		Menu menu = new Menu(MenuHandler_TPMenu);
		menu.OptionFlags = MENUFLAG_NO_SOUND;
		menu.ExitButton = false;
		menu.Pagination = MENU_NO_PAGINATION;
		TPMenuSetTitle(client, menu);
		TPMenuAddItems(client, menu);
		menu.Display(client, MENU_TIME_FOREVER);
		TPMenuIsShowing[client] = true;
	}
	else if (GOKZ_GetTimerRunning(client) && 
		GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
	{
		// Use a Panel if want to only show timer text as it doesn't seem
		// to be possible to display a Menu with no items.
		Panel panel = new Panel(null);
		panel.SetTitle(GetTimerTextMenuTitleString(client));
		panel.Send(client, PanelHandler_TPMenu, MENU_TIME_FOREVER);
		delete panel;
		TPMenuIsShowing[client] = true;
	}
}

static void TPMenuSetTitle(int client, Menu menu)
{
	if (GOKZ_GetTimerRunning(client) && 
		GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
	{
		menu.SetTitle(GetTimerTextMenuTitleString(client));
	}
}

static char[] GetTimerTextMenuTitleString(int client)
{
	char timerTextString[32];
	FormatEx(timerTextString, sizeof(timerTextString), 
		"%s %s", 
		gC_TimeTypeNames[GOKZ_GetTimeType(client)], 
		GOKZ_FormatTime(GOKZ_GetTime(client)));
	return timerTextString;
}

static void TPMenuAddItems(int client, Menu menu)
{
	switch (GOKZ_HUD_GetOption(client, HUDOption_TPMenu))
	{
		case TPMenu_Simple:
		{
			TPMenuAddItemCheckpoint(client, menu);
			TPMenuAddItemTeleport(client, menu);
			TPMenuAddItemPause(client, menu);
			TPMenuAddItemStart(client, menu);
		}
		case TPMenu_Advanced:
		{
			TPMenuAddItemCheckpoint(client, menu);
			TPMenuAddItemTeleport(client, menu);
			TPMenuAddItemPrevCheckpoint(client, menu);
			TPMenuAddItemNextCheckpoint(client, menu);
			TPMenuAddItemUndo(client, menu);
			TPMenuAddItemPause(client, menu);
			TPMenuAddItemStart(client, menu);
		}
	}
}

static void TPMenuAddItemCheckpoint(int client, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Checkpoint", client);
	menu.AddItem(ITEM_INFO_CHECKPOINT, display, ITEMDRAW_DEFAULT);
}

static void TPMenuAddItemTeleport(int client, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Teleport", client);
	if (GOKZ_GetCanTeleportToCheckpoint(client))
	{
		menu.AddItem(ITEM_INFO_TELEPORT, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_TELEPORT, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemPrevCheckpoint(int client, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Prev CP", client);
	if (GOKZ_GetCanPrevCheckpoint(client))
	{
		menu.AddItem(ITEM_INFO_PREV, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_PREV, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemNextCheckpoint(int client, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Next CP", client);
	if (GOKZ_GetCanNextCheckpoint(client))
	{
		menu.AddItem(ITEM_INFO_NEXT, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_NEXT, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemUndo(int client, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Undo TP", client);
	if (GOKZ_GetCanUndoTeleport(client))
	{
		menu.AddItem(ITEM_INFO_UNDO, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_UNDO, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemPause(int client, Menu menu)
{
	char display[16];
	if (GOKZ_GetPaused(client))
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Resume", client);
		menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Pause", client);
		menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
	}
}

static void TPMenuAddItemStart(int client, Menu menu)
{
	char display[16];
	if (GOKZ_GetHasStartPosition(client))
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Restart", client);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Respawn", client);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
} 