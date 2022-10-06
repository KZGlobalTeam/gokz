/*
	gokz-global Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_global_included_
#endinput
#endif
#define _gokz_global_included_

#include <GlobalAPI>



// =====[ ENUMS ]=====

enum
{
	EnforcedCVar_Cheats = 0, 
	EnforcedCVar_ClampUnsafeVelocities, 
	EnforcedCVar_DropKnifeEnable, 
	EnforcedCVar_AutoBunnyhopping, 
	EnforcedCVar_MinUpdateRate,
	EnforcedCVar_MaxUpdateRate,
	EnforcedCVar_MinCmdRate,
	EnforcedCVar_MaxCmdRate,
	EnforcedCVar_ClientCmdrateDifference,
	EnforcedCVar_Turbophysics,
	ENFORCEDCVAR_COUNT
};

enum
{
	BannedPluginCommand_Funcommands = 0,
	BannedPluginCommand_Playercommands,
	BANNEDPLUGINCOMMAND_COUNT
};

enum
{
	BannedPlugin_Funcommands = 0,
	BannedPlugin_Playercommands,
	BANNEDPLUGIN_COUNT
};

enum GlobalMode
{
	GlobalMode_Invalid = -1,
	GlobalMode_KZTimer = 200,
	GlobalMode_KZSimple,
	GlobalMode_Vanilla
}



// =====[ CONSTANTS ]=====

#define GL_SOUND_NEW_RECORD "gokz/holyshit.mp3"
#define GL_FPS_MAX_CHECK_INTERVAL 1.0
#define GL_FPS_MAX_KICK_TIMEOUT 10.0
#define GL_FPS_MAX_MIN_VALUE 120
#define GL_MYAW_MAX_VALUE 0.3

stock char gC_EnforcedCVars[ENFORCEDCVAR_COUNT][] = 
{
	"sv_cheats", 
	"sv_clamp_unsafe_velocities", 
	"mp_drop_knife_enable", 
	"sv_autobunnyhopping",
	"sv_minupdaterate",
	"sv_maxupdaterate",
	"sv_mincmdrate",
	"sv_maxcmdrate",
	"sv_client_cmdrate_difference",
	"sv_turbophysics"
};

stock char gC_BannedPluginCommands[BANNEDPLUGINCOMMAND_COUNT][] =
{
	"sm_beacon",
	"sm_slap"
};

stock char gC_BannedPlugins[BANNEDPLUGIN_COUNT][] = 
{
	"Fun Commands",
	"Player Commands"
};

stock float gF_EnforcedCVarValues[ENFORCEDCVAR_COUNT] = 
{
	0.0, 
	0.0, 
	0.0, 
	0.0,
	128.0,
	128.0,
	128.0,
	128.0,
	0.0,
	0.0
};



// =====[ FORWARDS ]=====

/**
 * Called when a player sets a new global top time.
 *
 * @param client		Client index.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			Player's movement mode.
 * @param timeType		Time type i.e. NUB or PRO.
 * @param rank			Ranking within the same time type.
 * @param rankOverall	Overall (NUB and PRO) ranking (0 if not ranked high enough).
 * @param runTime		Player's end time.
 */
forward void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall, float runTime);



// =====[ NATIVES ]=====

/**
 * Prints to chat the global records for a map, course and mode.
 *
 * @param client		Client index.
 * @param map	    	Map name or "" for current map.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			GOKZ mode.
 */
native void GOKZ_GL_PrintRecords(int client, const char[] map = "", int course, int mode, const char[] steamid = DEFAULT_STRING);

/**
 * Opens up the global map top menu for a map, course and mode.
 *
 * @param client		Client index.
 * @param map	    	Map name or "" for current map.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			GOKZ mode.
 * @param timeType		Type of time i.e. NUB or PRO.
 */
native void GOKZ_GL_DisplayMapTopMenu(int client, const char[] map = "", int course, int mode, int timeType);

/**
 * Get the total global points of a player.
 *
 * @param client		Client index.
 * @param mode			GOKZ mode.
 * @param timeType		Type of time i.e. NUB or PRO.
 */
native void GOKZ_GL_GetPoints(int client, int mode, int timeType);

/**
 * Get the global points on the main coruse of the current map.
 *
 * @param client		Client index.
 * @param mode			GOKZ mode.
 * @param timeType		Type of time i.e. NUB or PRO.
 */
native void GOKZ_GL_GetMapPoints(int client, int mode, int timeType);

/**
 * Get the total global ranking points of a player.
 *
 * @param client		Client index.
 * @param mode			GOKZ mode.
 * @return				The points.
 */
