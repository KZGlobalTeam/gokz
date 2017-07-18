/*
	Options Menu
	
	Lets players view and set options.
*/



static Menu optionsMenu[MAXPLAYERS + 1];
static bool cameFromOptionsMenu[MAXPLAYERS + 1];

static char PhrasesShowingKeys[SHOWINGKEYS_COUNT][] = 
{
	"Options Menu - Spectating", 
	"Options Menu - Always", 
	"Options Menu - Disabled"
};

static char PhrasesTimerText[TIMERTEXT_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Info Panel", 
	"Options Menu - Bottom", 
	"Options Menu - Top"
};

static char PhrasesSpeedText[SPEEDTEXT_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Info Panel", 
	"Options Menu - Bottom"
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

void CreateMenusOptions()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		optionsMenu[client] = new Menu(MenuHandler_Options);
		optionsMenu[client].Pagination = 6;
	}
}

void DisplayOptionsMenu(int client, int atItem = 0)
{
	OptionsMenuUpdate(client, optionsMenu[client]);
	optionsMenu[client].DisplayAt(client, atItem, MENU_TIME_FOREVER);
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
		switch (param2)
		{
			case 0:CycleOption(param1, Option_ShowingTPMenu);
			case 1:CycleOption(param1, Option_ShowingInfoPanel);
			case 2:CycleOption(param1, Option_TimerText);
			case 3:CycleOption(param1, Option_SpeedText);
			case 4:CycleOption(param1, Option_ShowingKeys);
			case 5:CycleOption(param1, Option_ShowingPlayers);
			case 6:CycleOption(param1, Option_CheckpointMessages);
			case 7:CycleOption(param1, Option_CheckpointSounds);
			case 8:CycleOption(param1, Option_TeleportSounds);
			case 9:CycleOption(param1, Option_ErrorSounds);
			case 10:CycleOption(param1, Option_ShowingWeapon);
			case 11:
			{
				cameFromOptionsMenu[param1] = true;
				DisplayPistolMenu(param1);
			}
			case 12:CycleOption(param1, Option_AutoRestart, true);
			case 13:CycleOption(param1, Option_SlayOnEnd, true);
		}
		if (param2 != 11) // Pistol
		{
			// Reopen the menu at the same place
			DisplayOptionsMenu(param1, param2 / 6 * 6);
		}
	}
}



// =========================  PRIVATE  ========================= //

static void OptionsMenuUpdate(int client, Menu menu)
{
	menu.SetTitle("%T", "Options Menu - Title", client);
	menu.RemoveAllItems();
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
}

static void OptionsMenuAddToggle(int client, Menu menu, Option option, const char[] optionPhrase)
{
	int optionValue = GetOption(client, option);
	char temp[32];
	if (view_as<int>(optionValue) == 0)
	{
		FormatEx(temp, sizeof(temp), "%T - %T", 
			optionPhrase, client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(temp, sizeof(temp), "%T - %T", 
			optionPhrase, client, 
			"Options Menu - Enabled", client);
	}
	menu.AddItem("", temp);
}

static void OptionsMenuAddPistol(int client, Menu menu)
{
	char temp[32];
	FormatEx(temp, sizeof(temp), "%T - %s", "Options Menu - Pistol", 
		client, pistolNames[GetOption(client, Option_Pistol)]);
	menu.AddItem("", temp);
}

static void OptionsMenuAddShowingKeys(int client, Menu menu)
{
	char temp[32];
	FormatEx(temp, sizeof(temp), "%T - %T", 
		"Options Menu - Show Keys", client, 
		PhrasesShowingKeys[GetOption(client, Option_ShowingKeys)], client);
	menu.AddItem("", temp);
}

static void OptionsMenuAddTimerText(int client, Menu menu)
{
	char temp[32];
	FormatEx(temp, sizeof(temp), "%T - %T", 
		"Options Menu - Timer Text", client, 
		PhrasesTimerText[GetOption(client, Option_TimerText)], client);
	menu.AddItem("", temp);
}

static void OptionsMenuAddSpeedText(int client, Menu menu)
{
	char temp[32];
	FormatEx(temp, sizeof(temp), "%T - %T", 
		"Options Menu - Speed Text", client, 
		PhrasesSpeedText[GetOption(client, Option_SpeedText)], client);
	menu.AddItem("", temp);
} 