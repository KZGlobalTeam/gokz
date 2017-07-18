/*
	Mode Menu
	
	Lets players pick their movement mode.
*/



static Menu modeMenu[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

void CreateMenusMode()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		modeMenu[client] = new Menu(MenuHandler_MovementMode);
	}
}

void DisplayModeMenu(int client)
{
	modeMenu[client].SetTitle("%T", "Mode Menu - Title", client);
	ModeMenuAddItems(client, modeMenu[client]);
	modeMenu[client].Display(client, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_MovementMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetOption(param1, Option_Mode, param2);
	}
}



// =========================  PRIVATE  ========================= //

static void ModeMenuAddItems(int client, Menu menu)
{
	int selectedMode = GOKZ_GetOption(client, Option_Mode);
	char temp[32];
	menu.RemoveAllItems();
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		FormatEx(temp, sizeof(temp), "%s", gC_ModeNames[mode], client);
		// Add mark to selected mode
		if (mode == selectedMode)
		{
			Format(temp, sizeof(temp), "%s*", temp);
		}
		
		if (GOKZ_GetModeLoaded(mode))
		{
			menu.AddItem("", temp, ITEMDRAW_DEFAULT);
		}
		else
		{
			menu.AddItem("", temp, ITEMDRAW_DISABLED);
		}
	}
} 