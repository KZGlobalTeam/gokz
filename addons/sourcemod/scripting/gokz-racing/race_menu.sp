/*
	A menu for hosting big races.
*/



#define ITEM_INFO_START "st"
#define ITEM_INFO_ABORT "ab"
#define ITEM_INFO_INVITE "iv"
#define ITEM_INFO_MODE "md"
#define ITEM_INFO_COURSE "co"
#define ITEM_INFO_TELEPORT "tp"

static int raceMenuMode[MAXPLAYERS + 1];
static int raceMenuCourse[MAXPLAYERS + 1];
static int raceMenuCheckpointLimit[MAXPLAYERS + 1];
static int raceMenuCheckpointCooldown[MAXPLAYERS + 1];



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
		raceMenuCourse[client] = 0;
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
				HostRace(param1, RaceType_Normal, raceMenuCourse[param1], raceMenuMode[param1], raceMenuCheckpointLimit[param1], raceMenuCheckpointCooldown[param1]);
			}
			
			SendRequestAll(param1);
			GOKZ_PrintToChat(param1, true, "%t", "You Invited Everyone");
			DisplayRaceMenu(param1, false);
		}
		else if (StrEqual(info, ITEM_INFO_MODE, false))
		{
			DisplayRaceModeMenu(param1);
		}
		else if (StrEqual(info, ITEM_INFO_COURSE, false))
		{
			int course = raceMenuCourse[param1];
			do
			{
				course++;
				if (!GOKZ_IsValidCourse(course))
				{
					course = 0;
				}
			} while (!GOKZ_GetCourseRegistered(course) && course != raceMenuCourse[param1]);
			raceMenuCourse[param1] = course;
			DisplayRaceMenu(param1, false);
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
	return 0;
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
	
	if (raceMenuCourse[client] == 0)
	{
		FormatEx(display, sizeof(display), "%T", "Race Rules - Main Course", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T %d", "Race Rules - Bonus Course", client, raceMenuCourse[client]);
	}
	menu.AddItem(ITEM_INFO_COURSE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%s", GetRaceRuleSummary(client, raceMenuCheckpointLimit[client], raceMenuCheckpointCooldown[client]));
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
	return 0;
}



// =====[ CHECKPOINT MENU ]=====

static void DisplayRaceCheckpointMenu(int client)
{
	Menu menu = new Menu(MenuHandler_RaceCheckpoint);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Checkpoint Rule Menu - Title", client);
	RaceCheckpointMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_RaceCheckpoint(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case CheckpointRule_None:
			{
				raceMenuCheckpointLimit[param1] = 0;
				raceMenuCheckpointCooldown[param1] = 0;
				DisplayRaceMenu(param1, false); 
			}
			case CheckpointRule_Limit:
			{
				DisplayCheckpointLimitMenu(param1);
			}
			case CheckpointRule_Cooldown:
			{
				DisplayCheckpointCooldownMenu(param1);
			}
			case CheckpointRule_Unlimited:
			{
				raceMenuCheckpointLimit[param1] = -1;
				raceMenuCheckpointCooldown[param1] = 0;
				DisplayRaceMenu(param1, false);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayRaceMenu(param1, false);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void RaceCheckpointMenuAddItems(int client, Menu menu)
{
	char display[32];

	menu.RemoveAllItems();

	FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - None", client);
	menu.AddItem("", display);

	if (raceMenuCheckpointLimit[client] == -1)
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - No Checkpoint Limit", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - Checkpoint Limit", client, raceMenuCheckpointLimit[client]);
	}
	menu.AddItem("", display);

	if (raceMenuCheckpointCooldown[client] == 0)
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - No Checkpoint Cooldown", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - Checkpoint Cooldown", client, raceMenuCheckpointCooldown[client]);
	}
	menu.AddItem("", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - Unlimited", client);
	menu.AddItem("", display);
}



// =====[ CP LIMIT MENU ]=====

static void DisplayCheckpointLimitMenu(int client)
{
	char display[32];

	Menu menu = new Menu(MenuHandler_RaceCheckpointLimit);
	menu.ExitButton = false;
	menu.ExitBackButton = true;

	if (raceMenuCheckpointLimit[client] == -1)
	{
		menu.SetTitle("%T", "Checkpoint Limit Menu - Title Unlimited", client);
	}
	else
	{
		menu.SetTitle("%T", "Checkpoint Limit Menu - Title Limited", client, raceMenuCheckpointLimit[client]);
	}

	FormatEx(display, sizeof(display), "%T", "Checkpoint Limit Menu - Add One", client);
	menu.AddItem("+1", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Limit Menu - Add Five", client);
	menu.AddItem("+5", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Limit Menu - Remove One", client);
	menu.AddItem("-1", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Limit Menu - Remove Five", client);
	menu.AddItem("-5", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Limit Menu - Unlimited", client);
	menu.AddItem("Unlimited", display);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_RaceCheckpointLimit(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(param2, item, sizeof(item));
		if (StrEqual(item, "+1"))
		{
			if (raceMenuCheckpointLimit[param1] == -1)
			{
				raceMenuCheckpointLimit[param1]++;
			}
			raceMenuCheckpointLimit[param1]++;
		}
		if (StrEqual(item, "+5"))
		{
			if (raceMenuCheckpointLimit[param1] == -1)
			{
				raceMenuCheckpointLimit[param1]++;
			}
			raceMenuCheckpointLimit[param1] += 5;
		}
		if (StrEqual(item, "-1"))
		{
			raceMenuCheckpointLimit[param1]--;
		}
		if (StrEqual(item, "-5"))
		{
			raceMenuCheckpointLimit[param1] -= 5;
		}
		if (StrEqual(item, "Unlimited"))
		{
			raceMenuCheckpointLimit[param1] = -1;
			DisplayRaceCheckpointMenu(param1);
			return 0;
		}

		raceMenuCheckpointLimit[param1] = raceMenuCheckpointLimit[param1] < 0 ? 0 : raceMenuCheckpointLimit[param1];
		DisplayCheckpointLimitMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayRaceCheckpointMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}



// =====[ CP COOLDOWN MENU ]=====

static void DisplayCheckpointCooldownMenu(int client)
{
	char display[32];

	Menu menu = new Menu(MenuHandler_RaceCPCooldown);
	menu.ExitButton = false;
	menu.ExitBackButton = true;

	if (raceMenuCheckpointCooldown[client] == -1)
	{
		menu.SetTitle("%T", "Checkpoint Cooldown Menu - Title None", client);
	}
	else
	{
		menu.SetTitle("%T", "Checkpoint Cooldown Menu - Title Limited", client, raceMenuCheckpointCooldown[client]);
	}

	FormatEx(display, sizeof(display), "%T", "Checkpoint Cooldown Menu - Add One Second", client);
	menu.AddItem("+1", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Cooldown Menu - Add Five Seconds", client);
	menu.AddItem("+5", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Cooldown Menu - Remove One Second", client);
	menu.AddItem("-1", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Cooldown Menu - Remove Five Seconds", client);
	menu.AddItem("-5", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Cooldown Menu - None", client);
	menu.AddItem("None", display);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_RaceCPCooldown(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(param2, item, sizeof(item));
		if (StrEqual(item, "+1"))
		{
			if (raceMenuCheckpointCooldown[param1] == -1)
			{
				raceMenuCheckpointCooldown[param1]++;
			}
			raceMenuCheckpointCooldown[param1]++;
		}
		if (StrEqual(item, "+5"))
		{
			if (raceMenuCheckpointCooldown[param1] == -1)
			{
				raceMenuCheckpointCooldown[param1]++;
			}
			raceMenuCheckpointCooldown[param1] += 5;
		}
		if (StrEqual(item, "-1"))
		{
			raceMenuCheckpointCooldown[param1]--;
		}
		if (StrEqual(item, "-5"))
		{
			raceMenuCheckpointCooldown[param1] -= 5;
		}
		if (StrEqual(item, "None"))
		{
			raceMenuCheckpointCooldown[param1] = 0;
			DisplayRaceCheckpointMenu(param1);
			return 0;
		}

		raceMenuCheckpointCooldown[param1] = raceMenuCheckpointCooldown[param1] < 0 ? 0 : raceMenuCheckpointCooldown[param1];
		DisplayCheckpointCooldownMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayRaceCheckpointMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}



// =====[ PRIVATE ]=====

char[] GetRaceRuleSummary(int client, int checkpointLimit, int checkpointCooldown)
{
	char rulesString[64];
	if (checkpointLimit == -1 && checkpointCooldown == 0)
	{
		FormatEx(rulesString, sizeof(rulesString), "%T", "Rule Summary - Unlimited", client);
	}
	else if (checkpointLimit > 0 && checkpointCooldown == 0)
	{
		FormatEx(rulesString, sizeof(rulesString), "%T", "Rule Summary - Limited Checkpoints", client, checkpointLimit);
	}
	else if (checkpointLimit == -1 && checkpointCooldown > 0)
	{
		FormatEx(rulesString, sizeof(rulesString), "%T", "Rule Summary - Limited Cooldown", client, checkpointCooldown);
	}
	else if (checkpointLimit > 0 && checkpointCooldown > 0)
	{
		FormatEx(rulesString, sizeof(rulesString), "%T", "Rule Summary - Limited Everything", client, checkpointLimit, checkpointCooldown);
	}
	else if (checkpointLimit == 0)
	{
		FormatEx(rulesString, sizeof(rulesString), "%T", "Rule Summary - No Checkpoints", client);
	}

	return rulesString;
}