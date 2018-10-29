/*
	Options
	
	Player options to customise their experience.
*/



#define OPTION_DESCRIPTION_PREFIX "HUD - "
#define OPTIONS_CFG_PATH "cfg/sourcemod/gokz/gokz-hud-options.cfg"

static const int defaultDefaultValues[HUDOPTION_COUNT] = 
{
	TPMenu_Simple, 
	InfoPanel_Enabled, 
	ShowKeys_Spectating, 
	TimerText_InfoPanel, 
	SpeedText_InfoPanel, 
	ShowWeapon_Enabled
};

static const int optionCounts[HUDOPTION_COUNT] = 
{
	TPMENU_COUNT, 
	INFOPANEL_COUNT, 
	SHOWKEYS_COUNT, 
	TIMERTEXT_COUNT, 
	SPEEDTEXT_COUNT, 
	SHOWWEAPON_COUNT
};

static const char optionDescription[HUDOPTION_COUNT][] = 
{
	"Teleport menu", 
	"Info panel", 
	"Show keys", 
	"Timer text", 
	"Speed text", 
	"Show weapon"
};



// =========================  LISTENERS  ========================= //

void OnAllPluginsLoaded_Options()
{
	for (HUDOption option; option < HUDOPTION_COUNT; option++)
	{
		char prefixedDescription[255];
		FormatEx(prefixedDescription, sizeof(prefixedDescription), "%s%s", 
			OPTION_DESCRIPTION_PREFIX, 
			optionDescription[option]);
		GOKZ_RegisterOption(gC_HUDOptionNames[option], prefixedDescription, 
			OptionType_Int, defaultDefaultValues[option], 0, optionCounts[option] - 1);
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



// =========================  PRIVATE  ========================= //

static void LoadDefaultOptions()
{
	KeyValues kv = new KeyValues("options");
	
	if (!kv.ImportFromFile(OPTIONS_CFG_PATH))
	{
		LogError("Could not read default options config file: %s", OPTIONS_CFG_PATH);
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