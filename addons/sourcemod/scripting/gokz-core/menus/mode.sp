/*
	Mode Menu
	
	Lets players pick their movement mode.
*/



// =========================  PUBLIC  ========================= //

void DisplayModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Mode);
	menu.SetTitle("%T", "Mode Menu - Title", client);
	ModeMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Mode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetOption(param1, Option_Mode, param2);
		if (GetCameFromOptionsMenu(param1))
		{
			DisplayOptionsMenu(param1, 0);
		}
	}
	else if (action == MenuAction_Cancel && GetCameFromOptionsMenu(param1))
	{
		// Reopen the options menu at the page this option is on
		DisplayOptionsMenu(param1, 0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

static void ModeMenuAddItems(int client, Menu menu)
{
	int selectedMode = GOKZ_GetOption(client, Option_Mode);
	char display[32];
	
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		FormatEx(display, sizeof(display), "%s", gC_ModeNames[mode]);
		// Add asterisk to selected mode
		if (mode == selectedMode)
		{
			Format(display, sizeof(display), "%s*", display);
		}
		
		if (GOKZ_GetModeLoaded(mode))
		{
			menu.AddItem("", display, ITEMDRAW_DEFAULT);
		}
		else
		{
			menu.AddItem("", display, ITEMDRAW_DISABLED);
		}
	}
} 