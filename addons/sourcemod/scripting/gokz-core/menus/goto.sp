/*
	Goto Menu
	
	Lets players pick an alive player to teleport to.
*/



// =========================  PUBLIC  ========================= //

void DisplayGotoMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Goto);
	menu.SetTitle("%T", "Goto Menu - Title", client);
	if (GotoMenuAddItems(client, menu) == 0)
	{
		delete menu;
		GOKZ_PrintToChat(client, true, "%t", "No Players Found");
		GOKZ_PlayErrorSound(client);
	}
	else
	{
		menu.Display(client, MENU_TIME_FOREVER);
	}
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Goto(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		
		if (!IsValidClient(target))
		{
			GOKZ_PrintToChat(param1, true, "%t", "Goto Failure (Invalid Player)");
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
	char display[MAX_NAME_LENGTH];
	int targetCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i) || i == client)
		{
			continue;
		}
		
		FormatEx(display, sizeof(display), "%N", i);
		menu.AddItem(IntToStringEx(GetClientUserId(i)), display, ITEMDRAW_DEFAULT);
		targetCount++;
	}
	
	return targetCount;
} 