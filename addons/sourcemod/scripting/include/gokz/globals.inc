/* 	
	GOKZ Globals Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_globals_included_
#endinput
#endif
#define _gokz_globals_included_



// =========================  FORWARDS  ========================= //

/**
 * Called when a player sets a new global top time.
 *
 * @param client			Client index.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param timeType			Time type i.e. NUB or PRO.
 * @param rank				Ranking within the same time type.
 * @param rankOverall		Overall (NUB and PRO) ranking (0 if not ranked high enough).
 * @noreturn
 */
forward void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall);



// =========================  STOCKS  ========================= //

/**
 * Gets the global mode enumeration equivalent for the GOKZ mode.
 *
 * @param mode	    	GOKZ mode.
 * @return				Global mode enumeration equivalent.		
 */
stock GlobalMode GetGlobalMode(int mode)
{
	switch (mode)
	{
		case Mode_Vanilla:return GlobalMode_Vanilla;
		case Mode_SimpleKZ:return GlobalMode_KZSimple;
		case Mode_KZTimer:return GlobalMode_KZTimer;
	}
	return GlobalMode;
} 