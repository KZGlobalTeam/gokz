/*
	Options
	
	Player options to customise their experience.
*/



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



// =========================  LISTENERS  ========================= //

void OnClientPutInServer_Options(int client)
{
	SetDefaultOptions(client);
}



// =========================  PRIVATE  ========================= //

static void SetDefaultOptions(int client)
{
	SetOption(client, JSOption_JumpstatsMaster, JumpstatsMaster_Enabled);
	SetOption(client, JSOption_MinChatTier, DistanceTier_Meh);
	SetOption(client, JSOption_MinConsoleTier, DistanceTier_Impressive);
	SetOption(client, JSOption_MinSoundTier, DistanceTier_Impressive);
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