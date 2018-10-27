/*
	Mode Menu
	
	Lets players pick their movement mode.
*/



// =========================  PUBLIC  ========================= //

void DisplayModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Mode);
	menu.SetTitle("%T", "Mode Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Mode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetCoreOption(param1, Option_Mode, param2);
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