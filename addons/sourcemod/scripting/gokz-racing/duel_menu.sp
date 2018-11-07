/*
	A menu for initiating 1v1 races.
*/



#define ITEM_INFO_CHALLENGE "ch"
#define ITEM_INFO_ABORT "ab"
#define ITEM_INFO_MODE "md"
#define ITEM_INFO_TELEPORT "tp"

static int duelMenuMode[MAXPLAYERS + 1];
static int duelMenuTeleport[MAXPLAYERS + 1];



// =====[ PICK MODE ]=====

void DisplayDuelMenu(int client, bool reset = true)
{
	if (InRace(client) && (!IsRaceHost(client) || GetRaceInfo(GetRaceID(client), RaceInfo_Type) != RaceType_Duel))
	{
		GOKZ_PrintToChat(client, true, "%t", "You Are Already Part Of A Race");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	if (reset)
	{
		duelMenuMode[client] = GOKZ_GetCoreOption(client, Option_Mode);
	}
	
	Menu menu = new Menu(MenuHandler_Duel);
	menu.SetTitle("%T", "Duel Menu - Title", client);
	DuelMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Duel(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, ITEM_INFO_CHALLENGE, false))
		{
			if (!DisplayDuelOpponentMenu(param1))
			{
				DisplayDuelMenu(param1, false);
			}
		}
		else if (StrEqual(info, ITEM_INFO_ABORT, false))
		{
			AbortHostedRace(param1);
			DisplayDuelMenu(param1, false);
		}
		else if (StrEqual(info, ITEM_INFO_MODE, false))
		{
			DisplayRaceModeMenu(param1);
		}
		else if (StrEqual(info, ITEM_INFO_TELEPORT, false))
		{
			DisplayRaceTeleportMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void DuelMenuAddItems(int client, Menu menu)
{
	char display[32];
	
	menu.RemoveAllItems();
	
	FormatEx(display, sizeof(display), "%T", "Duel Menu - Choose Opponent", client);
	menu.AddItem(ITEM_INFO_CHALLENGE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%T\n \n%T", "Race Menu - Abort Race", client, "Race Menu - Rules", client);
	menu.AddItem(ITEM_INFO_ABORT, display, InRace(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(display, sizeof(display), "%s", gC_ModeNames[duelMenuMode[client]]);
	menu.AddItem(ITEM_INFO_MODE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%T", gC_TeleportRulePhrases[duelMenuTeleport[client]], client);
	menu.AddItem(ITEM_INFO_TELEPORT, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
}



// =====[ MODE MENU ]=====

static void DisplayRaceModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DuelMode);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Mode Rule Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DuelMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		duelMenuMode[param1] = param2;
		DisplayDuelMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayDuelMenu(param1, false);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ TELEPORT MENU ]=====

static void DisplayRaceTeleportMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DuelTeleport);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Teleport Rule Menu - Title", client);
	GOKZ_RC_MenuAddTeleportsRuleItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DuelTeleport(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		duelMenuTeleport[param1] = param2;
		DisplayDuelMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayDuelMenu(param1, false);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ OPPONENT MENU ]=====

static bool DisplayDuelOpponentMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DuelOpponent);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Duel Opponent Selection Menu - Title", client);
	if (DuelOpponentMenuAddItems(client, menu) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Opponents Available");
		GOKZ_PlayErrorSound(client);
		delete menu;
		return false;
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return true;
}

static int DuelOpponentMenuAddItems(int client, Menu menu)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		char display[MAX_NAME_LENGTH];
		if (i != client && IsClientInGame(i) && !IsFakeClient(i) && !InRace(i))
		{
			FormatEx(display, sizeof(display), "%N", i);
			menu.AddItem(IntToStringEx(GetClientUserId(i)), display);
			count++;
		}
	}
	return count;
}

public int MenuHandler_DuelOpponent(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if (IsValidClient(target))
		{
			if (SendDuelRequest(param1, target))
			{
				GOKZ_PrintToChat(param1, true, "%t", "Duel Request Sent", target);
			}
			else
			{
				DisplayDuelOpponentMenu(param1);
			}
		}
		else
		{
			GOKZ_PrintToChat(param1, true, "%t", "Player No Longer Valid");
			GOKZ_PlayErrorSound(param1);
			DisplayDuelOpponentMenu(param1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayDuelMenu(param1, false);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

static bool SendDuelRequest(int host, int target)
{
	if (InRace(target))
	{
		GOKZ_PrintToChat(host, true, "%t", "Player Already In A Race", target);
		GOKZ_PlayErrorSound(host);
		return false;
	}
	
	HostRace(host, RaceType_Duel, 0, duelMenuMode[host], duelMenuTeleport[host]);
	return SendRequest(host, target);
} 