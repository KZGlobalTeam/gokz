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

static bool oldCanMakeCP[MAXPLAYERS + 1];
static bool oldCanTP[MAXPLAYERS + 1];
static bool oldCanPrevCP[MAXPLAYERS + 1];
static bool oldCanNextCP[MAXPLAYERS + 1];
static bool oldCanUndoTP[MAXPLAYERS + 1];
static bool oldCanPause[MAXPLAYERS + 1];
static bool oldCanResume[MAXPLAYERS + 1];
static bool forceRefresh[MAXPLAYERS + 1];

// =====[ EVENTS ]=====

void OnPlayerRunCmdPost_TPMenu(int client, int cmdnum, HUDInfo info)
{
	int updateSpeed = gB_FastUpdateRate[client] ? 3 : 6;
	if (cmdnum % updateSpeed == 2)
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
	return 0;
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
	return 0;
}

// =====[ PUBLIC ]=====
void SetForceUpdateTPMenu(int client)
{
	forceRefresh[client] = true;
}

// =====[ PRIVATE ]=====

static void UpdateTPMenu(int client, HUDInfo info)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake)
	{
		return;
	}
	
	bool force = forceRefresh[client]
		|| player.CanMakeCheckpoint != oldCanMakeCP[client]
		|| player.CanTeleportToCheckpoint != oldCanTP[client]
		|| player.CanPrevCheckpoint != oldCanPrevCP[client]
		|| player.CanNextCheckpoint != oldCanNextCP[client]
		|| player.CanUndoTeleport != oldCanUndoTP[client]
		|| player.CanPause != oldCanPause[client]
		|| player.CanResume != oldCanResume[client];

	
	if (player.Alive)
	{
		if (player.TPMenu != TPMenu_Disabled)
		{
			if (GetClientMenu(client) == MenuSource_None
				|| gB_MenuShowing[player.ID] && GetClientAvgLoss(player.ID, NetFlow_Both) > EPSILON
				|| gB_MenuShowing[player.ID] && player.TimerRunning && !player.Paused && player.TimerText == TimerText_TPMenu
				|| gB_MenuShowing[player.ID] && force)
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
	
	oldCanMakeCP[client] = player.CanMakeCheckpoint;
	oldCanTP[client] = player.CanTeleportToCheckpoint;
	oldCanPrevCP[client] = player.CanPrevCheckpoint;
	oldCanNextCP[client] = player.CanNextCheckpoint;
	oldCanUndoTP[client] = player.CanUndoTeleport;
	oldCanPause[client] = player.CanPause;
	oldCanResume[client] = player.CanResume;
	forceRefresh[client] = false;
}

static void ShowPanel(KZPlayer player, HUDInfo info)
{
	char panelTitle[256];
	// Spectator List
	if (player.ShowSpectators >= ShowSpecs_Number && player.SpecListPosition == SpecListPosition_TPMenu)
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
	if (player.ShowSpectators >= ShowSpecs_Number && player.SpecListPosition == SpecListPosition_TPMenu)
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

	// Legacy behavior: Always able to make checkpoint attempts.
	if (gI_DynamicMenu[player.ID] == DynamicMenu_Enabled && !player.CanMakeCheckpoint)
	{
		menu.AddItem(ITEM_INFO_CHECKPOINT, display, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem(ITEM_INFO_CHECKPOINT, display, ITEMDRAW_DEFAULT);
	}
	
}

static void TPMenuAddItemTeleport(KZPlayer player, Menu menu)
{
	char display[24];
	FormatEx(display, sizeof(display), "%T", "TP Menu - Teleport", player.ID);
	if (player.TimerRunning)
	{
		Format(display, sizeof(display), "%s #%d", display, player.TeleportCount);
	}

	// Legacy behavior: Only able to make TP attempts when there is a checkpoint.
	if (gI_DynamicMenu[player.ID] == DynamicMenu_Disabled || player.CanTeleportToCheckpoint)
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

	// Legacy behavior: Only able to do prev CP when there is a previous checkpoint to go back to.
	if (gI_DynamicMenu[player.ID] == DynamicMenu_Disabled || player.CanPrevCheckpoint)
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

	// Legacy behavior: Only able to do prev CP when there is a next checkpoint to go forward to.
	if (gI_DynamicMenu[player.ID] == DynamicMenu_Disabled || player.CanNextCheckpoint)
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

	// Legacy behavior: Only able to attempt to undo TP when it is allowed.
	if (gI_DynamicMenu[player.ID] == DynamicMenu_Disabled || player.CanUndoTeleport)
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

	// Legacy behavior: Always able to attempt to pause.
	if (gI_DynamicMenu[player.ID] == DynamicMenu_Enabled)
	{
		if (player.Paused)
		{
			FormatEx(display, sizeof(display), "%T", "TP Menu - Resume", player.ID);
			if (player.CanResume)
			{
				menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
			}
			else
			{
				menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DISABLED);
			}
		}
		else
		{
			FormatEx(display, sizeof(display), "%T", "TP Menu - Pause", player.ID);
			if (player.CanPause)
			{
				menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DEFAULT);
			}
			else
			{
				menu.AddItem(ITEM_INFO_PAUSE, display, ITEMDRAW_DISABLED);
			}
		}
	}
	else
	{
		if (player.Paused)
		{
			FormatEx(display, sizeof(display), "%T", "TP Menu - Resume", player.ID);
		}
		else
		{
			FormatEx(display, sizeof(display), "%T", "TP Menu - Pause", player.ID);
		}
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