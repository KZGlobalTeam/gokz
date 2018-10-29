/*
	Options Menu
	
	Lets player set their gokz-jumpstats options.
*/



TopMenu optionsTopMenu;
TopMenuObject catJumpstats;
TopMenuObject itemsJumpstats[JSOPTION_COUNT];

static char optionDisplayPhrases[JSOPTION_COUNT][] = 
{
	"Options Menu - Jumpstats Master Switch", 
	"Options Menu - Jumpstats Chat Report", 
	"Options Menu - Jumpstats Console Report", 
	"Options Menu - Jumpstats Sounds", 
};



// =========================  LISTENERS  ========================= //

void OnAllPluginsLoaded_OptionsMenu()
{
	// Handle late loading
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (optionsTopMenu == topMenu && catJumpstats != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catJumpstats = topMenu.AddCategory(OPTIONS_MENU_CAT_JUMPSTATS, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (catJumpstats == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (optionsTopMenu == topMenu)
	{
		return;
	}
	
	optionsTopMenu = topMenu;
	
	// Add HUD option items	
	for (int option = 0; option < view_as<int>(JSOPTION_COUNT); option++)
	{
		itemsJumpstats[option] = optionsTopMenu.AddItem(gC_JSOptionNames[option], TopMenuHandler_HUD, catJumpstats);
	}
}



// =========================  HANDLER  ========================= //

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == catJumpstats)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Jumpstats", param);
		}
	}
}

public void TopMenuHandler_HUD(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	JSOption option = JSOPTION_INVALID;
	for (int i = 0; i < view_as<int>(JSOPTION_COUNT); i++)
	{
		if (topobj_id == itemsJumpstats[i])
		{
			option = view_as<JSOption>(i);
			break;
		}
	}
	
	if (option == JSOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case JSOption_JumpstatsMaster:FormatToggleableOptionDisplay(param, option, buffer, maxlength);
			default:FormatDistanceTierOptionDisplay(param, option, buffer, maxlength);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_JS_CycleOption(param, option);
		optionsTopMenu.Display(param, TopMenuPosition_LastCategory);
	}
}



// =========================  PRIVATE  ========================= //

static void FormatToggleableOptionDisplay(int client, JSOption option, char[] buffer, int maxlength)
{
	if (GOKZ_JS_GetOption(client, option) == 0)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			optionDisplayPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			optionDisplayPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
}

static void FormatDistanceTierOptionDisplay(int client, JSOption option, char[] buffer, int maxlength)
{
	int optionValue = GOKZ_JS_GetOption(client, option);
	if (optionValue == DistanceTier_None) // Disabled
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			optionDisplayPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		// Add a plus sign to anything below the highest tier
		if (optionValue < DISTANCETIER_COUNT - 1)
		{
			FormatEx(buffer, maxlength, "%T - %s+", 
				optionDisplayPhrases[option], client, 
				gC_DistanceTiers[optionValue]);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %s", 
				optionDisplayPhrases[option], client, 
				gC_DistanceTiers[optionValue]);
		}
	}
} 