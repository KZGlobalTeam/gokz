/*
	Options for jumpstats, including an option to disable it completely.
*/



// =====[ PUBLIC ]=====

bool GetJumpstatsDisabled(int client)
{
	return GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled
	 || (GOKZ_JS_GetOption(client, JSOption_MinChatTier) == DistanceTier_None
		 && GOKZ_JS_GetOption(client, JSOption_MinConsoleTier) == DistanceTier_None
		 && GOKZ_JS_GetOption(client, JSOption_MinSoundTier) == DistanceTier_None
		 && GOKZ_JS_GetOption(client, JSOption_FailstatsConsole) == JSToggleOption_Disabled
		 && GOKZ_JS_GetOption(client, JSOption_FailstatsChat) == JSToggleOption_Disabled
		 && GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled);
}



// =====[ EVENTS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void OnClientPutInServer_Options(int client)
{
	if (GOKZ_JS_GetOption(client, JSOption_MinSoundTier) == DistanceTier_Meh)
	{
		GOKZ_JS_SetOption(client, JSOption_MinSoundTier, DistanceTier_Impressive);
	}
}

void OnOptionChanged_Options(int client, const char[] option, any newValue)
{
	JSOption jsOption;
	if (GOKZ_JS_IsJSOption(option, jsOption))
	{
		if (jsOption == JSOption_MinSoundTier && newValue == DistanceTier_Meh)
		{
			GOKZ_JS_SetOption(client, JSOption_MinSoundTier, DistanceTier_Impressive);
		}
		else
		{
			PrintOptionChangeMessage(client, jsOption, newValue);
		}
	}
}



// =====[ PRIVATE ]=====

static void RegisterOptions()
{
	for (JSOption option; option < JSOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_JSOptionNames[option], gC_JSOptionDescriptions[option], 
			OptionType_Int, gI_JSOptionDefaults[option], 0, gI_JSOptionCounts[option] - 1);
	}
}

static void PrintOptionChangeMessage(int client, JSOption option, any newValue)
{
	// NOTE: Not all options have a message for when they are changed.
	switch (option)
	{
		case JSOption_JumpstatsMaster:
		{
			switch (newValue)
			{
				case JSToggleOption_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Jumpstats Option - Master Switch - Enable");
				}
				case JSToggleOption_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Jumpstats Option - Master Switch - Disable");
				}
			}
		}
	}
}
