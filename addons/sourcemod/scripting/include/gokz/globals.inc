/* 	
	GOKZ Globals Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_globals_included_
#endinput
#endif
#define _gokz_globals_included_

#include <GlobalAPI-Core>



// =========================  ENUMERATIONS  ========================= //

enum
{
	EnforcedCVar_Cheats = 0, 
	EnforcedCVar_ClampUnsafeVelocities, 
	EnforcedCVar_DropKnifeEnable, 
	ENFORCEDCVAR_COUNT
};



// =========================  OTHER  ========================= //

stock char gC_EnforcedCVars[ENFORCEDCVAR_COUNT][] = 
{
	"sv_cheats", 
	"sv_clamp_unsafe_velocities", 
	"mp_drop_knife_enable"
};



// =========================  FORWARDS  ========================= //

/**
 * Called when a player sets a new global top time.
 *
 * @param client		Client index.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			Player's movement mode.
 * @param timeType		Time type i.e. NUB or PRO.
 * @param rank			Ranking within the same time type.
 * @param rankOverall	Overall (NUB and PRO) ranking (0 if not ranked high enough).
 * @noreturn
 */
forward void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall);



// =========================  NATIVES  ========================= //

/**
 * Prints to chat the global records for a map, course and mode.
 *
 * @param client		Client index.
 * @param map	    	Map name or "" for current map.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			GOKZ mode.
 * @noreturn
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
 * @noreturn
 */
native void GOKZ_GL_DisplayMapTopMenu(int client, const char[] map = "", int course, int mode, int timeType);



// =========================  STOCKS  ========================= //

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



// =========================  DEPENDENCY  ========================= //

public SharedPlugin __pl_gokz_globals = 
{
	name = "gokz-globals", 
	file = "gokz-globals.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_globals_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_GL_PrintRecords");
	MarkNativeAsOptional("GOKZ_GL_DisplayMapTopMenu");
}
#endif