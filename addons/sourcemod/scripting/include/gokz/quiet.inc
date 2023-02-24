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
	QTOption_Soundscapes,
	QTOption_FallDamageSound,
	QTOption_AmbientSounds,
	QTOption_CheckpointVolume,
	QTOption_TeleportVolume,
	QTOption_TimerVolume,
	QTOption_ErrorVolume,
	QTOption_ServerRecordVolume,
	QTOption_WorldRecordVolume,
	QTOption_JumpstatsVolume,
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
	Soundscapes_Disabled = 0,
	Soundscapes_Enabled,
	SOUNDSCAPES_COUNT
};

// =====[ CONSTANTS ]=====

#define QUIET_OPTION_CATEGORY "Quiet"
#define DEFAULT_VOLUME 10
#define VOLUME_COUNT 21 // Maximum of 200%

#define EFFECT_IMPACT 8
#define EFFECT_KNIFESLASH 2
#define BLANK_SOUNDSCAPEINDEX 482 // Search for "coopcementplant.missionselect_blank" id with sv_soundscape_printdebuginfo.

stock char gC_QTOptionNames[QTOPTION_COUNT][] =
{
	"GOKZ QT - Show Players",
	"GOKZ QT - Soundscapes",
	"GOKZ QT - Fall Damage Sound",
	"GOKZ QT - Ambient Sounds",
	"GOKZ QT - Checkpoint Volume",
	"GOKZ QT - Teleport Volume",
	"GOKZ QT - Timer Volume",
	"GOKZ QT - Error Volume",
	"GOKZ QT - Server Record Volume",
	"GOKZ QT - World Record Volume",
	"GOKZ QT - Jumpstats Volume"
};

stock char gC_QTOptionDescriptions[QTOPTION_COUNT][] =
{
	"Visibility of Other Players - 0 = Disabled, 1 = Enabled",
	"Play Soundscapes - 0 = Disabled, 1 = Enabled",
	"Play Fall Damage Sound - 0 to 20 = 0% to 200%",
	"Play Ambient Sounds - 0 to 20 = 0% to 200%",
	"Checkpoint Volume - 0 to 20 = 0% to 200%",
	"Teleport Volume - 0 to 20 = 0% to 200%",
	"Timer Volume - 0 to 20 = 0% to 200%",
	"Error Volume - 0 to 20 = 0% to 200%",
	"Server Record Volume - 0 to 20 = 0% to 200%",
	"World Record Volume - 0 to 20 = 0% to 200%",
	"Jumpstats Volume - 0 to 20 = 0% to 200%"
};

stock int gI_QTOptionDefaultValues[QTOPTION_COUNT] =
{
	ShowPlayers_Enabled,
	Soundscapes_Enabled,
	DEFAULT_VOLUME, // Fall damage volume
	DEFAULT_VOLUME, // Ambient volume
	DEFAULT_VOLUME,	// Checkpoint volume
	DEFAULT_VOLUME, // Teleport volume
	DEFAULT_VOLUME, // Timer volume
	DEFAULT_VOLUME, // Error volume
	DEFAULT_VOLUME, // Server Record Volume
	DEFAULT_VOLUME, // World Record Volume
	DEFAULT_VOLUME // Jumpstats Volume
};

stock int gI_QTOptionCounts[QTOPTION_COUNT] =
{
	SHOWPLAYERS_COUNT,
	SOUNDSCAPES_COUNT,
	VOLUME_COUNT, // Fall damage volume
	VOLUME_COUNT, // Ambient volume
	VOLUME_COUNT, // Checkpoint volume
	VOLUME_COUNT, // Teleport volume
	VOLUME_COUNT, // Timer volume
	VOLUME_COUNT, // Error volume
	VOLUME_COUNT, // Server Record volume
	VOLUME_COUNT, // World Record volume
	VOLUME_COUNT // Jumpstats volume
};

stock char gC_QTOptionPhrases[QTOPTION_COUNT][] =
{
	"Options Menu - Show Players",
	"Options Menu - Soundscapes",
	"Options Menu - Fall Damage Sounds",
	"Options Menu - Ambient Sounds",
	"Options Menu - Checkpoint Volume",
	"Options Menu - Teleport Volume",
	"Options Menu - Timer Volume",
	"Options Menu - Error Volume",
	"Options Menu - Server Record Volume",
	"Options Menu - World Record Volume",
	"Options Menu - Jumpstats Volume"
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