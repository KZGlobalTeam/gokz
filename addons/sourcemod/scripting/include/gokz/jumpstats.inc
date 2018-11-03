/* 	
	GOKZ Jumpstats Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_jumpstats_included_
#endinput
#endif
#define _gokz_jumpstats_included_



// =========================  DEFINITIONS  ========================= //

#define OPTIONS_MENU_CAT_JUMPSTATS "jumpstats"



// =========================  ENUMERATIONS  ========================= //

enum
{
	JumpType_Invalid = -1, 
	JumpType_LongJump, 
	JumpType_Bhop, 
	JumpType_MultiBhop, 
	JumpType_WeirdJump, 
	JumpType_LadderJump, 
	JumpType_Ladderhop, 
	JumpType_Fall, 
	JumpType_Other, 
	JUMPTYPE_COUNT
};

enum
{
	StrafeDirection_None, 
	StrafeDirection_Left, 
	StrafeDirection_Right
};

enum
{
	DistanceTier_None = 0, 
	DistanceTier_Meh, 
	DistanceTier_Impressive, 
	DistanceTier_Perfect, 
	DistanceTier_Godlike, 
	DistanceTier_Ownage, 
	DISTANCETIER_COUNT
};

enum JSOption
{
	JSOPTION_INVALID = -1, 
	JSOption_JumpstatsMaster, 
	JSOption_MinChatTier, 
	JSOption_MinConsoleTier, 
	JSOption_MinSoundTier, 
	JSOPTION_COUNT
};

enum
{
	JumpstatsMaster_Disabled = 0, 
	JumpstatsMaster_Enabled, 
	JUMPSTATSMASTER_COUNT
};



// =========================  PHRASES  ========================= //

stock char gC_JumpTypes[JUMPTYPE_COUNT][] = 
{
	"Long Jump", 
	"Bunnyhop", 
	"Multi Bunnyhop", 
	"Weird Jump", 
	"Ladder Jump", 
	"Ladderhop", 
	"Fall", 
	"Unknown Jump"
};

stock char gC_JumpTypesShort[JUMPTYPE_COUNT][] = 
{
	"LJ", 
	"BH", 
	"MBH", 
	"WJ", 
	"LAJ", 
	"LAH", 
	"FL", 
	"??"
};

stock char gC_DistanceTiers[DISTANCETIER_COUNT][] = 
{
	"None", 
	"Meh", 
	"Impressive", 
	"Perfect", 
	"Godlike", 
	"Ownage"
};



// =========================  OTHER  ========================= //

// Used and recommended for key value files
stock char gC_KeysJumpType[JUMPTYPE_COUNT - 2][] =  { "longjump", "bhop", "multibhop", "weirdjump", "ladderjump", "ladderhop" };
stock char gC_KeysMode[MODE_COUNT][] =  { "vanilla", "simplekz", "kztimer" };
stock char gC_KeysDistanceTier[DISTANCETIER_COUNT][] =  { "none", "meh", "impressive", "perfect", "godlike", "ownage" };
stock char gC_JSOptionNames[JSOPTION_COUNT][] =  { "masterswitch", "chatreport", "consolereport", "sounds" };



// =========================  FORWARDS  ========================= //

/**
 * Called when a player begins their jump.
 *
 * @param client		Client index.
 * @param jumpType		Type of jump.
 */
forward void GOKZ_JS_OnTakeoff(int client, int jumpType);

/**
 * Called when a player lands their jump.
 *
 * @param client		Client index.
 * @param jumpType		Type of jump they landed.
 * @param distance		Horizontal distance of the jump.
 * @param offset		Vertical distance of the jump.
 * @param height		Max height of the player relative to their takeoff origin.
 * @param preSpeed		Takeoff speed.
 * @param maxSpeed		Max horizontal speed reached.
 * @param strafes		Number of strafes.
 * @param sync			Percentage of time that speed was gained.
 * @param duration		Duration of the jump in seconds.
 */
forward void GOKZ_JS_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration);

/**
 * Called when player's current jump has been declared an invalid jumpstat.
 *
 * @param client		Client index.
 */
forward void GOKZ_JS_OnJumpInvalidated(int client);



// =========================  NATIVES  ========================= //

/**
 * Gets the default jumpstats option value as set by a config file.
 *
 * @param option		GOKZ Jumpstats option.
 * @return				Default option value.
 */
native int GOKZ_JS_GetDefaultOption(JSOption option);

/**
 * Declare the player's current jump an invalid jumpstat.
 *
 * @param client    	Client index.
 */
native void GOKZ_JS_InvalidateJump(int client);



// =========================  STOCKS  ========================= //

/**
 * Returns whether an option is a gokz-jumpstats option.
 *
 * @param option		Option name.
 * @param optionEnum	Variable to store enumerated gokz-jumpstats option (if it is one).
 * @return				Whether option is a gokz-jumpstats option.
 */
stock bool GOKZ_JS_IsJSOption(const char[] option, JSOption &optionEnum = JSOPTION_INVALID)
{
	for (JSOption i; i < JSOPTION_COUNT; i++)
	{
		if (StrEqual(option, gC_JSOptionNames[i]))
		{
			optionEnum = i;
			return true;
		}
	}
	return false;
}

/**
 * Gets the current value of a player's gokz-jumpstats option.
 *
 * @param client		Client index.
 * @param option		gokz-jumpstats option.
 * @return				Current value of option.
 */
stock any GOKZ_JS_GetOption(int client, JSOption option)
{
	return GOKZ_GetOption(client, gC_JSOptionNames[option]);
}

/**
 * Sets the player's gokz-jumpstats option's value.
 *
 * @param client		Client index.
 * @param option		gokz-jumpstats option.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_JS_SetOption(int client, JSOption option, any value)
{
	return GOKZ_SetOption(client, gC_JSOptionNames[option], value);
}

/**
 * Increment an integer-type gokz-jumpstats option's value.
 * Loops back to '0' if max value is exceeded.
 *
 * @param client		Client index.
 * @param option		gokz-jumpstats option.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_JS_CycleOption(int client, JSOption option)
{
	return GOKZ_CycleOption(client, gC_JSOptionNames[option]);
}



// =========================  DEPENDENCY  ========================= //

public SharedPlugin __pl_gokz_jumpstats = 
{
	name = "gokz-jumpstats", 
	file = "gokz-jumpstats.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_jumpstats_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_JS_InvalidateJump");
}
#endif