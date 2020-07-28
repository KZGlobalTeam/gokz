/*
	gokz-quiet Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_quiet_included_
#endinput
#endif
#define _gokz_quiet_included_



// =====[ ENUMS ]=====

enum QTOption:
{
	QTOPTION_INVALID = -1, 
	QTOption_ShowPlayers, 
	QTOption_MapSounds, 
	QTOPTION_COUNT
};

enum
{
	ShowPlayers_Disabled = 0, 
	ShowPlayers_Enabled, 
	SHOWPLAYERS_COUNT
};

enum
{
	MapSounds_Enabled = 0,
	MapSounds_Disabled,
	MAPSOUNDS_COUNT
};



// =====[ CONSTANTS ]=====

stock char gC_QTOptionNames[QTOPTION_COUNT][] = 
{
	"GOKZ QT - Show Players",
	"GOKZ QT - Map Sounds"
};

stock char gC_QTOptionDescriptions[QTOPTION_COUNT][] = 
{
	"Visibility of Other Players - 0 = Disabled, 1 = Enabled",
	"Play Ambient Map Sounds/Music - 0 = Enabled, 1 = Disabled"
};

stock int gI_QTOptionDefaultValues[QTOPTION_COUNT] = 
{
	ShowPlayers_Enabled,
	MapSounds_Enabled
};

stock int gI_QTOptionCounts[QTOPTION_COUNT] = 
{
	SHOWPLAYERS_COUNT,
	MAPSOUNDS_COUNT
};

stock char gC_QTOptionPhrases[QTOPTION_COUNT][] = 
{
	"Options Menu - Show Players",
	"Options Menu - Map Sounds"
};



// =====[ STOCKS ]=====

/**
 * Returns whether an option is a gokz-quiet option.
 *
 * @param option		Option name.
 * @param optionEnum	Variable to store enumerated gokz-quiet option (if it is one).
 * @return				Whether option is a gokz-quiet option.
 */
stock bool GOKZ_QT_IsQTOption(const char[] option, QTOption &optionEnum = QTOPTION_INVALID)
{
	for (QTOption i; i < QTOPTION_COUNT; i++)
	{
		if (StrEqual(option, gC_QTOptionNames[i]))
		{
			optionEnum = i;
			return true;
		}
	}
	return false;
}

/**
 * Gets the current value of a player's gokz-quiet option.
 *
 * @param client		Client index.
 * @param option		gokz-quiet option.
 * @return				Current value of option.
 */
stock any GOKZ_QT_GetOption(int client, QTOption option)
{
	return GOKZ_GetOption(client, gC_QTOptionNames[option]);
}

/**
 * Sets a player's gokz-quiet option's value.
 *
 * @param client		Client index.
 * @param option		gokz-quiet option.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_QT_SetOption(int client, QTOption option, any value)
{
	return GOKZ_SetOption(client, gC_QTOptionNames[option], value);
}

/**
 * Increment an integer-type gokz-quiet option's value.
 * Loops back to '0' if max value is exceeded.
 *
 * @param client		Client index.
 * @param option		gokz-quiet option.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_QT_CycleOption(int client, QTOption option)
{
	return GOKZ_CycleOption(client, gC_QTOptionNames[option]);
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_quiet = 
{
	name = "gokz-quiet", 
	file = "gokz-quiet.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
}; 