/*
	Options Menu
	
	Lets players view and set options.
*/



static bool cameFromOptionsMenu[MAXPLAYERS + 1];

static char phrasesShowingKeys[SHOWINGKEYS_COUNT][] = 
{
	"Options Menu - Spectating", 
	"Options Menu - Always", 
	"Options Menu - Disabled"
};

static char phrasesTimerText[TIMERTEXT_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Info Panel", 
	"Options Menu - Bottom", 
	"Options Menu - Top"
};

static char phrasesSpeedText[SPEEDTEXT_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Info Panel", 
	"Options Menu - Bottom"
};

static char phrasesJumpBeam[JUMPBEAM_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Feet", 
	"Options Menu - Head", 
	"Options Menu - Feet and Head", 
	"Options Menu - Ground"
};

static char pistolNames[PISTOL_COUNT][] = 
{
	"P2000 / USP-S", 
	"Glock-18", 
	"P250", 
	"Dual Berettas", 
	"Deagle", 
	"CZ75-Auto", 
	"Five-SeveN", 
	"Tec-9"
};



// =========================  PUBLIC  ========================= //

void DisplayOptionsMenu(int client, int atItem = 0)
{
	Menu menu = new Menu(MenuHandler_Options);
	menu.Pagination = 6;
	menu.SetTitle("%T", "Options Menu - Title", client);
	OptionsMenuAddItems(client, menu);
	menu.DisplayAt(client, atItem, MENU_TIME_FOREVER);
	cameFromOptionsMenu[client] = false;
}

bool GetCameFromOptionsMenu(int client)
{
	return cameFromOptionsMenu[client];
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Options(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		Option option = view_as<Option>(StringToInt(info));
		
		switch (option)
		{
			case Option_Pistol:
			{
				cameFromOptionsMenu[param1] = true;
				DisplayPistolMenu(param1);
			}
			case Option_AutoRestart:CycleOption(param1, Option_AutoRestart, true);
			case Option_SlayOnEnd:CycleOption(param1, Option_SlayOnEnd, true);
			default:CycleOption(param1, option, false);
		}
		if (param2 != 11) // Pistol
		{
			// Reopen the menu at the same place
			DisplayOptionsMenu(param1, param2 / 6 * 6);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

static void OptionsMenuAddItems(int client, Menu menu)
{
	OptionsMenuAddToggle(client, menu, Option_ShowingTPMenu, "Options Menu - Teleport Menu");
	OptionsMenuAddToggle(client, menu, Option_ShowingInfoPanel, "Options Menu - Info Panel");
	OptionsMenuAddTimerText(client, menu);
	OptionsMenuAddSpeedText(client, menu);
	OptionsMenuAddShowingKeys(client, menu);
	OptionsMenuAddToggle(client, menu, Option_ShowingPlayers, "Options Menu - Show Players");
	OptionsMenuAddToggle(client, menu, Option_CheckpointMessages, "Options Menu - Checkpoint Messages");
	OptionsMenuAddToggle(client, menu, Option_CheckpointSounds, "Options Menu - Checkpoint Sounds");
	OptionsMenuAddToggle(client, menu, Option_TeleportSounds, "Options Menu - Teleport Sounds");
	OptionsMenuAddToggle(client, menu, Option_ErrorSounds, "Options Menu - Error Sounds");
	OptionsMenuAddToggle(client, menu, Option_ShowingWeapon, "Options Menu - Show Weapon");
	OptionsMenuAddPistol(client, menu);
	OptionsMenuAddToggle(client, menu, Option_AutoRestart, "Options Menu - Auto Restart");
	OptionsMenuAddToggle(client, menu, Option_SlayOnEnd, "Options Menu - Slay On End");
	OptionsMenuAddJumpBeam(client, menu);
}

static void OptionsMenuAddToggle(int client, Menu menu, Option option, const char[] optionPhrase)
{
	int optionValue = GetOption(client, option);
	char display[32];
	
	if (optionValue == 0)
	{
		FormatEx(display, sizeof(display), "%T - %T", 
			optionPhrase, client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(display, sizeof(display), "%T - %T", 
			optionPhrase, client, 
			"Options Menu - Enabled", client);
	}
	menu.AddItem(IntToStringEx(view_as<int>(option)), display);
}

static void OptionsMenuAddPistol(int client, Menu menu)
{
	char display[32];
	FormatEx(display, sizeof(display), "%T - %s", "Options Menu - Pistol", 
		client, pistolNames[GetOption(client, Option_Pistol)]);
	menu.AddItem(IntToStringEx(view_as<int>(Option_Pistol)), display);
}

static void OptionsMenuAddShowingKeys(int client, Menu menu)
{
	char display[32];
	FormatEx(display, sizeof(display), "%T - %T", 
		"Options Menu - Show Keys", client, 
		phrasesShowingKeys[GetOption(client, Option_ShowingKeys)], client);
	menu.AddItem(IntToStringEx(view_as<int>(Option_ShowingKeys)), display);
}

static void OptionsMenuAddTimerText(int client, Menu menu)
{
	char display[32];
	FormatEx(display, sizeof(display), "%T - %T", 
		"Options Menu - Timer Text", client, 
		phrasesTimerText[GetOption(client, Option_TimerText)], client);
	menu.AddItem(IntToStringEx(view_as<int>(Option_TimerText)), display);
}

static void OptionsMenuAddSpeedText(int client, Menu menu)
{
	char display[32];
	FormatEx(display, sizeof(display), "%T - %T", 
		"Options Menu - Speed Text", client, 
		phrasesSpeedText[GetOption(client, Option_SpeedText)], client);
	menu.AddItem(IntToStringEx(view_as<int>(Option_SpeedText)), display);
}

static void OptionsMenuAddJumpBeam(int client, Menu menu)
{
	char display[32];
	FormatEx(display, sizeof(display), "%T - %T", 
		"Options Menu - Jump Beam", client, 
		phrasesJumpBeam[GetOption(client, Option_JumpBeam)], client);
	menu.AddItem(IntToStringEx(view_as<int>(Option_JumpBeam)), display);
} 