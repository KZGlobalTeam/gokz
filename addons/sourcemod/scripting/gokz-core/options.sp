/*
	Options
	
	Player options to customise their experience.
*/



#define OPTION_DESCRIPTION_PREFIX "GOKZ - "
#define OPTIONS_CFG_PATH "cfg/sourcemod/gokz/gokz-core-options.cfg"

static StringMap options;

static const int defaultDefaultValues[OPTION_COUNT] = 
{
	Mode_SimpleKZ, 
	Style_Normal, 
	ShowingPlayers_Enabled, 
	AutoRestart_Disabled, 
	SlayOnEnd_Disabled, 
	CheckpointMessages_Disabled, 
	CheckpointSounds_Enabled, 
	TeleportSounds_Disabled, 
	ErrorSounds_Enabled
};

static const int optionCounts[OPTION_COUNT] = 
{
	MODE_COUNT, 
	STYLE_COUNT, 
	SHOWINGPLAYERS_COUNT, 
	AUTORESTART_COUNT, 
	SLAYONEND_COUNT, 
	CHECKPOINTMESSAGES_COUNT, 
	CHECKPOINTSOUNDS_COUNT, 
	TELEPORTSOUNDS_COUNT, 
	ERRORSOUNDS_COUNT
};

static const char optionDescription[OPTION_COUNT][] = 
{
	"Movement mode", 
	"Movement style", 
	"Other player visibility", 
	"Automatic timer restart upon teleport to start", 
	"Automatic slay upon end", 
	"Checkpoint messages", 
	"Checkpoint sounds", 
	"Teleport sounds", 
	"Error sounds"
};



// =========================  PUBLIC  ========================= //

void CreateOptions()
{
	options = new StringMap();
	
	for (Option option; option < OPTION_COUNT; option++)
	{
		RegisterOption(gC_CoreOptionNames[option], optionDescription[option], 
			OptionType_Int, defaultDefaultValues[option], 0, optionCounts[option] - 1);
	}
}

bool RegisterOption(const char[] name, const char[] description, OptionType type, any defaultValue, any minValue, any maxValue)
{
	if (!IsValueInRange(type, defaultValue, minValue, maxValue))
	{
		LogError("Failed to register option \"%s\" due to invalid default value and value range.", name);
		return false;
	}
	
	char prefixedDescription[255];
	FormatEx(prefixedDescription, sizeof(prefixedDescription), "%s%s", 
		OPTION_DESCRIPTION_PREFIX, 
		description);
	
	Handle cookie = IsRegisteredOption(name) ? GetOptionProp(name, OptionProp_Cookie)
	 : RegClientCookie(name, prefixedDescription, CookieAccess_Protected);
	
	// I seriously couldn't work out a prettier way of using the enum values
	ArrayList data = new ArrayList(1, view_as<int>(OPTIONPROP_COUNT));
	data.Set(view_as<int>(OptionProp_Cookie), cookie);
	data.Set(view_as<int>(OptionProp_Type), type);
	data.Set(view_as<int>(OptionProp_DefaultValue), defaultValue);
	data.Set(view_as<int>(OptionProp_MinValue), minValue);
	data.Set(view_as<int>(OptionProp_MaxValue), maxValue);
	
	if (!options.SetValue(name, data, true))
	{
		return false;
	}
	
	// Support late-loading/registering
	for (int client = 1; client <= MaxClients; client++)
	{
		if (AreClientCookiesCached(client))
		{
			LoadOption(client, name);
		}
	}
	
	return true;
}

any GetOptionProp(const char[] option, OptionProp prop)
{
	ArrayList data;
	if (!options.GetValue(option, data))
	{
		LogError("Failed to get option property of unregistered option \"%s\".", option);
		return -1;
	}
	
	return data.Get(view_as<int>(prop));
}

