/*
	Teleport Menu
	
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



// =========================  PUBLIC  ========================= //

// Update the TP menu i.e. item text, item disabled/enabled
void UpdateTPMenu(int client)
{
	// Only cancel the menu if we know it's the TP menu
	if (TPMenuIsShowing[client])
	{
		CancelClientMenu(client);
	}
}



// =========================  HANDLER  ========================= //

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


// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_TPMenu(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	// Checks option and that no other menu is open instead of rudely interrupting it
	if (GetOption(client, Option_ShowingTPMenu) == ShowingTPMenu_Enabled
		 && GetClientMenu(client) == MenuSource_None)
	{
		DisplayTPMenu(client);
	}
}

void OnOptionChanged_TPMenu(int client, Option option)
{
	if (option == Option_ShowingTPMenu)
	{
		UpdateTPMenu(client);
	}
}



// =========================  PRIVATE  ========================= //

static void DisplayTPMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TPMenu);
	menu.OptionFlags = MENUFLAG_NO_SOUND;
	menu.ExitButton = false;
	menu.Pagination = MENU_NO_PAGINATION;
	TPMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
	TPMenuIsShowing[client] = true;
}

static void TPMenuAddItems(int client, Menu menu)
{
	TPMenuAddItemCheckpoint(client, menu);
	TPMenuAddItemTeleport(client, menu);
	TPMenuAddIdisplayrevCheckpoint(client, menu);
	TPMenuAddItemNextCheckpoint(client, menu);
	TPMenuAddItemUndo(client, menu);
	TPMenuAddIdisplayause(client, menu);
	TPMenuAddItemStart(client, menu);
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
	if (CanTeleportToCheckpoint(client))
	{
		menu.AddItem(ITEM_INFO_TELEPORT, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_TELEPORT, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddIdisplayrevCheckpoint(int client, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Prev CP", client);
	if (CanPrevCheckpoint(client))
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
	if (CanNextCheckpoint(client))
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
	if (CanUndoTeleport(client))
	{
		menu.AddItem(ITEM_INFO_UNDO, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_UNDO, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddIdisplayause(int client, Menu menu)
{
	char display[16];
	if (GetPaused(client))
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

static void TPMenuAddItemStart(int client, Menu menu) {
	char display[16];
	if (GetHasStartedTimerThisMap(client) || GetHasCustomStartPosition(client))
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