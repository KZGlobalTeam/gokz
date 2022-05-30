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
	JumpType_FullInvalid = -1,
	JumpType_LongJump, 
	JumpType_Bhop, 
	JumpType_MultiBhop, 
	JumpType_WeirdJump, 
	JumpType_LadderJump, 
	JumpType_Ladderhop, 
	JumpType_Jumpbug,
	JumpType_LowpreBhop,
	JumpType_LowpreWeirdJump,
	JumpType_Fall, 
	JumpType_Other, 
	JumpType_Invalid, 
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
	DistanceTier_Wrecker,
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
	JSOption_JumpstatsAlways, 
	JSOption_ExtendedChatReport, 
	JSOption_MinChatBroadcastTier,
	JSOption_MinSoundBroadcastTier,
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
#define JS_CFG_BROADCAST "cfg/sourcemod/gokz/gokz-jumpstats-broadcast.cfg"
#define JS_OPTION_CATEGORY "Jumpstats"
#define JS_MAX_LADDERJUMP_OFFSET 2.0
#define JS_MAX_BHOP_GROUND_TICKS 5
#define JS_MAX_DUCKBUG_RESET_TICKS 6
#define JS_MAX_WEIRDJUMP_FALL_OFFSET 64.0
#define JS_TOUCH_GRACE_TICKS 3
#define JS_MAX_TRACKED_STRAFES 48
#define JS_MIN_BLOCK_DISTANCE 186
#define JS_MIN_LAJ_BLOCK_DISTANCE 50
#define JS_MAX_LAJ_FAILSTAT_DISTANCE 250
#define JS_TOP_RECORD_COUNT 20
#define JS_MAX_JUMP_DISTANCE 500
#define JS_FAILSTATS_MAX_TRACKED_TICKS 128
#define JS_MIN_TELEPORT_DELAY 5
#define JS_SPEED_MODIFICATION_TOLERANCE 0.1
#define JS_OFFSET_EPSILON 0.03125

stock char gC_JumpTypes[JUMPTYPE_COUNT][] = 
{
	"Long Jump", 
	"Bunnyhop", 
	"Multi Bunnyhop", 
	"Weird Jump", 
	"Ladder Jump", 
	"Ladderhop", 
	"Jumpbug",
	"Lowpre Bunnyhop",
	"Lowpre Weird Jump",
	"Fall", 
	"Unknown Jump",
	"Invalid Jump"
};

stock char gC_JumpTypesShort[JUMPTYPE_COUNT][] = 
{
	"LJ", 
	"BH", 
	"MBH", 
	"WJ", 
	"LAJ", 
	"LAH", 
	"JB", 
	"LBH",
	"LWJ",
	"FL", 
	"UNK",
	"INV"
};

stock char gC_JumpTypeKeys[JUMPTYPE_COUNT][] = 
{
	"longjump", 
	"bhop", 
	"multibhop", 
	"weirdjump", 
	"ladderjump", 
	"ladderhop",
	"jumpbug",
	"lowprebhop",
	"lowpreweirdjump",
	"fall",
	"unknown",
	"invalid"
};

stock char gC_DistanceTiers[DISTANCETIER_COUNT][] = 
{
	"None", 
	"Meh", 
	"Impressive", 
	"Perfect", 
	"Godlike", 
	"Ownage",
	"Wrecker"
};

stock char gC_DistanceTierKeys[DISTANCETIER_COUNT][] = 
{
	"none", 
	"meh", 
	"impressive", 
	"perfect", 
	"godlike", 
	"ownage",
	"wrecker"
};

stock char gC_DistanceTierChatColours[DISTANCETIER_COUNT][] = 
{
	"{grey}", 
	"{grey}", 
	"{blue}", 
	"{green}", 
	"{darkred}", 
	"{gold}",
	"{orchid}"
};

stock char gC_JSOptionNames[JSOPTION_COUNT][] = 
{
	"GOKZ JS - Master Switch", 
	"GOKZ JS - Chat Report", 
	"GOKZ JS - Console Report", 
	"GOKZ JS - Sounds", 
	"GOKZ JS - Failstats Console", 
	"GOKZ JS - Failstats Chat", 
	"GOKZ JS - Jumpstats Always", 
	"GOKZ JS - Ext Chat Report",
	"GOKZ JS - Min Chat Broadcast",
	"GOKZ JS - Min Sound Broadcast"
};