native int GOKZ_GL_GetRankPoints(int client, int mode);

/**
 * Get the amount of maps a player finished.
 *
 * @param client		Client index.
 * @param mode			GOKZ mode.
 * @param timeType		Type of time i.e. NUB or PRO.
 */
native void GOKZ_GL_GetFinishes(int client, int mode, int timeType);

/**
 * Fetch the points a player got from the Global API.
 *
 * @param client		Client index. -1 to update all indices.
 * @param mode			GOKZ mode. -1 to update all modes.
 */
native void GOKZ_GL_UpdatePoints(int client = -1, int mode = -1);

/**
 * Gets whether the Global API key is valid or not for global status.
 *
 * @return				True if the API key is valid, false otherwise or if there is no connection to the Global API.
 */
native bool GOKZ_GL_GetAPIKeyValid();

/**
 * Gets whether the running plugins are valid or not for global status.
 *
 * @return				True if the plugins are valid, false otherwise.
 */
native bool GOKZ_GL_GetPluginsValid();

/**
 * Gets whether the setting enforcer is valid or not for global status.
 *
 * @return				True if the setting enforcer is valid, false otherwise.
 */
native bool GOKZ_GL_GetSettingsEnforcerValid();

/**
 * Gets whether the current map is valid or not for global status.
 *
 * @return				True if the map is valid, false otherwise or if there is no connection to the Global API.
 */
native bool GOKZ_GL_GetMapValid();

/**
 * Gets whether the current player is valid or not for global status.
 *
 * @param client		Client index.
 * @return				True if the player is valid, false otherwise or if there is no connection to the Global API.
 */
native bool GOKZ_GL_GetPlayerValid(int client);



// =====[ STOCKS ]=====

/**
 * Gets the global mode enumeration equivalent for the GOKZ mode.
 *
 * @param mode	    	GOKZ mode.
 * @return				Global mode enumeration equivalent.		
 */
stock GlobalMode GOKZ_GL_GetGlobalMode(int mode)
{
	switch (mode)
	{
		case Mode_Vanilla:return GlobalMode_Vanilla;
		case Mode_SimpleKZ:return GlobalMode_KZSimple;
		case Mode_KZTimer:return GlobalMode_KZTimer;
	}
	return GlobalMode_Invalid;
}

/**
 * Gets the global mode enumeration equivalent for the GOKZ mode.
 *
 * @param mode	    	GOKZ mode.
 * @return				Global mode enumeration equivalent.		
 */
stock int GOKZ_GL_FromGlobalMode(GlobalMode mode)
{
	switch (mode)
	{
		case GlobalMode_Vanilla:return Mode_Vanilla;
		case GlobalMode_KZSimple:return Mode_SimpleKZ;
		case GlobalMode_KZTimer:return Mode_KZTimer;
	}
	return -1;
}

/**
 * Gets the string representation of a mode.
 *
 * @param mode	    	GOKZ mode.
 * @param mode_str		String version of the mode.
 * @param size			Max length of mode_str.
 * @return				True if the conversion was successful.
 */
stock bool GOKZ_GL_GetModeString(int mode, char[] mode_str, int size)
{
	switch (mode)
	{
		case Mode_Vanilla:strcopy(mode_str, size, "kz_vanilla");
		case Mode_SimpleKZ:strcopy(mode_str, size, "kz_simple");
		case Mode_KZTimer:strcopy(mode_str, size, "kz_timer");
		default:return false;
	}
	return true;
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_global = 
{
	name = "gokz-global", 
	file = "gokz-global.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_global_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_GL_PrintRecords");
	MarkNativeAsOptional("GOKZ_GL_DisplayMapTopMenu");
	MarkNativeAsOptional("GOKZ_GL_UpdatePoints");
	MarkNativeAsOptional("GOKZ_GL_GetAPIKeyValid");
	MarkNativeAsOptional("GOKZ_GL_GetPluginsValid");
	MarkNativeAsOptional("GOKZ_GL_GetSettingsEnforcerValid");
	MarkNativeAsOptional("GOKZ_GL_GetMapValid");
	MarkNativeAsOptional("GOKZ_GL_GetPlayerValid");
	MarkNativeAsOptional("GOKZ_GL_GetPoints");
	MarkNativeAsOptional("GOKZ_GL_GetMapPoints");
	MarkNativeAsOptional("GOKZ_GL_GetRankPoints");
	MarkNativeAsOptional("GOKZ_GL_GetFinishes");
	MarkNativeAsOptional("GOKZ_GL_UpdatePoints");
}
#endif