/*
	A menu for initiating 1v1 races.
*/



#define ITEM_INFO_CHALLENGE "ch"
#define ITEM_INFO_ABORT "ab"
#define ITEM_INFO_MODE "md"
#define ITEM_INFO_COURSE "co"
#define ITEM_INFO_TELEPORT "tp"

static int duelMenuMode[MAXPLAYERS + 1];
static int duelMenuCourse[MAXPLAYERS + 1];
static int duelMenuCheckpointLimit[MAXPLAYERS + 1];
static int duelMenuCheckpointCooldown[MAXPLAYERS + 1];



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
			DisplayDuelModeMenu(param1);
		}
		else if (StrEqual(info, ITEM_INFO_COURSE, false))
		{
			int course = duelMenuCourse[param1];
			do
			{
				course++;
				if (!GOKZ_IsValidCourse(course))
				{
					course = 0;
				}
			} while (!GOKZ_GetCourseRegistered(course) && course != duelMenuCourse[param1]);
			duelMenuCourse[param1] = course;
			DisplayDuelMenu(param1, false);
		}
		else if (StrEqual(info, ITEM_INFO_TELEPORT, false))
		{
			DisplayDuelCheckpointMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void DuelMenuAddItems(int client, Menu menu)
{
	char display[64];
	
	menu.RemoveAllItems();
	
	FormatEx(display, sizeof(display), "%T", "Duel Menu - Choose Opponent", client);
	menu.AddItem(ITEM_INFO_CHALLENGE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%T\n \n%T", "Race Menu - Abort Race", client, "Race Menu - Rules", client);
	menu.AddItem(ITEM_INFO_ABORT, display, InRace(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(display, sizeof(display), "%s", gC_ModeNames[duelMenuMode[client]]);
	menu.AddItem(ITEM_INFO_MODE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	if (duelMenuCourse[client] == 0)
	{
		FormatEx(display, sizeof(display), "%T", "Race Rules - Main Course", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T %d", "Race Rules - Bonus Course", client, duelMenuCourse[client]);
	}
	menu.AddItem(ITEM_INFO_COURSE, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%s", GetDuelRuleSummary(client, duelMenuCheckpointLimit[client], duelMenuCheckpointCooldown[client]));
	menu.AddItem(ITEM_INFO_TELEPORT, display, InRace(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
}



// =====[ MODE MENU ]=====

static void DisplayDuelModeMenu(int client)
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
	return 0;
}



// =====[ CHECKPOINT MENU ]=====

static void DisplayDuelCheckpointMenu(int client)
{
	Menu menu = new Menu(MenuHandler_DuelCheckpoint);
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Checkpoint Rule Menu - Title", client);
	DuelCheckpointMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DuelCheckpoint(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case CheckpointRule_None:
			{
				duelMenuCheckpointCooldown[param1] = 0;
				duelMenuCheckpointLimit[param1] = 0;
				DisplayDuelMenu(param1, false);
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
				duelMenuCheckpointCooldown[param1] = 0;
				duelMenuCheckpointLimit[param1] = -1;
				DisplayDuelMenu(param1, false);
			}
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
	return 0;
}

void DuelCheckpointMenuAddItems(int client, Menu menu)
{
	char display[32];

	menu.RemoveAllItems();

	FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - None", client);
	menu.AddItem("", display);

	if (duelMenuCheckpointLimit[client] == -1)
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - No Checkpoint Limit", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - Checkpoint Limit", client, duelMenuCheckpointLimit[client]);
	}
	menu.AddItem("", display);

	if (duelMenuCheckpointCooldown[client] == 0)
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - No Checkpoint Cooldown", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - Checkpoint Cooldown", client, duelMenuCheckpointCooldown[client]);
	}
	menu.AddItem("", display);

	FormatEx(display, sizeof(display), "%T", "Checkpoint Rule - Unlimited", client);
	menu.AddItem("", display);
}



// =====[ CP LIMIT MENU ]=====

static void DisplayCheckpointLimitMenu(int client)
{
	char display[32];

	Menu menu = new Menu(MenuHandler_DuelCheckpointLimit);
	menu.ExitButton = false;
	menu.ExitBackButton = true;

	if (duelMenuCheckpointLimit[client] == -1)
	{
		menu.SetTitle("%T", "Checkpoint Limit Menu - Title Unlimited", client);
	}
	else
	{
		menu.SetTitle("%T", "Checkpoint Limit Menu - Title Limited", client, duelMenuCheckpointLimit[client]);
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

public int MenuHandler_DuelCheckpointLimit(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(param2, item, sizeof(item));
		if (StrEqual(item, "+1"))
		{
			if (duelMenuCheckpointLimit[param1] == -1)
			{
				duelMenuCheckpointLimit[param1]++;
			}
			duelMenuCheckpointLimit[param1]++;
		}
		if (StrEqual(item, "+5"))
		{
			if (duelMenuCheckpointLimit[param1] == -1)
			{
				duelMenuCheckpointLimit[param1]++;
			}
			duelMenuCheckpointLimit[param1] += 5;
		}
		if (StrEqual(item, "-1"))
		{
			duelMenuCheckpointLimit[param1]--;
		}
		if (StrEqual(item, "-5"))
		{
			duelMenuCheckpointLimit[param1] -= 5;
		}
		if (StrEqual(item, "Unlimited"))
		{
			duelMenuCheckpointLimit[param1] = -1;
			DisplayDuelCheckpointMenu(param1);
			return 0;
		}

		duelMenuCheckpointLimit[param1] = duelMenuCheckpointLimit[param1] < 0 ? 0 : duelMenuCheckpointLimit[param1];
		DisplayCheckpointLimitMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayDuelCheckpointMenu(param1);
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

	Menu menu = new Menu(MenuHandler_DuelCPCooldown);
	menu.ExitButton = false;
	menu.ExitBackButton = true;

	if (duelMenuCheckpointCooldown[client] == -1)
	{
		menu.SetTitle("%T", "Checkpoint Cooldown Menu - Title None", client);
	}
	else
	{
		menu.SetTitle("%T", "Checkpoint Cooldown Menu - Title Limited", client, duelMenuCheckpointCooldown[client]);
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

public int MenuHandler_DuelCPCooldown(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(param2, item, sizeof(item));
		if (StrEqual(item, "+1"))
		{
			if (duelMenuCheckpointCooldown[param1] == -1)
			{
				duelMenuCheckpointCooldown[param1]++;
			}
			duelMenuCheckpointCooldown[param1]++;
		}
		if (StrEqual(item, "+5"))
		{
			if (duelMenuCheckpointCooldown[param1] == -1)
			{
				duelMenuCheckpointCooldown[param1]++;
			}
			duelMenuCheckpointCooldown[param1] += 5;
		}
		if (StrEqual(item, "-1"))
		{
			duelMenuCheckpointCooldown[param1]--;
		}
		if (StrEqual(item, "-5"))
		{
			duelMenuCheckpointCooldown[param1] -= 5;
		}
		if (StrEqual(item, "None"))
		{
			duelMenuCheckpointCooldown[param1] = 0;
			DisplayDuelCheckpointMenu(param1);
			return 0;
		}

		duelMenuCheckpointCooldown[param1] = duelMenuCheckpointCooldown[param1] < 0 ? 0 : duelMenuCheckpointCooldown[param1];
		DisplayCheckpointCooldownMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayDuelCheckpointMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
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
	return 0;
}

static bool SendDuelRequest(int host, int target)
{
	if (InRace(target))
	{
		GOKZ_PrintToChat(host, true, "%t", "Player Already In A Race", target);
		GOKZ_PlayErrorSound(host);
		return false;
	}
	
	HostRace(host, RaceType_Duel, duelMenuCourse[host], duelMenuMode[host], duelMenuCheckpointLimit[host], duelMenuCheckpointCooldown[host]);
	return SendRequest(host, target);
} 



// =====[ PRIVATE ]=====

char[] GetDuelRuleSummary(int client, int checkpointLimit, int checkpointCooldown)
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