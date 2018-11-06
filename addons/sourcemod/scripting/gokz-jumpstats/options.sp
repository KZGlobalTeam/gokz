/*
	Options for jumpstats, including an option to disable it completely.
*/



// =====[ PUBLIC ]=====

bool GetJumpstatsDisabled(int client)
{
	return GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JumpstatsMaster_Disabled
	 || (GOKZ_JS_GetOption(client, JSOption_MinChatTier) == DistanceTier_None
		 && GOKZ_JS_GetOption(client, JSOption_MinConsoleTier) == DistanceTier_None
		 && GOKZ_JS_GetOption(client, JSOption_MinSoundTier) == DistanceTier_None);
}



// =====[ EVENTS ]=====

void OnAllPluginsLoaded_Options()
{
	for (JSOption option; option < JSOPTION_COUNT; option++)
	{
		char prefixedDescription[255];
		FormatEx(prefixedDescription, sizeof(prefixedDescription), "%s%s", 
			JS_OPTION_DESC_PREFIX, 
			gC_JSOptionDescriptions[option]);
		GOKZ_RegisterOption(gC_JSOptionNames[option], prefixedDescription, 
			OptionType_Int, gI_JSOptionDefaults[option], 0, gI_JSOptionCounts[option] - 1);
	}
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

void OnMapStart_Options()
{
	LoadDefaultOptions();
}



// =====[ PRIVATE ]=====

static void LoadDefaultOptions()
{
	KeyValues kv = new KeyValues("options");
	
	if (!kv.ImportFromFile(JS_CFG_OPTIONS))
	{
		LogError("Failed to load file: \"%s\".", JS_CFG_OPTIONS);
		return;
	}
	
	for (JSOption option; option < JSOPTION_COUNT; option++)
	{
		GOKZ_SetOptionProp(gC_JSOptionNames[option], OptionProp_DefaultValue, kv.GetNum(gC_JSOptionNames[option]));
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
				case JumpstatsMaster_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Jumpstats Option - Master Switch - Enable");
				}
				case JumpstatsMaster_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Jumpstats Option - Master Switch - Disable");
				}
			}
		}
	}
} 