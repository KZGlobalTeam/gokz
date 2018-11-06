/*
	Options for controlling appearance and behaviour of HUD and UI.
*/



// =====[ EVENTS ]=====

void OnAllPluginsLoaded_Options()
{
	char prefixedDescription[255];
	for (HUDOption option; option < HUDOPTION_COUNT; option++)
	{
		FormatEx(prefixedDescription, sizeof(prefixedDescription), "%s%s", 
			HUD_OPTION_DESC_PREFIX, 
			gC_HUDOptionDescriptions[option]);
		GOKZ_RegisterOption(gC_HUDOptionNames[option], prefixedDescription, 
			OptionType_Int, gI_HUDOptionDefaults[option], 0, gI_HUDOptionCounts[option] - 1);
	}
}

void OnOptionChanged_Options(int client, HUDOption option, any newValue)
{
	PrintOptionChangeMessage(client, option, newValue);
}

void OnMapStart_Options()
{
	LoadDefaultOptions();
}



// =====[ PRIVATE ]=====

static void LoadDefaultOptions()
{
	KeyValues kv = new KeyValues("options");
	
	if (!kv.ImportFromFile(HUD_CFG_OPTIONS))
	{
		LogError("Failed to load file: \"%s\".", HUD_CFG_OPTIONS);
		return;
	}
	
	for (HUDOption option; option < HUDOPTION_COUNT; option++)
	{
		GOKZ_SetOptionProp(gC_HUDOptionNames[option], OptionProp_DefaultValue, kv.GetNum(gC_HUDOptionNames[option]));
	}
}

static void PrintOptionChangeMessage(int client, HUDOption option, any newValue)
{
	// NOTE: Not all options have a message for when they are changed.
	switch (option)
	{
		case HUDOption_TPMenu:
		{
			switch (newValue)
			{
				case TPMenu_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Teleport Menu - Disable");
				}
				case TPMenu_Simple:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Teleport Menu - Enable (Simple)");
				}
				case TPMenu_Advanced:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Teleport Menu - Enable (Advanced)");
				}
			}
		}
		case HUDOption_InfoPanel:
		{
			switch (newValue)
			{
				case InfoPanel_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Info Panel - Disable");
				}
				case InfoPanel_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Info Panel - Enable");
				}
			}
		}
		case HUDOption_ShowWeapon:
		{
			switch (newValue)
			{
				case ShowWeapon_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Weapon - Disable");
				}
				case ShowWeapon_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Weapon - Enable");
				}
			}
		}
	}
} 