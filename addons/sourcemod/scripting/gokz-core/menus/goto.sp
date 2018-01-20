/*
	Goto Menu
	
	Lets players pick an alive player to teleport to.
*/



// =========================  PUBLIC  ========================= //

int DisplayGotoMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Goto);
	menu.SetTitle("%T", "Goto Menu - Title", client);
	int menuItems = GotoMenuAddItems(client, menu);
	if (menuItems == 0)
	{
		delete menu;
	}
	else
	{
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return menuItems;
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Goto(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		
		if (!IsValidClient(target))
		{
			GOKZ_PrintToChat(param1, true, "%t", "Player No Longer Valid");
			GOKZ_PlayErrorSound(param1);
			DisplayGotoMenu(param1);
		}
		else if (!GotoPlayer(param1, target))
		{
			DisplayGotoMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

// Returns number of items added to the menu
static int GotoMenuAddItems(int client, Menu menu)
{
	char display[MAX_NAME_LENGTH + 4];
	int targetCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
		{
			continue;
		}
		
		if (IsFakeClient(i))
		{
			FormatEx(display, sizeof(display), "BOT %N", i);
		}
		else
		{
			FormatEx(display, sizeof(display), "%N", i);
		}
		
		menu.AddItem(IntToStringEx(GetClientUserId(i)), display, ITEMDRAW_DEFAULT);
		targetCount++;
	}
	
	return targetCount;
} 