/*
	gokz-localranks Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_localranks_included_
#endinput
#endif
#define _gokz_localranks_included_



// =====[ ENUMS ]=====

enum
{
	RecordType_Nub = 0, 
	RecordType_Pro, 
	RecordType_NubAndPro, 
	RECORDTYPE_COUNT
};



// =====[ CONSTANTS ]=====

#define LR_CFG_MAP_POOL "cfg/sourcemod/gokz/gokz-localranks-mappool.cfg"
#define LR_CFG_SOUNDS "cfg/sourcemod/gokz/gokz-localranks-sounds.cfg"
#define LR_COMMAND_COOLDOWN 2.5
#define LR_MAP_TOP_CUTOFF 20
#define LR_PLAYER_TOP_CUTOFF 20



// =====[ FORWARDS ]=====

/**
 * Called when a player's time has been processed by GOKZ Local Ranks.
 *
 * @param client		Client index.
 * @param steamID		SteamID32 of the player (from GetSteamAccountID()).
 * @param mapID 		MapID from the "Maps" database table.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			Player's movement mode.
 * @param style			Player's movement style.
 * @param runTime		Player's end time.
 * @param teleportsUsed	Number of teleportsUsed used by player.
 * @param firstTime		Whether this is player's first time on this course.
 * @param pbDiff		Difference between new time and PB in seconds (-'ve means beat PB).
 * @param rank			New rank of the player's PB time.
 * @param maxRank		New total number of players with times.
 * @param firstTimePro	Whether this is player's first PRO time on this course.
 * @param pbDiffPro		Difference between new time and PRO PB in seconds (-'ve means beat PB).
 * @param rankPro		New rank of the player's PB PRO time.
 * @param maxRankPro	New total number of players with PRO times.
 */
forward void GOKZ_LR_OnTimeProcessed(
	int client, 
	int steamID, 
	int mapID, 
	int course, 
	int mode, 
	int style, 
	float runTime, 
	int teleportsUsed, 
	bool firstTime, 
	float pbDiff, 
	int rank, 
	int maxRank, 
	bool firstTimePro, 
	float pbDiffPro, 
	int rankPro, 
	int maxRankPro);

/**
 * Called when a player sets a new local record.
 *
 * @param client			Client index.
 * @param steamID			SteamID32 of the player (from GetSteamAccountID()).
 * @param mapID 			MapID from the "Maps" table.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param style				Player's movement style.
 * @param recordType		Type of record.
 */
forward void GOKZ_LR_OnNewRecord(
	int client, 
	int steamID, 
	int mapID, 
	int course, 
	int mode, 
	int style, 
	int recordType);

/**
 * Called when a player misses the server record time.
 * Is called regardless of player's current run type.
 *
 * @param client			Client index.
 * @param recordTime		Record time missed.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param style				Player's movement style.
 * @param recordType		Type of record.
 */
forward void GOKZ_LR_OnRecordMissed(int client, float recordTime, int course, int mode, int style, int recordType);

/**
 * Called when a player misses their personal best time.
 * Is called regardless of player's current run type.
 *
 * @param client			Client index.
 * @param pbTime			Personal best time missed.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param style				Player's movement style.
 * @param recordType		Type of record.
 */
forward void GOKZ_LR_OnPBMissed(int client, float pbTime, int course, int mode, int style, int recordType);



// =====[ NATIVES ]=====

/**
 * Gets whether player has missed the server record time.
 *
 * @param client		Client index.
 * @param timeType		Which record time i.e. NUB or PRO.
 * @return				Whether player has missed the server record time.
 */
native bool GOKZ_LR_GetRecordMissed(int client, int timeType);

/**
 * Gets whether player has missed their personal best time.
 *
 * @param client		Client index.
 * @param timeType		Which PB time i.e. NUB or PRO.
 * @return				Whether player has missed their PB time.
 */
native bool GOKZ_LR_GetPBMissed(int client, int timeType);

/**
 * Reopens the map top menu with the already selected parameters.
 * Don't use if the client hasn't opened the map top menu before.
 *
 * @param client		Client index.
 */
native void GOKZ_LR_ReopenMapTopMenu(int client);



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_localranks = 
{
	name = "gokz-localranks", 
	file = "gokz-localranks.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_localranks_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_LR_GetRecordMissed");
	MarkNativeAsOptional("GOKZ_LR_GetPBMissed");
	MarkNativeAsOptional("GOKZ_LR_ReopenMapTopMenu");
}
#endif