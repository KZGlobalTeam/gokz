/*
	Options
	
	Player options to customise their experience.
*/



#define OPTIONS_CFG_PATH "cfg/sourcemod/gokz/gokz-jumpstats-options.cfg"

static int defaultOptions[JSOPTION_COUNT];
static int options[JSOPTION_COUNT][MAXPLAYERS + 1];
static int optionCounts[JSOPTION_COUNT] = 
{
	JUMPSTATSMASTER_COUNT, 
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT
};



// =========================  PUBLIC  ========================= //

int GetOption(int client, JSOption option)
{
	return options[option][client];
}

void SetOption(int client, JSOption option, int optionValue, bool printMessage = false)
{
	// Special case for minimum sound tier - there is no sound for the 'Meh' tier
	if (option == JSOption_MinSoundTier && optionValue == DistanceTier_Meh)
	{
		optionValue = DistanceTier_Impressive;
	}
	
	// Don't need to do anything if their option is already set at that value
	if (GetOption(client, option) == optionValue)
	{
		return;
	}
	
	// Set the option otherwise
	options[option][client] = optionValue;
	if (printMessage)
	{
		PrintOptionChangeMessage(client, option);
	}
	
	Call_OnOptionChanged(client, option, optionValue);
}

void CycleOption(int client, JSOption option, bool printMessage = false)
{
	SetOption(client, option, (GetOption(client, option) + 1) % optionCounts[option], printMessage);
}

int GetDefaultOption(JSOption option)
{
	return defaultOptions[option];
}



// =========================  LISTENERS  ========================= //

void OnClientPutInServer_Options(int client)
{
	SetDefaultOptions(client);
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
	
	for (JSOption option; option < JSOPTION_COUNT; option++)
	{
		defaultOptions[option] = kv.GetNum(gC_KeysJSOptions[option]);
	}
}

static void SetDefaultOptions(int client)
{
	for (JSOption option; option < JSOPTION_COUNT; option++)
	{
		SetOption(client, option, GetDefaultOption(option));
	}
}

static void PrintOptionChangeMessage(int client, JSOption option)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	// NOTE: Not all options have a message for when they are changed.
	switch (option)
	{
		case JSOption_JumpstatsMaster:
		{
			switch (GetOption(client, option))
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