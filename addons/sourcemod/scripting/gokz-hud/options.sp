/*
	Options for controlling appearance and behaviour of HUD and UI.
*/



// =====[ EVENTS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void OnOptionChanged_Options(int client, HUDOption option, any newValue)
{
	PrintOptionChangeMessage(client, option, newValue);
}



// =====[ PRIVATE ]=====

static void RegisterOptions()
{
	for (HUDOption option; option < HUDOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_HUDOptionNames[option], gC_HUDOptionDescriptions[option], 
			OptionType_Int, gI_HUDOptionDefaults[option], 0, gI_HUDOptionCounts[option] - 1);
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
		case HUDOption_TimerStyle:
		{
			switch (newValue)
			{
				case TimerStyle_Standard:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Timer Style - Standard");
				}
				case TimerStyle_Precise:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Timer Style - Precise");
				}
			}
		}
		case HUDOption_TimerType:
		{
			switch (newValue)
			{
				case TimerType_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Timer Type - Disabled");
				}
				case TimerType_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Timer Type - Enabled");
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
		case HUDOption_ShowControls:
		{
			switch (newValue)
			{
				case ReplayControls_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Controls - Disable");
				}
				case ReplayControls_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Controls - Enable");
				}
			}
		}
		case HUDOption_DeadstrafeColor:
		{
			switch (newValue)
			{
				case DeadstrafeColor_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Dead Strafe - Disable");
				}
				case DeadstrafeColor_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Dead Strafe - Enable");
				}
			}
		}
		case HUDOption_ShowSpectators:
		{
			switch (newValue)
			{
				case ShowSpecs_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Spectators - Disable");
				}
				case ShowSpecs_Number:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Spectators - Number");
				}
				case ShowSpecs_Full:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Spectators - Full");
				}
			}
		}
	}
} 