
// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (ProfileOption option; option < PROFILEOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_ProfileOptionNames[option], gC_ProfileOptionDescriptions[option], 
			OptionType_Int, gI_ProfileOptionDefaults[option], 0, gI_ProfileOptionCounts[option] - 1);
	}
}



// =====[ OPTIONS MENU ]=====

TopMenu gTM_Options;
TopMenuObject gTMO_CatProfile;
TopMenuObject gTMO_ItemsProfile[PROFILEOPTION_COUNT];

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu && gTMO_CatProfile != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	gTMO_CatProfile = topMenu.AddCategory(PROFILE_OPTION_CATEGORY, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (gTMO_CatProfile == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	
	// Add gokz-profile option items	
	for (int option = 0; option < view_as<int>(PROFILEOPTION_COUNT); option++)
	{
		gTMO_ItemsProfile[option] = gTM_Options.AddItem(gC_ProfileOptionNames[option], TopMenuHandler_Profile, gTMO_CatProfile);
	}
}

void DisplayProfileOptionsMenu(int client)
{
	if (gTMO_CatProfile != INVALID_TOPMENUOBJECT)
	{
		gTM_Options.DisplayCategory(gTMO_CatProfile, client);
	}
}

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == gTMO_CatProfile)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Profile", param);
		}
	}
}

public void TopMenuHandler_Profile(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	ProfileOption option = PROFILEOPTION_INVALID;
	for (int i = 0; i < view_as<int>(PROFILEOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsProfile[i])
		{
			option = view_as<ProfileOption>(i);
			break;
		}
	}
	
	if (option == PROFILEOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		if (option == ProfileOption_TagType)
		{
			FormatEx(buffer, maxlength, "%T - %T",
					gC_ProfileOptionPhrases[option], param,
					gC_ProfileTagTypePhrases[GOKZ_GetOption(param, gC_ProfileOptionNames[option])], param);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %T",
					gC_ProfileOptionPhrases[option], param,
					gC_ProfileBoolPhrases[GOKZ_GetOption(param, gC_ProfileOptionNames[option])], param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, gC_ProfileOptionNames[option]);

		if (option == ProfileOption_TagType)
		{
			for (int i = 0; i < PROFILETAGTYPE_COUNT; i++)
			{
				int tagType = GOKZ_GetOption(param, gC_ProfileOptionNames[option]);
				if (!CanUseTagType(param, tagType))
				{
					GOKZ_CycleOption(param, gC_ProfileOptionNames[option]);
				}
			}
		}

		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
}

