/*
	TopMenu that allows users to browse categories of options.
	
	Adds core options to the general category where players
	can cycle the value of each core option.
*/



static TopMenu optionsMenu;
static TopMenuObject catGeneral;
static TopMenuObject itemsGeneral[OPTION_COUNT];
static bool cameFromOptionsMenu[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

void DisplayOptionsMenu(int client, TopMenuPosition position = TopMenuPosition_Start)
{
	optionsMenu.Display(client, position);
	cameFromOptionsMenu[client] = false;
}

TopMenu GetOptionsTopMenu()
{
	return optionsMenu;
}

bool GetCameFromOptionsMenu(int client)
{
	return cameFromOptionsMenu[client];
}



// =====[ LISTENERS ]=====

void OnAllPluginsLoaded_OptionsMenu()
{
	optionsMenu = new TopMenu(TopMenuHandler_Options);
	Call_GOKZ_OnOptionsMenuCreated(optionsMenu);
	Call_GOKZ_OnOptionsMenuReady(optionsMenu);
}

void OnConfigsExecuted_OptionsMenu()
{
	SortOptionsMenu();
}

void OnOptionsMenuCreated_OptionsMenu()
{
	catGeneral = optionsMenu.AddCategory(GENERAL_OPTION_CATEGORY, TopMenuHandler_Options);
}

void OnOptionsMenuReady_OptionsMenu()
{
	for (int option = 0; option < view_as<int>(OPTION_COUNT); option++)
	{
		if (option == view_as<int>(Option_Style))
		{
			continue; // TODO Currently hard-coded to skip style
		}
		itemsGeneral[option] = optionsMenu.AddItem(gC_CoreOptionNames[option], TopMenuHandler_General, catGeneral);
	}
}



// =====[ HANDLER ]=====

public void TopMenuHandler_Options(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == INVALID_TOPMENUOBJECT)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Title", param);
		}
		else if (topobj_id == catGeneral)
		{
			Format(buffer, maxlength, "%T", "Options Menu - General", param);
		}
	}
}

public void TopMenuHandler_General(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	Option option = OPTION_INVALID;
	for (int i = 0; i < view_as<int>(OPTION_COUNT); i++)
	{
		if (topobj_id == itemsGeneral[i])
		{
			option = view_as<Option>(i);
			break;
		}
	}
	
	if (option == OPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case Option_Mode:
			{
				FormatEx(buffer, maxlength, "%T - %s", 
					gC_CoreOptionPhrases[option], param, 
					gC_ModeNames[GOKZ_GetCoreOption(param, option)]);
			}
			case Option_TimerButtonZoneType:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_CoreOptionPhrases[option], param, 
					gC_TimerButtonZoneTypePhrases[GOKZ_GetCoreOption(param, option)], param);
			}
			case Option_Safeguard:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_CoreOptionPhrases[option], param, 
					gC_SafeGuardPhrases[GOKZ_GetCoreOption(param, option)], param);
			}
			default:FormatToggleableOptionDisplay(param, option, buffer, maxlength);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		switch (option)
		{
			case Option_Mode:
			{
				cameFromOptionsMenu[param] = true;
				DisplayModeMenu(param);
			}
			default:
			{
				GOKZ_CycleCoreOption(param, option);
				optionsMenu.Display(param, TopMenuPosition_LastCategory);
			}
		}
	}
}



// =====[ PRIVATE ]=====

static void SortOptionsMenu()
{
	char error[256];
	if (!optionsMenu.LoadConfig(GOKZ_CFG_OPTIONS_SORTING, error, sizeof(error)))
	{
		LogError("Failed to load file: \"%s\". Error: %s", GOKZ_CFG_OPTIONS_SORTING, error);
	}
}

static void FormatToggleableOptionDisplay(int client, Option option, char[] buffer, int maxlength)
{
	if (GOKZ_GetCoreOption(client, option) == 0)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_CoreOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_CoreOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
} 