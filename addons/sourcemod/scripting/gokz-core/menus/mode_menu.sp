/*
	Lets players choose their mode.
*/



// =====[ PUBLIC ]=====

void DisplayModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Mode);
	menu.SetTitle("%T", "Mode Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ EVENTS ]=====

public int MenuHandler_Mode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetCoreOption(param1, Option_Mode, param2);
		if (GetCameFromOptionsMenu(param1))
		{
			DisplayOptionsMenu(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Cancel && GetCameFromOptionsMenu(param1))
	{
		DisplayOptionsMenu(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
} 