stock char gC_JSOptionDescriptions[JSOPTION_COUNT][] = 
{
	"Master Switch for All Jumpstats Functionality - 0 = Disabled, 1 = Enabled", 
	"Minimum Tier for Jumpstats Chat Report - 0 = Disabled, 1 = Meh+, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage+, 6 = Wrecker", 
	"Minimum Tier for Jumpstats Console report - 0 = Disabled, 1 = Meh+, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage+, 6 = Wrecker", 
	"Minimum Tier for Jumpstats Sounds - 0 = Disabled, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage+, 6 = Wrecker", 
	"Print Failstats To Console - 0 = Disabled, 1 = Enabled", 
	"Print Failstats To Chat - 0 = Disabled, 1 = Enabled", 
	"Always show jumpstats, even for invalid jumps - 0 = Disabled, 1 = Enabled", 
	"Extended Chat Report - 0 = Disabled, 1 = Enabled",
	"Minimum Jump Tier for Jumpstat Chat Broadcast - 0 = Disabled, 1 = Meh+, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage+, 6 = Wrecker",
	"Minimum Jump Tier for Jumpstat Sound Broadcast - 0 = Disabled, 1 = Meh+, 2 = Impressive+, 3 = Perfect+, 4 = Godlike+, 5 = Ownage+, 6 = Wrecker"
};

stock char gI_JSOptionPhrases[JSOPTION_COUNT][] = 
{
	"Options Menu - Jumpstats Master Switch", 
	"Options Menu - Jumpstats Chat Report", 
	"Options Menu - Jumpstats Console Report", 
	"Options Menu - Jumpstats Sounds", 
	"Options Menu - Failstats Console Report", 
	"Options Menu - Failstats Chat Report", 
	"Options Menu - Jumpstats Always", 
	"Options Menu - Extended Jump Chat Report",
	"Options Menu - Minimal Jump Chat Broadcast Tier",
	"Options Menu - Minimal Jump Sound Broadcast Tier"
};

stock int gI_JSOptionDefaults[JSOPTION_COUNT] = 
{
	JSToggleOption_Enabled, 
	DistanceTier_Meh, 
	DistanceTier_Meh, 
	DistanceTier_Impressive, 
	JSToggleOption_Enabled, 
	JSToggleOption_Disabled, 
	JSToggleOption_Disabled, 
	JSToggleOption_Disabled,
	DistanceTier_Ownage,
	DistanceTier_None
};

stock int gI_JSOptionCounts[JSOPTION_COUNT] = 
{
	JSTOGGLEOPTION_COUNT, 
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT, 
	JSTOGGLEOPTION_COUNT, 
	JSTOGGLEOPTION_COUNT, 
	JSTOGGLEOPTION_COUNT, 
	JSTOGGLEOPTION_COUNT,
	DISTANCETIER_COUNT, 
	DISTANCETIER_COUNT
};



// =====[ STRUCTS ]=====

enum struct Jump
{
	int jumper;
	int block;
	int crouchRelease;
	int crouchTicks;
	int deadair;
	int duration;
	int originalType;
	int overlap;
	int releaseW;
	int strafes;
	int type;
	float deviation;
	float distance;
	float edge;
	float height;
	float maxSpeed;
	float offset;
	float preSpeed;
	float sync;
	float width;
	
	// For the 'always' stats
	float miss;
	
	// We can't make a separate enum struct for that cause it won't let us
	// index an array of enum structs.
	int strafes_gainTicks[JS_MAX_TRACKED_STRAFES];
	int strafes_deadair[JS_MAX_TRACKED_STRAFES];
	int strafes_overlap[JS_MAX_TRACKED_STRAFES];
	int strafes_ticks[JS_MAX_TRACKED_STRAFES];
	float strafes_gain[JS_MAX_TRACKED_STRAFES];
	float strafes_loss[JS_MAX_TRACKED_STRAFES];
	float strafes_sync[JS_MAX_TRACKED_STRAFES];
	float strafes_width[JS_MAX_TRACKED_STRAFES];
}



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
 * @param jump			The jumpstats.
 */
forward void GOKZ_JS_OnLanding(Jump jump);

/**
 * Called when player's current jump has been declared an invalid jumpstat.
 *
 * @param client		Client index.
 */
forward void GOKZ_JS_OnJumpInvalidated(int client);

/**
 * Called when a player fails a blockjump.
 *
 * @param jump			The jumpstats.
 */
forward void GOKZ_JS_OnFailstat(Jump jump);

/**
 * Called when a player lands a jump and has always-on jumpstats enabled.
 *
 * @param jump			The jumpstats.
 */
forward void GOKZ_JS_OnJumpstatAlways(Jump jump);

/**
 * Called when a player fails a jump and has always-on failstats enabled.
 *
 * @param jump			The failstats.
 */
forward void GOKZ_JS_OnFailstatAlways(Jump jump);



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
	MarkNativeAsOptional("GOKZ_JS_GetDefaultOption");
	MarkNativeAsOptional("GOKZ_JS_InvalidateJump");
}
#endif
