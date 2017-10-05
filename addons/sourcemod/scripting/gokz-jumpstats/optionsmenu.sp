/*
	Options Menu
	
	Lets players view and set options.
*/



// =========================  PUBLIC  ========================= //

void DisplayOptionsMenu(int client, int atItem = 0)
{
	Menu menu = new Menu(MenuHandler_Options);
	menu.Pagination = 6;
	menu.SetTitle("%T", "Jumpstats Options Menu - Title", client);
	OptionsMenuAddItems(client, menu);
	menu.DisplayAt(client, atItem, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Options(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		JSOption option = view_as<JSOption>(StringToInt(info));
		
		CycleOption(param1, option, true);
		DisplayOptionsMenu(param1, param2 / 6 * 6);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

static void OptionsMenuAddItems(int client, Menu menu)
{
	OptionsMenuAddToggle(client, menu, JSOption_JumpstatsMaster, "Jumpstats Options Menu - Master Switch");
	OptionsMenuAddDistanceTier(client, menu, JSOption_MinChatTier, "Jumpstats Options Menu - Chat Report");
	OptionsMenuAddDistanceTier(client, menu, JSOption_MinConsoleTier, "Jumpstats Options Menu - Console Report");
	OptionsMenuAddDistanceTier(client, menu, JSOption_MinSoundTier, "Jumpstats Options Menu - Sounds");
}

static void OptionsMenuAddToggle(int client, Menu menu, JSOption option, const char[] optionPhrase)
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
	
	if (option != JSOption_JumpstatsMaster && GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled)
	{
		menu.AddItem(IntToStringEx(view_as<int>(option)), display, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem(IntToStringEx(view_as<int>(option)), display, ITEMDRAW_DEFAULT);
	}
}

static void OptionsMenuAddDistanceTier(int client, Menu menu, JSOption option, const char[] optionPhrase)
{
	int optionValue = GetOption(client, option);
	char display[32];
	if (optionValue == DistanceTier_None) // Disabled
	{
		FormatEx(display, sizeof(display), "%T - %T", 
			optionPhrase, client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		// Add a plus sign to anything below the highest tier
		if (optionValue < DISTANCETIER_COUNT - 1)
		{
			FormatEx(display, sizeof(display), "%T - %s+", optionPhrase, client, gC_DistanceTiers[optionValue]);
		}
		else
		{
			FormatEx(display, sizeof(display), "%T - %s", optionPhrase, client, gC_DistanceTiers[optionValue]);
		}
	}
	
	if (option != JSOption_JumpstatsMaster && GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled)
	{
		menu.AddItem(IntToStringEx(view_as<int>(option)), display, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem(IntToStringEx(view_as<int>(option)), display, ITEMDRAW_DEFAULT);
	}
} 