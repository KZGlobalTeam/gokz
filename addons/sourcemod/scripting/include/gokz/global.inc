/*
	gokz-global Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_global_included_
#endinput
#endif
#define _gokz_global_included_

#include <GlobalAPI-Core>



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
native void GOKZ_GL_PrintRecords(int client, const char[] map = "", int course, int mode);

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
	return GlobalMode;
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
}
#endif