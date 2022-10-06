static StringMap optionData;
static StringMap optionDescriptions;



// =====[ PUBLIC ]=====

bool RegisterOption(const char[] name, const char[] description, OptionType type, any defaultValue, any minValue, any maxValue)
{
	if (!IsValueInRange(type, defaultValue, minValue, maxValue))
	{
		LogError("Failed to register option \"%s\" due to invalid default value and value range.", name);
		return false;
	}
	
	if (strlen(name) > GOKZ_OPTION_MAX_NAME_LENGTH - 1)
	{
		LogError("Failed to register option \"%s\" because its name is too long.", name);
		return false;
	}
	
	if (strlen(name) > GOKZ_OPTION_MAX_NAME_LENGTH - 1)
	{
		LogError("Failed to register option \"%s\" because its description is too long.", name);
		return false;
	}
	
	ArrayList data;
	Cookie cookie;
	if (IsRegisteredOption(name))
	{
		optionData.GetValue(name, data);
		cookie = GetOptionProp(name, OptionProp_Cookie);
	}
	else
	{
		data = new ArrayList(1, view_as<int>(OPTIONPROP_COUNT));
		cookie = new Cookie(name, description, CookieAccess_Private);
	}
	
	data.Set(view_as<int>(OptionProp_Cookie), cookie);
	data.Set(view_as<int>(OptionProp_Type), type);
	data.Set(view_as<int>(OptionProp_DefaultValue), defaultValue);
	data.Set(view_as<int>(OptionProp_MinValue), minValue);
	data.Set(view_as<int>(OptionProp_MaxValue), maxValue);
	
	optionData.SetValue(name, data, true);
	optionDescriptions.SetString(name, description, true);
	
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
	if (!optionData.GetValue(option, data))
	{
		LogError("Failed to get option property of unregistered option \"%s\".", option);
		return -1;
	}
	
	return data.Get(view_as<int>(prop));
}

bool SetOptionProp(const char[] option, OptionProp prop, any newValue)
{
	ArrayList data;
	if (!optionData.GetValue(option, data))
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
	return optionData.SetValue(option, data, true);
}

any GetOption(int client, const char[] option)
{
	if (!IsRegisteredOption(option))
	{
		LogError("Failed to get value of unregistered option \"%s\".", option);
		return -1;
	}
	
	Cookie cookie = GetOptionProp(option, OptionProp_Cookie);
	OptionType type = GetOptionProp(option, OptionProp_Type);
	char value[100];
	cookie.Get(client, value, sizeof(value));
	
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
	
	Cookie cookie = GetOptionProp(option, OptionProp_Cookie);
	cookie.Set(client, newValueString);
	
	if (IsClientInGame(client))
	{
		Call_GOKZ_OnOptionChanged(client, option, newValue);
	}
	
	return true;
}

bool IsRegisteredOption(const char[] option)
{
	int dummy;
	return optionData.GetValue(option, dummy);
}



// =====[ EVENTS ]=====

void OnPluginStart_Options()
{
	optionData = new StringMap();
	optionDescriptions = new StringMap();
	RegisterOptions();
}

