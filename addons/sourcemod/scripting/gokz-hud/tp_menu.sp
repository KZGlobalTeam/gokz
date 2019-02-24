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



// =====[ EVENTS ]=====

void OnPlayerRunCmdPost_TPMenu(int client, int cmdnum)
{
	if (cmdnum % 6 == 3)
	{
		UpdateTPMenu(client);
	}
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
		gB_MenuShowing[param1] = false;
	}
	else if (action == MenuAction_Cancel)
	{
		gB_MenuShowing[param1] = false;
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ PRIVATE ]=====

static void UpdateTPMenu(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.fake || !player.alive || player.tpMenu == TPMenu_Disabled)
	{
		return;
	}
	
	// If there is no menu showing, or if the TP menu is currently showing with timer text
	if (GetClientMenu(client) == MenuSource_None
		 || gB_MenuShowing[player.id] && player.timerText == TimerText_TPMenu && player.alive && player.timerRunning && !player.paused)
	{
		ShowTPMenu(player);
	}
}

static void ShowTPMenu(KZPlayer player)
{
	Menu menu = new Menu(MenuHandler_TPMenu);
	menu.OptionFlags = MENUFLAG_NO_SOUND;
	menu.ExitButton = false;
	menu.Pagination = MENU_NO_PAGINATION;
	TPMenuSetTitle(player, menu);
	TPMenuAddItems(player, menu);
	menu.Display(player.id, MENU_TIME_FOREVER);
	gB_MenuShowing[player.id] = true;
	
	static int test1 = 0;
	PrintToServer("menu %d", test1++);
}

static void TPMenuSetTitle(KZPlayer player, Menu menu)
{
	if (player.timerRunning && player.timerText == TimerText_TPMenu)
	{
		menu.SetTitle(FormatTimerTextForMenu(player));
	}
}

static void TPMenuAddItems(KZPlayer player, Menu menu)
{
	switch (player.tpMenu)
	{
		case TPMenu_Simple:
		{
			TPMenuAddItemCheckpoint(player, menu);
			TPMenuAddItemTeleport(player, menu);
			TPMenuAddItemPause(player, menu);
			TPMenuAddItemStart(player, menu);
		}
		case TPMenu_Advanced:
		{
			TPMenuAddItemCheckpoint(player, menu);
			TPMenuAddItemTeleport(player, menu);
			TPMenuAddItemPrevCheckpoint(player, menu);
			TPMenuAddItemNextCheckpoint(player, menu);
			TPMenuAddItemUndo(player, menu);
			TPMenuAddItemPause(player, menu);
			TPMenuAddItemStart(player, menu);
		}
	}
}

static void TPMenuAddItemCheckpoint(KZPlayer player, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Checkpoint", player.id);
	menu.AddItem(ITEM_INFO_CHECKPOINT, display, ITEMDRAW_DEFAULT);
}

static void TPMenuAddItemTeleport(KZPlayer player, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Teleport", player.id);
	if (player.canTeleportToCheckpoint)
	{
		menu.AddItem(ITEM_INFO_TELEPORT, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_TELEPORT, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemPrevCheckpoint(KZPlayer player, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Prev CP", player.id);
	if (player.canPrevCheckpoint)
	{
		menu.AddItem(ITEM_INFO_PREV, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_PREV, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemNextCheckpoint(KZPlayer player, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Next CP", player.id);
	if (player.canNextCheckpoint)
	{
		menu.AddItem(ITEM_INFO_NEXT, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_NEXT, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemUndo(KZPlayer player, Menu menu)
{
	char display[16];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Undo TP", player.id);
	if (player.canUndoTeleport)
	{
		menu.AddItem(ITEM_INFO_UNDO, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem(ITEM_INFO_UNDO, display, ITEMDRAW_DISABLED);
	}
}

static void TPMenuAddItemPause(KZPlayer player, Menu menu)
{
	char display[16];
	if (player.paused)
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Resume", player.id);
		menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Pause", player.id);
		menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
	}
}

static void TPMenuAddItemStart(KZPlayer player, Menu menu)
{
	char display[16];
	if (player.hasStartPosition)
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Restart", player.id);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Respawn", player.id);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
} 