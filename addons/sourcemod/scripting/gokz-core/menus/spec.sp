/*
	Spec Menu
	
	Lets players pick an alive player to spectate.
*/



// =========================  PUBLIC  ========================= //

void DisplaySpecMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Spec);
	menu.SetTitle("%T", "Spec Menu - Title", client);
	if (SpecMenuAddItems(client, menu) == 0)
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

// Returns whether change to spectating the target was successful
bool SpectatePlayer(int client, int target, bool printMessage = true)
{
	if (target == client)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Spectate Failure (Not Yourself)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	else if (!IsPlayerAlive(target))
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Spectate Failure (Dead)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	
	JoinTeam(client, CS_TEAM_SPECTATOR);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
	
	return true;
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Spec(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		
		if (!IsValidClient(target))
		{
			GOKZ_PrintToChat(param1, true, "%t", "Player No Longer Valid");
			GOKZ_PlayErrorSound(param1);
			DisplaySpecMenu(param1);
		}
		else if (!SpectatePlayer(param1, target))
		{
			DisplaySpecMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

// Returns number of items added to the menu
static int SpecMenuAddItems(int client, Menu menu)
{
	char display[MAX_NAME_LENGTH];
	int targetCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
		{
			continue;
		}
		
		FormatEx(display, sizeof(display), "%N", i);
		menu.AddItem(IntToStringEx(GetClientUserId(i)), display, ITEMDRAW_DEFAULT);
		targetCount++;
	}
	
	return targetCount;
} 