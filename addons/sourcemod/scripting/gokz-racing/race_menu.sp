/*
	A menu for hosting big races.
*/



#define ITEM_INFO_START "st"
#define ITEM_INFO_ABORT "ab"
#define ITEM_INFO_INVITE "iv"
#define ITEM_INFO_MODE "md"
#define ITEM_INFO_TELEPORT "tp"

static int raceMenuMode[MAXPLAYERS + 1];
static int raceMenuCheckpoint[MAXPLAYERS + 1];



// =====[ PICK MODE ]=====

void DisplayRaceMenu(int client, bool reset = true)
{
	if (InRace(client) && (!IsRaceHost(client) || GetRaceInfo(GetRaceID(client), RaceInfo_Type) != RaceType_Normal))
	{
		GOKZ_PrintToChat(client, true, "%t", "You Are Already Part Of A Race");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	if (reset)
	{
		raceMenuMode[client] = GOKZ_GetCoreOption(client, Option_Mode);
	}
	
	Menu menu = new Menu(MenuHandler_Race);
	menu.SetTitle("%T", "Race Menu - Title", client);
	RaceMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Race(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, ITEM_INFO_START, false))
		{
			if (!StartHostedRace(param1))
			{
				DisplayRaceMenu(param1, false);
			}
		}
		else if (StrEqual(info, ITEM_INFO_ABORT, false))
		{
			AbortHostedRace(param1);
			DisplayRaceMenu(param1, false);
		}
		else if (StrEqual(info, ITEM_INFO_INVITE, false))
		{
			if (!InRace(param1))
			{
				HostRace(param1, RaceType_Normal, 0, raceMenuMode[param1], raceMenuCheckpoint[param1]);
			}
			
			SendRequestAll(param1);
			GOKZ_PrintToChat(param1, true, "%t", "You Invited Everyone");
			DisplayRaceMenu(param1, false);
		}
		else if (StrEqual(info, ITEM_INFO_MODE, false))
		{
			DisplayRaceModeMenu(param1);
		}
		else if (StrEqual(info, ITEM_INFO_TELEPORT, false))
		{
			DisplayRaceCheckpointMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void RaceMenuAddItems(int client, Menu menu)
{
	char display[32];
	
	menu.RemoveAllItems();
	
	bool pending = GetRaceInfo(GetRaceID(client), RaceInfo_Status) == RaceStatus_Pending;
	FormatEx(display, sizeof(display), "%T", "Race Menu - Start Race", client);
	menu.AddItem(ITEM_INFO_START, display, (InRace(client) && pending) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(display, sizeof(display), "%T", "Race Menu - Invite Everyone", client);
	menu.AddItem(ITEM_INFO_INVITE, display, (!InRace(client) || pending) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(display, sizeof(display), "%T\n \n%T", "Race Menu - Abort Race", client, "Race Menu - Rules", client);
	menu.AddItem(ITEM_INFO_ABORT, display, InRace(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(display, sizeof(display), "%s", gC_ModeNames[raceMenuMode[client]]);
	menu.AddItem(ITEM_INFO_MODE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%T", gC_CheckpointRulePhrases[raceMenuCheckpoint[client]], client);
	menu.AddItem(ITEM_INFO_TELEPORT, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
}



// =====[ MODE MENU ]=====

static void DisplayRaceModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_RaceMode);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Mode Rule Menu - Title", client);
	GOKZ_MenuAddModeItems(client, menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_RaceMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		raceMenuMode[param1] = param2;
		DisplayRaceMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayRaceMenu(param1, false);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ TELEPORT MENU ]=====

static void DisplayRaceCheckpointMenu(int client)
{
	Menu menu = new Menu(MenuHandler_RaceCheckpoint);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Checkpoint Rule Menu - Title", client);
	GOKZ_RC_MenuAddCheckpointRuleItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_RaceCheckpoint(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		raceMenuCheckpoint[param1] = param2;
		DisplayRaceMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayRaceMenu(param1, false);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
} 