bool SetOptionProp(const char[] option, OptionProp prop, any newValue)
{
	ArrayList data;
	if (!options.GetValue(option, data))
	{
		LogError("Failed to set property of unregistered option \"%s\".", option);
		return false;
	}
	
	if (prop == OptionProp_Cookie)
	{
		LogError("Failed to set cookie of option \"%s\" as it is read-only.");
		return false;
	}
	
	OptionType type = GetOptionProp(option, OptionProp_Type);
	any defaultValue = GetOptionProp(option, OptionProp_DefaultValue);
	any minValue = GetOptionProp(option, OptionProp_MinValue);
	any maxValue = GetOptionProp(option, OptionProp_MaxValue);
	
	switch (prop)
	{
		case OptionProp_DefaultValue:
		{
			if (!IsValueInRange(type, newValue, minValue, maxValue))
			{
				LogError("Failed to set default value of option \"%s\" due to invalid default value and value range.", option);
				return false;
			}
		}
		case OptionProp_MinValue:
		{
			if (!IsValueInRange(type, defaultValue, newValue, maxValue))
			{
				LogError("Failed to set minimum value of option \"%s\" due to invalid default value and value range.", option);
				return false;
			}
		}
		case OptionProp_MaxValue:
		{
			if (!IsValueInRange(type, defaultValue, minValue, newValue))
			{
				LogError("Failed to set maximum value of option \"%s\" due to invalid default value and value range.", option);
				return false;
			}
		}
	}
	
	data.Set(view_as<int>(prop), newValue);
	return options.SetValue(option, data, true);
}

any GetOption(int client, const char[] option)
{
	if (!IsRegisteredOption(option))
	{
		LogError("Failed to get value of unregistered option \"%s\".", option);
		return -1;
	}
	
	Handle cookie = GetOptionProp(option, OptionProp_Cookie);
	OptionType type = GetOptionProp(option, OptionProp_Type);
	char value[100];
	GetClientCookie(client, cookie, value, sizeof(value));
	
	if (type == OptionType_Float)
	{
		return StringToFloat(value);
	}
	else //if (type == OptionType_Int)
	{
		return StringToInt(value);
	}
}

bool SetOption(int client, const char[] option, any newValue)
{
	if (!IsRegisteredOption(option))
	{
		LogError("Failed to set value of unregistered option \"%s\".", option);
		return false;
	}
	
	if (GetOption(client, option) == newValue)
	{
		return true;
	}
	
	OptionType type = GetOptionProp(option, OptionProp_Type);
	any minValue = GetOptionProp(option, OptionProp_MinValue);
	any maxValue = GetOptionProp(option, OptionProp_MaxValue);
	
	if (!IsValueInRange(type, newValue, minValue, maxValue))
	{
		LogError("Failed to set value of option \"%s\" because desired value was outside registered value range.", option);
		return false;
	}
	
	char newValueString[100];
	if (type == OptionType_Float)
	{
		FloatToString(newValue, newValueString, sizeof(newValueString));
	}
	else //if (type == OptionType_Int)
	{
		IntToString(newValue, newValueString, sizeof(newValueString));
	}
	
	Handle cookie = GetOptionProp(option, OptionProp_Cookie);
	SetClientCookie(client, cookie, newValueString);
	
	if (IsClientInGame(client))
	{
		Call_GOKZ_OnOptionChanged(client, option, newValue);
	}
	
	return true;
}

bool IsRegisteredOption(const char[] option)
{
	int dummy;
	return options.GetValue(option, dummy);
}



// =========================  LISTENERS  ========================= //

void OnClientCookiesCached_Options(int client)
{
	StringMapSnapshot snapshot = options.Snapshot();
	char option[30];
	
	for (int i = 0; i < snapshot.Length; i++)
	{
		snapshot.GetKey(i, option, sizeof(option));
		LoadOption(client, option);
	}
}

void OnClientPutInServer_Options(int client)
{
	if (!GetModeLoaded(GOKZ_GetCoreOption(client, Option_Mode)))
	{
		GOKZ_SetCoreOption(client, Option_Mode, GetALoadedMode());
	}
}