void OnClientCookiesCached_Options(int client)
{
	StringMapSnapshot optionDataSnapshot = optionData.Snapshot();
	char option[GOKZ_OPTION_MAX_NAME_LENGTH];
	
	for (int i = 0; i < optionDataSnapshot.Length; i++)
	{
		optionDataSnapshot.GetKey(i, option, sizeof(option));
		LoadOption(client, option);
	}
	
	delete optionDataSnapshot;
	
	Call_GOKZ_OnOptionsLoaded(client);
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
	for (int client = 1; client <= MaxClients; client++)
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



// =====[ PRIVATE ]=====

static void RegisterOptions()
{
	for (Option option; option < OPTION_COUNT; option++)
	{
		RegisterOption(gC_CoreOptionNames[option], gC_CoreOptionDescriptions[option], 
			OptionType_Int, gI_CoreOptionDefaults[option], 0, gI_CoreOptionCounts[option] - 1);
	}
}

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

static void LoadOption(int client, const char[] option)
{
	char valueString[100];
	Cookie cookie = GetOptionProp(option, OptionProp_Cookie);
	cookie.Get(client, valueString, sizeof(valueString));
	
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

// Load default optionData from a config file, creating one and adding optionData if necessary
static void LoadDefaultOptions()
{
	KeyValues oldKV = new KeyValues(GOKZ_CFG_OPTIONS_ROOT);
	
	if (FileExists(GOKZ_CFG_OPTIONS) && !oldKV.ImportFromFile(GOKZ_CFG_OPTIONS))
	{
		LogError("Failed to load file: \"%s\".", GOKZ_CFG_OPTIONS);
		delete oldKV;
		return;
	}
	
	KeyValues newKV = new KeyValues(GOKZ_CFG_OPTIONS_ROOT); // This one will be sorted by option name
	StringMapSnapshot optionDataSnapshot = optionData.Snapshot();
	ArrayList optionDataSnapshotArray = new ArrayList(ByteCountToCells(GOKZ_OPTION_MAX_NAME_LENGTH), 0);
	char option[GOKZ_OPTION_MAX_NAME_LENGTH];
	char optionDescription[GOKZ_OPTION_MAX_DESC_LENGTH];
	
	// Sort the optionData by name
	for (int i = 0; i < optionDataSnapshot.Length; i++)
	{
		optionDataSnapshot.GetKey(i, option, sizeof(option));
		optionDataSnapshotArray.PushString(option);
	}
	SortADTArray(optionDataSnapshotArray, Sort_Ascending, Sort_String);
	
	// Get the values from the KeyValues, otherwise set them
	for (int i = 0; i < optionDataSnapshotArray.Length; i++)
	{
		oldKV.Rewind();
		newKV.Rewind();
		optionDataSnapshotArray.GetString(i, option, sizeof(option));
		optionDescriptions.GetString(option, optionDescription, sizeof(optionDescription));
		
		newKV.JumpToKey(option, true);
		newKV.SetString(GOKZ_CFG_OPTIONS_DESCRIPTION, optionDescription);
		
		OptionType type = GetOptionProp(option, OptionProp_Type);
		if (type == OptionType_Float)
		{
			if (oldKV.JumpToKey(option, false) && oldKV.JumpToKey(GOKZ_CFG_OPTIONS_DEFAULT, false))
			{
				oldKV.GoBack();
				newKV.SetFloat(GOKZ_CFG_OPTIONS_DEFAULT, oldKV.GetFloat(GOKZ_CFG_OPTIONS_DEFAULT));
				SetOptionProp(option, OptionProp_DefaultValue, oldKV.GetFloat(GOKZ_CFG_OPTIONS_DEFAULT));
			}
			else
			{
				newKV.SetFloat(GOKZ_CFG_OPTIONS_DEFAULT, GetOptionProp(option, OptionProp_DefaultValue));
			}
		}
		else if (type == OptionType_Int)
		{
			if (oldKV.JumpToKey(option, false) && oldKV.JumpToKey(GOKZ_CFG_OPTIONS_DEFAULT, false))
			{
				oldKV.GoBack();
				newKV.SetNum(GOKZ_CFG_OPTIONS_DEFAULT, oldKV.GetNum(GOKZ_CFG_OPTIONS_DEFAULT));
				SetOptionProp(option, OptionProp_DefaultValue, oldKV.GetNum(GOKZ_CFG_OPTIONS_DEFAULT));
			}
			else
			{
				newKV.SetNum(GOKZ_CFG_OPTIONS_DEFAULT, GetOptionProp(option, OptionProp_DefaultValue));
			}
		}
	}
	
	newKV.Rewind();
	newKV.ExportToFile(GOKZ_CFG_OPTIONS);
	
	delete oldKV;
	delete newKV;
	delete optionDataSnapshot;
	delete optionDataSnapshotArray;
}

static void PrintOptionChangeMessage(int client, Option option, int newValue)
{
	// NOTE: Not all optionData have a message for when they are changed.
	switch (option)
	{
		case Option_Mode:
		{
			GOKZ_PrintToChat(client, true, "%t", "Switched Mode", gC_ModeNames[newValue]);
		}
		case Option_VirtualButtonIndicators:
		{
			switch (newValue)
			{
				case VirtualButtonIndicators_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Virtual Button Indicators - Disable");
				}
				case VirtualButtonIndicators_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Virtual Button Indicators - Enable");
				}
			}
		}
		case Option_Safeguard:
		{
			switch (newValue)
			{
				case Safeguard_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Safeguard - Disable");
				}
				case Safeguard_EnabledNUB:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Safeguard - Enable (NUB)");
				}
				case Safeguard_EnabledPRO:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Safeguard - Enable (PRO)");
				}
			}
		}
	}
} 