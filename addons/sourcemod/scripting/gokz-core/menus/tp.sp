/*
	Teleport Menu
	
	Lets players easily use teleport functionality.
*/



static Menu TPMenu[MAXPLAYERS + 1];
static bool TPMenuIsShowing[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

void CreateMenusTP()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		TPMenu[client] = new Menu(MenuHandler_TPMenu);
		TPMenu[client].OptionFlags = MENUFLAG_NO_SOUND;
		TPMenu[client].ExitButton = false;
		TPMenu[client].Pagination = MENU_NO_PAGINATION;
	}
}

void UpdateTPMenu(int client)
{
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
		switch (param2)
		{
			case 0:GOKZ_MakeCheckpoint(param1);
			case 1:GOKZ_TeleportToCheckpoint(param1);
			case 2:GOKZ_PrevCheckpoint(param1);
			case 3:GOKZ_NextCheckpoint(param1);
			case 4:GOKZ_UndoTeleport(param1);
			case 5:GOKZ_TogglePause(param1);
			case 6:GOKZ_TeleportToStart(param1);
		}
		TPMenuIsShowing[param1] = false;
	}
	else if (action == MenuAction_Cancel)
	{
		TPMenuIsShowing[param1] = false;
	}
}


// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_TPMenu(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	// Checks that no other menu is open instead of rudely interrupting it
	if (GetOption(client, Option_ShowingTPMenu) == ShowingTPMenu_Enabled
		 && !TPMenuIsShowing[client]
		 && GetClientMenu(client) == MenuSource_None)
	{
		TPMenuUpdateItems(client, TPMenu[client]);
		TPMenu[client].Display(client, MENU_TIME_FOREVER);
		TPMenuIsShowing[client] = true;
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

static void TPMenuUpdateItems(int client, Menu menu)
{
	menu.RemoveAllItems();
	AddItemsTPMenu(client, menu);
}

static void AddItemsTPMenu(int client, Menu menu)
{
	AddItemTPMenuCheckpoint(client, menu);
	AddItemTPMenuTeleport(client, menu);
	AddItemTPMenuPrevCheckpoint(client, menu);
	AddItemTPMenuNextCheckpoint(client, menu);
	AddItemTPMenuUndo(client, menu);
	AddItemTPMenuPause(client, menu);
	AddItemTPMenuStart(client, menu);
}

static void AddItemTPMenuCheckpoint(int client, Menu menu)
{
	char temp[16];
	FormatEx(temp, sizeof(temp), "%T", "TP Menu - Checkpoint", client);
	menu.AddItem("", temp, ITEMDRAW_DEFAULT);
}

static void AddItemTPMenuTeleport(int client, Menu menu)
{
	char temp[16];
	FormatEx(temp, sizeof(temp), "%T", "TP Menu - Teleport", client);
	if (CanTeleportToCheckpoint(client))
	{
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem("", temp, ITEMDRAW_DISABLED);
	}
}

static void AddItemTPMenuPrevCheckpoint(int client, Menu menu)
{
	char temp[16];
	FormatEx(temp, sizeof(temp), "%T", "TP Menu - Prev CP", client);
	if (CanPrevCheckpoint(client))
	{
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem("", temp, ITEMDRAW_DISABLED);
	}
}

static void AddItemTPMenuNextCheckpoint(int client, Menu menu)
{
	char temp[16];
	FormatEx(temp, sizeof(temp), "%T", "TP Menu - Next CP", client);
	if (CanNextCheckpoint(client))
	{
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem("", temp, ITEMDRAW_DISABLED);
	}
}

static void AddItemTPMenuUndo(int client, Menu menu)
{
	char temp[16];
	FormatEx(temp, sizeof(temp), "%T", "TP Menu - Undo TP", client);
	if (CanUndoTeleport(client))
	{
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
	else
	{
		menu.AddItem("", temp, ITEMDRAW_DISABLED);
	}
}

static void AddItemTPMenuPause(int client, Menu menu)
{
	char temp[16];
	if (GetPaused(client))
	{
		FormatEx(temp, sizeof(temp), "%T", "TP Menu - Resume", client);
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(temp, sizeof(temp), "%T", "TP Menu - Pause", client);
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
}

static void AddItemTPMenuStart(int client, Menu menu) {
	char temp[16];
	if (GetHasStartedTimerThisMap(client))
	{
		FormatEx(temp, sizeof(temp), "%T", "TP Menu - Restart", client);
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(temp, sizeof(temp), "%T", "TP Menu - Respawn", client);
		menu.AddItem("", temp, ITEMDRAW_DEFAULT);
	}
}
