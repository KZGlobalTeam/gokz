static TopMenu optionsTopMenu;
static TopMenuObject catJumpstats;
static TopMenuObject itemsJumpstats[JSOPTION_COUNT];



// =====[ PUBLIC ]=====

void DisplayJumpstatsOptionsMenu(int client)
{
	optionsTopMenu.DisplayCategory(catJumpstats, client);
}



// =====[ EVENTS ]=====

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (optionsTopMenu == topMenu && catJumpstats != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catJumpstats = topMenu.AddCategory(JS_OPTION_CATEGORY, TopMenuHandler_Categories);
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
		if (option == JSOption_JumpstatsMaster ||
			option == JSOption_ExtendedChatReport ||
			option == JSOption_FailstatsConsole ||
			option == JSOption_FailstatsChat ||
			option == JSOption_JumpstatsAlways)
		{
			FormatToggleableOptionDisplay(param, option, buffer, maxlength);
		}
		else
		{
			FormatDistanceTierOptionDisplay(param, option, buffer, maxlength);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_JS_CycleOption(param, option);
		optionsTopMenu.Display(param, TopMenuPosition_LastCategory);
	}
}



// =====[ PRIVATE ]=====

static void FormatToggleableOptionDisplay(int client, JSOption option, char[] buffer, int maxlength)
{
	if (GOKZ_JS_GetOption(client, option) == JSToggleOption_Disabled)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gI_JSOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gI_JSOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
}

static void FormatDistanceTierOptionDisplay(int client, JSOption option, char[] buffer, int maxlength)
{
	int optionValue = GOKZ_JS_GetOption(client, option);
	if (optionValue == DistanceTier_None) // Disabled
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gI_JSOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		// Add a plus sign to anything below the highest tier
		if (optionValue < DISTANCETIER_COUNT - 1)
		{
			FormatEx(buffer, maxlength, "%T - %s+", 
				gI_JSOptionPhrases[option], client, 
				gC_DistanceTiers[optionValue]);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %s", 
				gI_JSOptionPhrases[option], client, 
				gC_DistanceTiers[optionValue]);
		}
	}
}
