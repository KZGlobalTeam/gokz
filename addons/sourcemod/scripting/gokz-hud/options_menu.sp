static TopMenu optionsTopMenu;
static TopMenuObject catHUD;
static TopMenuObject itemsHUD[HUDOPTION_COUNT];



// =====[ EVENTS ]=====

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (optionsTopMenu == topMenu && catHUD != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catHUD = topMenu.AddCategory(HUD_OPTION_CATEGORY, TopMenuHandler_Categories);
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
					gC_HUDOptionPhrases[option], param, 
					gC_TPMenuPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_ShowKeys:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_HUDOptionPhrases[option], param, 
					gC_ShowKeysPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_TimerText:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_HUDOptionPhrases[option], param, 
					gC_TimerTextPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_TimerStyle:
			{
				int optionValue = GOKZ_HUD_GetOption(param, option);
				if (optionValue == TimerStyle_Precise)
				{
					FormatEx(buffer, maxlength, "%T - 01:23.45", 
						gC_HUDOptionPhrases[option], param);
				}
				else
				{
					FormatEx(buffer, maxlength, "%T - 1:23", 
						gC_HUDOptionPhrases[option], param);
				}
			}
			case HUDOption_TimerType:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_HUDOptionPhrases[option], param,
					gC_TimerTypePhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_SpeedText:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_HUDOptionPhrases[option], param, 
					gC_SpeedTextPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_ShowControls:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_HUDOptionPhrases[option], param,
					gC_ShowControlsPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_DeadstrafeColor:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_HUDOptionPhrases[option], param, 
					gC_DeadstrafeColorPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_UpdateRate:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_HUDOptionPhrases[option], param,
					gC_HUDUpdateRatePhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_ShowSpectators:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_HUDOptionPhrases[option], param,
					gC_ShowSpecsPhrases[GOKZ_HUD_GetOption(param, option)], param);
			}
			case HUDOption_DynamicMenu:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_HUDOptionPhrases[option], param,
					gC_DynamicMenuPhrases[GOKZ_HUD_GetOption(param, option)], param);
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



// =====[ PRIVATE ]=====

static void FormatToggleableOptionDisplay(int client, HUDOption option, char[] buffer, int maxlength)
{
	if (GOKZ_HUD_GetOption(client, option) == 0)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_HUDOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_HUDOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
} 