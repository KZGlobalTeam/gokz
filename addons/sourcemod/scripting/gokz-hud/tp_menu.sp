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

void OnPlayerRunCmdPost_TPMenu(int client, int cmdnum, HUDInfo info)
{
	if (cmdnum % 6 == 3)
	{
		UpdateTPMenu(client, info);
	}
}

public int PanelHandler_Menu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		gB_MenuShowing[param1] = false;
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

static void UpdateTPMenu(int client, HUDInfo info)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake)
	{
		return;
	}
	
	if (player.Alive)
	{
		if (player.TPMenu != TPMenu_Disabled)
		{
			if (GetClientMenu(client) == MenuSource_None
				|| gB_MenuShowing[player.ID] && GetClientAvgLoss(player.ID, NetFlow_Both) > EPSILON
				|| gB_MenuShowing[player.ID] && player.TimerRunning && !player.Paused && player.TimerText == TimerText_TPMenu)
			{
				ShowTPMenu(player, info);
			}
		}
		else
		{
			// There is no need to update this very often as there's no menu selection to be done here.
			if (GetClientMenu(client) == MenuSource_None
				|| gB_MenuShowing[player.ID] && player.TimerRunning && !player.Paused && player.TimerText == TimerText_TPMenu)
			{
				ShowPanel(player, info);
			}
		}
	}
	else if (player.ObserverTarget != -1) // If the player is spectating someone else
	{
		// Check if the replay plugin wants to display the replay control menu.
		if (!(IsFakeClient(player.ObserverTarget) && gB_GOKZReplays && GOKZ_RP_UpdateReplayControlMenu(client)))
		{
			ShowPanel(player, info);
		}
	}
}

static void ShowPanel(KZPlayer player, HUDInfo info)
{
	char panelTitle[256];
	// Spectator List
	if (player.SpecList >= SpecList_Number && player.SpecListPosition == SpecListPosition_TPMenu)
	{
		Format(panelTitle, sizeof(panelTitle), "%s", FormatSpectatorTextForMenu(player, info));
	}
	// Timer panel
	if (player.TimerText == TimerText_TPMenu && info.TimerRunning)
	{
		if (panelTitle[0] != '\0')
		{
			Format(panelTitle, sizeof(panelTitle), "%s \n%s", panelTitle, FormatTimerTextForMenu(player, info));
		}
		else
		{
			Format(panelTitle, sizeof(panelTitle), "%s", FormatTimerTextForMenu(player, info));
		}
		if (info.TimeType == TimeType_Nub && info.CurrentTeleport != 0)
		{
			Format(panelTitle, sizeof(panelTitle), "%s\n%t", panelTitle, "TP Menu - Spectator Teleports", info.CurrentTeleport);
		}
	}

	if (panelTitle[0] != '\0' && GetClientMenu(player.ID) == MenuSource_None || gB_MenuShowing[player.ID])
	{
		Panel panel = new Panel(null);
		panel.SetTitle(panelTitle);
		panel.Send(player.ID, PanelHandler_Menu, MENU_TIME_FOREVER);
		
		delete panel;
		gB_MenuShowing[player.ID] = true;
	}
}

static void ShowTPMenu(KZPlayer player, HUDInfo info)
{
	Menu menu = new Menu(MenuHandler_TPMenu);
	menu.OptionFlags = MENUFLAG_NO_SOUND;
	menu.ExitButton = false;
	menu.Pagination = MENU_NO_PAGINATION;
	TPMenuSetTitle(player, menu, info);
	TPMenuAddItems(player, menu);
	menu.Display(player.ID, MENU_TIME_FOREVER);
	gB_MenuShowing[player.ID] = true;
}

static void TPMenuSetTitle(KZPlayer player, Menu menu, HUDInfo info)
{
	char title[256];
	if (player.SpecList >= SpecList_Number && player.SpecListPosition == SpecListPosition_TPMenu)
	{
		Format(title, sizeof(title), "%s", FormatSpectatorTextForMenu(player, info));
	}
	if (player.TimerRunning && player.TimerText == TimerText_TPMenu)
	{
		if (title[0] != '\0')
		{
			Format(title, sizeof(title), "%s \n%s", title, FormatTimerTextForMenu(player, info));
		}
		else
		{
			Format(title, sizeof(title), "%s", FormatTimerTextForMenu(player, info));
		}
	}
	if (title[0] != '\0')
	{
		menu.SetTitle(title);
	}
}

static void TPMenuAddItems(KZPlayer player, Menu menu)
{
	switch (player.TPMenu)
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
	char display[24];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Checkpoint", player.ID);
	if (player.TimerRunning)
	{
		Format(display, sizeof(display), "%s #%d", display, player.CheckpointCount);
	}
	
	menu.AddItem(ITEM_INFO_CHECKPOINT, display, ITEMDRAW_DEFAULT);
}

static void TPMenuAddItemTeleport(KZPlayer player, Menu menu)
{
	char display[24];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Teleport", player.ID);
	if (player.TimerRunning)
	{
		Format(display, sizeof(display), "%s #%d", display, player.TeleportCount);
	}
	
	if (player.CanTeleportToCheckpoint)
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
	char display[24];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Prev CP", player.ID);
	if (player.CanPrevCheckpoint)
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
	char display[24];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Next CP", player.ID);
	if (player.CanNextCheckpoint)
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
	char display[24];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Undo TP", player.ID);
	if (player.CanUndoTeleport)
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
	char display[24];
	if (player.Paused)
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Resume", player.ID);
		menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Pause", player.ID);
		menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
	}
}

static void TPMenuAddItemStart(KZPlayer player, Menu menu)
{
	char display[24];
	if (player.StartPositionType == StartPositionType_Spawn)
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Respawn", player.ID);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
	else if (player.TimerRunning)
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Restart", player.ID);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "TP Menu - Start", player.ID);
		menu.AddItem(ITEM_INFO_START, display, ITEMDRAW_DEFAULT);
	}
} 