void OnOptionChanged_Options(int client, Option option, int newValue)
{
	if (option == Option_Mode && !GetModeLoaded(newValue))
	{
		GOKZ_PrintToChat(client, true, "%t", "Mode Not Available", newValue);
		GOKZ_SetCoreOption(client, Option_Mode, GetALoadedMode());
	}
	else
	{
		PrintOptionChangeMessage(client, option, newValue);
	}
}

void OnModeUnloaded_Options(int mode)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsClientInGame(client) && GOKZ_GetCoreOption(client, Option_Mode) == mode)
		{
			GOKZ_SetCoreOption(client, Option_Mode, GetALoadedMode());
		}
	}
}

void OnMapStart_Options()
{
	LoadDefaultOptions();
}



// =========================  PRIVATE  ========================= //

static bool IsValueInRange(OptionType type, any value, any minValue, any maxValue)
{
	if (type == OptionType_Float)
	{
		return FloatCompare(minValue, value) <= 0 && FloatCompare(value, maxValue) <= 0;
	}
	else //if (type == OptionType_Int)
	{
		return minValue <= value && value <= maxValue;
	}
}

static bool LoadOption(int client, const char[] option)
{
	char valueString[100];
	Handle cookie = GetOptionProp(option, OptionProp_Cookie);
	GetClientCookie(client, cookie, valueString, sizeof(valueString));
	
	// If there's no stored value for the option, set it to default
	if (valueString[0] == '\0')
	{
		SetOption(client, option, GetOptionProp(option, OptionProp_DefaultValue));
		return;
	}
	
	OptionType type = GetOptionProp(option, OptionProp_Type);
	any minValue = GetOptionProp(option, OptionProp_MinValue);
	any maxValue = GetOptionProp(option, OptionProp_MaxValue);
	any value;
	
	// If stored option isn't a valid float or integer, or is out of range, set it to default
	if (type == OptionType_Float && StringToFloatEx(valueString, value) == 0)
	{
		SetOption(client, option, GetOptionProp(option, OptionProp_DefaultValue));
	}
	else if (type == OptionType_Int && StringToIntEx(valueString, value) == 0)
	{
		SetOption(client, option, GetOptionProp(option, OptionProp_DefaultValue));
	}
	else if (!IsValueInRange(type, value, minValue, maxValue))
	{
		SetOption(client, option, GetOptionProp(option, OptionProp_DefaultValue));
	}
}

static void LoadDefaultOptions()
{
	KeyValues kv = new KeyValues("options");
	
	if (!kv.ImportFromFile(OPTIONS_CFG_PATH))
	{
		LogError("Could not read default options config file: %s", OPTIONS_CFG_PATH);
		return;
	}
	
	for (Option option; option < OPTION_COUNT; option++)
	{
		GOKZ_SetOptionProp(gC_CoreOptionNames[option], OptionProp_DefaultValue, kv.GetNum(gC_CoreOptionNames[option]));
	}
}

static void PrintOptionChangeMessage(int client, Option option, int newValue)
{
	// NOTE: Not all options have a message for when they are changed.
	switch (option)
	{
		case Option_Mode:
		{
			GOKZ_PrintToChat(client, true, "%t", "Switched Mode", gC_ModeNames[newValue]);
		}
		case Option_ShowingPlayers:
		{
			switch (newValue)
			{
				case ShowingPlayers_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Disable");
				}
				case ShowingPlayers_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Enable");
				}
			}
		}
		case Option_AutoRestart:
		{
			switch (newValue)
			{
				case AutoRestart_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Auto Restart - Disable");
				}
				case AutoRestart_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Auto Restart - Enable");
				}
			}
		}
		case Option_SlayOnEnd:
		{
			switch (newValue)
			{
				case SlayOnEnd_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Slay On End - Disable");
				}
				case SlayOnEnd_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Slay On End - Enable");
				}
			}
		}
	}
} 