/*
	Pistol Menu
	
	Lets players pick their pistol.
*/



// =========================  PUBLIC  ========================= //

void DisplayPistolMenu(int client, int atItem = 0)
{
	Menu menu = new Menu(MenuHandler_Pistol);
	menu.SetTitle("%T", "Pistol Menu - Title", client);
	PistolMenuAddItems(client, menu);
	menu.DisplayAt(client, atItem, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Pistol(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetCoreOption(param1, Option_Pistol, param2);
		DisplayOptionsMenu(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Cancel && GetCameFromOptionsMenu(param1))
	{
		DisplayOptionsMenu(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

static void PistolMenuAddItems(int client, Menu menu)
{
	int selectedPistol = GOKZ_GetCoreOption(client, Option_Pistol);
	char display[32];
	
	for (int pistol = 0; pistol < PISTOL_COUNT; pistol++)
	{
		if (pistol == Pistol_Disabled)
		{
			FormatEx(display, sizeof(display), "%T", "Options Menu - Disabled", client);
		}
		else
		{
			FormatEx(display, sizeof(display), "%s", gC_PistolNames[pistol]);
		}
		
		// Add asterisk to selected pistol
		if (pistol == selectedPistol)
		{
			Format(display, sizeof(display), "%s*", display);
		}
		
		menu.AddItem("", display, ITEMDRAW_DEFAULT);
	}
} 