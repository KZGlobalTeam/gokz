
// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (DBOption option; option < DBOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_DBOptionNames[option], gC_DBOptionDescriptions[option], 
			OptionType_Int, gI_DBOptionDefaultValues[option], 0, gI_DBOptionCounts[option] - 1);
	}
}



// =====[ OPTIONS MENU ]=====

TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemsDB[DBOPTION_COUNT];

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	gTMO_CatGeneral = gTM_Options.FindCategory(GENERAL_OPTION_CATEGORY);
	
	for (int option = 0; option < view_as<int>(DBOPTION_COUNT); option++)
	{
		gTMO_ItemsDB[option] = gTM_Options.AddItem(gC_DBOptionNames[option], TopMenuHandler_DB, gTMO_CatGeneral);
	}
}

public void TopMenuHandler_DB(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	DBOption option = DBOPTION_COUNT;
	for (int i = 0; i < view_as<int>(DBOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsDB[i])
		{
			option = view_as<DBOption>(i);
			break;
		}
	}
	
	if (option == DBOPTION_COUNT)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case DBOption_AutoLoadTimerSetup:
			{
				FormatToggleableOptionDisplay(param, DBOption_AutoLoadTimerSetup, buffer, maxlength);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, gC_DBOptionNames[option]);
		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
}

void FormatToggleableOptionDisplay(int client, DBOption option, char[] buffer, int maxlength)
{
	if (GOKZ_GetOption(client, gC_DBOptionNames[option]) == DBOption_Disabled)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_DBOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_DBOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
}
