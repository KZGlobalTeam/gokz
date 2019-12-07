/*
	gokz-jumpbeam Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_jumpbeam_included_
#endinput
#endif
#define _gokz_jumpbeam_included_



// =====[ ENUMS ]=====

enum JBOption:
{
	JBOPTION_INVALID = -1, 
	JBOption_Type, 
	JBOPTION_COUNT
};

enum
{
	JBType_Disabled = 0, 
	JBType_Feet, 
	JBType_Head, 
	JBType_FeetAndHead, 
	JBType_Ground, 
	JBTYPE_COUNT
};



// =====[ CONSTANTS ]=====

#define JB_BEAM_LIFETIME 4.0

stock char gC_JBOptionNames[JBOPTION_COUNT][] = 
{
	"GOKZ JB - Jump Beam Type"
};

stock char gC_JBOptionDescriptions[JBOPTION_COUNT][] = 
{
	"Jump Beam Type - 0 = Disabled, 1 = Feet, 2 = Head, 3 = Feet & Head, 4 = Ground"
};

stock int gI_JBOptionDefaultValues[JBOPTION_COUNT] = 
{
	JBType_Disabled
};

stock int gI_JBOptionCounts[JBOPTION_COUNT] = 
{
	JBTYPE_COUNT
};

stock char gC_JBOptionPhrases[JBOPTION_COUNT][] = 
{
	"Options Menu - Jump Beam"
};

stock char gC_JBTypePhrases[JBTYPE_COUNT][] = 
{
	"Options Menu - Disabled", 
	"Options Menu - Feet", 
	"Options Menu - Head", 
	"Options Menu - Feet and Head", 
	"Options Menu - Ground"
};



// =====[ STOCKS ]=====

/**
 * Returns whether an option is a gokz-jumpbeam option.
 *
 * @param option		Option name.
 * @param optionEnum	Variable to store enumerated gokz-jumpbeam option (if it is one).
 * @return				Whether option is a gokz-jumpbeam option.
 */
stock bool GOKZ_JB_IsJBOption(const char[] option, JBOption &optionEnum = JBOPTION_INVALID)
{
	for (JBOption i; i < JBOPTION_COUNT; i++)
	{
		if (StrEqual(option, gC_JBOptionNames[i]))
		{
			optionEnum = i;
			return true;
		}
	}
	return false;
}

/**
 * Gets the current value of a player's gokz-jumpbeam option.
 *
 * @param client		Client index.
 * @param option		gokz-jumpbeam option.
 * @return				Current value of option.
 */
stock any GOKZ_JB_GetOption(int client, JBOption option)
{
	return GOKZ_GetOption(client, gC_JBOptionNames[option]);
}

/**
 * Sets a player's gokz-jumpbeam option's value.
 *
 * @param client		Client index.
 * @param option		gokz-jumpbeam option.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_JB_SetOption(int client, JBOption option, any value)
{
	return GOKZ_SetOption(client, gC_JBOptionNames[option], value);
}

/**
 * Increment an integer-type gokz-jumpbeam option's value.
 * Loops back to '0' if max value is exceeded.
 *
 * @param client		Client index.
 * @param option		gokz-jumpbeam option.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_JB_CycleOption(int client, JBOption option)
{
	return GOKZ_CycleOption(client, gC_JBOptionNames[option]);
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_jumpbeam = 
{
	name = "gokz-jumpbeam", 
	file = "gokz-jumpbeam.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
}; 