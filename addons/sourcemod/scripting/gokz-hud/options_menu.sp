/*
	Options Menu
	
	Lets player set their gokz-hud options.
*/



TopMenu optionsTopMenu;
TopMenuObject catHUD;
TopMenuObject itemsHUD[HUDOPTION_COUNT];

static char optionDisplayPhrases[HUDOPTION_COUNT][] = 
{
	"Options Menu - Teleport Menu", 
	"Options Menu - Info Panel", 
	"Options Menu - Show Keys", 
	"Options Menu - Timer Text", 
	"Options Menu - Speed Text"
};

static char phrasesTPMenu[TPMENU_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Simple", 
	"Options Menu - Advanced"
};

static char phrasesShowKeys[SHOWKEYS_COUNT][] = 
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
	if (optionsTopMenu == topMenu && catHUD != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catHUD = topMenu.AddCategory(OPTIONS_MENU_CAT_HUD, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (catHUD == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (optionsTopMenu == topMenu)
	{
		return;
	}
	
	optionsTopMenu = topMenu;
	
	// Add HUD option items	
	for (int option = 0; option < view_as<int>(HUDOPTION_COUNT); option++)
	{
		itemsHUD[option] = optionsTopMenu.AddItem(gC_HUDOptionNames[option], TopMenuHandler_HUD, catHUD);
	}
}



// =========================  HANDLER  ========================= //

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == catHUD)
		{
			Format(buffer, maxlength, "%T", "Options Menu - HUD", param);
		}
	}
}

public void TopMenuHandler_HUD(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	HUDOption option = HUDOPTION_INVALID;
	for (int i = 0; i < view_as<int>(HUDOPTION_COUNT); i++)
	{
		if (topobj_id == itemsHUD[i])
		{
			option = view_as<HUDOption>(i);
			break;
		}
	}
	
	if (option == HUDOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case HUDOption_TPMenu:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					optionDisplayPhrases[option], param, 
					phrasesTPMenu[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_ShowKeys:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					optionDisplayPhrases[option], param, 
					phrasesShowKeys[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_TimerText:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					optionDisplayPhrases[option], param, 
					phrasesTimerText[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_SpeedText:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					optionDisplayPhrases[option], param, 
					phrasesSpeedText[GOKZ_HUD_GetOption(param, option)], param);
			}
			default:FormatToggleableOptionDisplay(param, option, buffer, maxlength);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_HUD_CycleOption(param, option);
		optionsTopMenu.Display(param, TopMenuPosition_LastCategory);
	}
}



// =========================  PRIVATE  ========================= //

static void FormatToggleableOptionDisplay(int client, HUDOption option, char[] buffer, int maxlength)
{
	if (GOKZ_HUD_GetOption(client, option) == 0)
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