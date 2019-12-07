/*
	gokz-jumpstats Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_jumpstats_included_
#endinput
#endif
#define _gokz_jumpstats_included_



// =====[ ENUMS ]=====

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

enum JSOption:
{
	JSOPTION_INVALID = -1, 
	JSOption_JumpstatsMaster, 
	JSOption_MinChatTier, 
	JSOption_MinConsoleTier, 
	JSOption_MinSoundTier, 
	JSOption_FailstatsConsole, 
	JSOption_FailstatsChat, 
	JSOption_ExtendedChatReport, 
	JSOPTION_COUNT
};

enum
{
	JSToggleOption_Disabled = 0, 
	JSToggleOption_Enabled, 
	JSTOGGLEOPTION_COUNT
};



// =====[ CONSTANTS ]=====

#define JS_CFG_TIERS "cfg/sourcemod/gokz/gokz-jumpstats-tiers.cfg"
#define JS_CFG_SOUNDS "cfg/sourcemod/gokz/gokz-jumpstats-sounds.cfg"
#define JS_OPTION_CATEGORY "Jumpstats"
#define JS_MAX_NORMAL_OFFSET 0.6
#define JS_MAX_LADDERJUMP_OFFSET 2.0
#define JS_MAX_BHOP_GROUND_TICKS 5
#define JS_MAX_WEIRDJUMP_FALL_OFFSET 64.0
#define JS_MAX_TRACKED_STRAFES 32
#define JS_MIN_BLOCK_DISTANCE 200
#define JS_MIN_LAJ_BLOCK_DISTANCE 50
#define JS_MAX_LAJ_FAILSTAT_DISTANCE 250
#define JS_TOP_RECORD_COUNT 20
#define JS_MAX_JUMP_DISTANCE 500

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

stock char gC_JumpTypeKeys[JUMPTYPE_COUNT - 2][] = 
{
	"longjump", 
	"bhop", 
	"multibhop", 
	"weirdjump", 
	"ladderjump", 
	"ladderhop"
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

stock char gC_DistanceTierKeys[DISTANCETIER_COUNT][] = 
{
	"none", 
	"meh", 
	"impressive", 
	"perfect", 
	"godlike", 
	"ownage"
};

stock char gC_DistanceTierChatColours[DISTANCETIER_COUNT][] = 
{
	"{grey}", 
	"{grey}", 
	"{blue}", 
	"{green}", 
	"{darkred}", 
	"{gold}"
};

stock char gC_JSOptionNames[JSOPTION_COUNT][] = 
{
	"GOKZ JS - Master Switch", 
	"GOKZ JS - Chat Report", 
	"GOKZ JS - Console Report", 
	"GOKZ JS - Sounds", 
	"GOKZ JS - Failstats Console", 
	"GOKZ JS - Failstats Chat", 
	"GOKZ JS - Extended Chat Report"
};

stock char gC_JSOptionDescriptions[JSOPTION_COUNT][] = 
{
	"Master Switch for All Jumpstats Functionality - 0 = Disabled, 1 = Enabled", 
	"Minimum Tier for Jumpstats Chat Report - 0 = Disabled, 1 = Meh+, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage", 
	"Minimum Tier for Jumpstats Console report - 0 = Disabled, 1 = Meh+, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage", 
	"Minimum Tier for Jumpstats Sounds - 0 = Disabled, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage", 
	"Print Failstats To Console - 0 = Disabled, 1 = Enabled", 
	"Print Failstats To Chat - 0 = Disabled, 1 = Enabled", 
	"Extended Chat Report - 0 = Disabled, 1 = Enabled"
};

stock char gI_JSOptionPhrases[JSOPTION_COUNT][] = 
{
	"Options Menu - Jumpstats Master Switch", 
	"Options Menu - Jumpstats Chat Report", 
	"Options Menu - Jumpstats Console Report", 
	"Options Menu - Jumpstats Sounds", 
	"Options Menu - Failstats Console Report", 
	"Options Menu - Failstats Chat Report", 
	"Options Menu - Extended Jump Chat Report"
};

stock int gI_JSOptionDefaults[JSOPTION_COUNT] = 
{
	JSToggleOption_Enabled, 
	DistanceTier_Meh, 
	DistanceTier_Meh, 
	DistanceTier_Impressive, 
	JSToggleOption_Enabled, 
	JSToggleOption_Disabled, 
	JSToggleOption_Disabled
};

stock int gI_JSOptionCounts[JSOPTION_COUNT] = 
{
	JSTOGGLEOPTION_COUNT, 
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT, 
	JSTOGGLEOPTION_COUNT, 
	JSTOGGLEOPTION_COUNT, 
	JSTOGGLEOPTION_COUNT
};



// =====[ FORWARDS ]=====

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
 * @param block         Size of the block jumped.
 * @param width         Total angle turned during the jump.
 * @param overlap       Amount of ticks where the player turned left and right at the same time.
 * @param deadair       Amount of ticks where the player turned neither left nor right.
 * @param deviation     Deviation to the side when jumping across a block.
 * @param edge          Distance from the edge of the jumpoff block to the player jumpoff position.
 * @param releaseW      Tick relative to the jumpoff that the forward key was released.
 */
forward void GOKZ_JS_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW);

/**
 * Called when player's current jump has been declared an invalid jumpstat.
 *
 * @param client		Client index.
 */
forward void GOKZ_JS_OnJumpInvalidated(int client);

/**
 * Called when a player fails a blockjump.
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
 * @param block         Size of the block jumped.
 * @param width         Total angle turned during the jump.
 * @param overlap       Amount of ticks where the player turned left and right at the same time.
 * @param deadair       Amount of ticks where the player turned neither left nor right.
 * @param deviation     Deviation to the side when jumping across a block.
 * @param edge          Distance from the edge of the jumpoff block to the player jumpoff position.
 * @param releaseW      Tick relative to the jumpoff that the forward key was released.
 */
forward void GOKZ_JS_OnFailstat(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW);



// =====[ NATIVES ]=====

/**
 * Gets the default jumpstats option value as set by a config file.
 *
 * @param option		GOKZ Jumpstats option.
 * @return				Default option value.
 */
native int GOKZ_JS_GetDefaultOption(JSOption option);

/**
 * Declare a player's current jump an invalid jumpstat.
 *
 * @param client    	Client index.
 */
native void GOKZ_JS_InvalidateJump(int client);



// =====[ STOCKS ]=====

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
 * Sets a player's gokz-jumpstats option's value.
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



// =====[ DEPENDENCY ]=====

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
