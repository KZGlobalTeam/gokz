// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (QTOption option; option < QTOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_QTOptionNames[option], gC_QTOptionDescriptions[option], 
			OptionType_Int, gI_QTOptionDefaultValues[option], 0, gI_QTOptionCounts[option] - 1);
	}
}

void OnOptionChanged_Options(int client, QTOption option, any newValue)
{
	if (option == QTOption_Soundscapes && newValue == Soundscapes_Enabled)
	{
		EnableSoundscape(client);
	}
	PrintOptionChangeMessage(client, option, newValue);
}

void PrintOptionChangeMessage(int client, QTOption option, any newValue)
{
	switch (option)
	{
		case QTOption_ShowPlayers:
		{
			switch (newValue)
			{
				case ShowPlayers_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Disable");
				}
				case ShowPlayers_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Enable");
				}
			}
		}
		case QTOption_Soundscapes:
		{
			switch (newValue)
			{
				case Soundscapes_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Soundscapes - Disable");
				}
				case Soundscapes_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Soundscapes - Enable");
				}
			}
		}
	}
}

// =====[ OPTIONS MENU ]=====

TopMenu gTM_Options;
TopMenuObject gTMO_CatQuiet;
TopMenuObject gTMO_ItemsQuiet[QTOPTION_COUNT];

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu && gTMO_CatQuiet != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	gTMO_CatQuiet = topMenu.AddCategory(QUIET_OPTION_CATEGORY, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (gTMO_CatQuiet == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	
	// Add gokz-profile option items	
	for (int option = 0; option < view_as<int>(QTOPTION_COUNT); option++)
	{
		gTMO_ItemsQuiet[option] = gTM_Options.AddItem(gC_QTOptionNames[option], TopMenuHandler_QT, gTMO_CatQuiet);
	}
}

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == gTMO_CatQuiet)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Quiet", param);
		}
	}
}

public void TopMenuHandler_QT(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	QTOption option = QTOPTION_INVALID;
	for (int i = 0; i < view_as<int>(QTOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsQuiet[i])
		{
			option = view_as<QTOption>(i);
			break;
		}
	}
	
	if (option == QTOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case QTOption_ShowPlayers:
			{
				FormatToggleableOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_Soundscapes:
			{
				FormatToggleableOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_FallDamageSound:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_AmbientSounds:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_CheckpointVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_TeleportVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_TimerVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_ErrorVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_ServerRecordVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_WorldRecordVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
			case QTOption_JumpstatsVolume:
			{
				FormatVolumeOptionDisplay(param, option, buffer, maxlength);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, gC_QTOptionNames[option]);
		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
}

void FormatToggleableOptionDisplay(int client, QTOption option, char[] buffer, int maxlength)
{
	if (GOKZ_GetOption(client, gC_QTOptionNames[option]) == 0)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_QTOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_QTOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
}

void FormatVolumeOptionDisplay(int client, QTOption option, char[] buffer, int maxlength)
{
	// Assume 10% volume steps.
	FormatEx(buffer, maxlength, "%T - %i%", 
		gC_QTOptionPhrases[option], client, 
		GOKZ_QT_GetOption(client, option) * 10);
}