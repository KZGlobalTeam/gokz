/* 	
	GOKZ Local Ranks Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_localranks_included_
#endinput
#endif
#define _gokz_localranks_included_



// =========================  ENUMERATIONS  ========================= //

enum
{
	RecordType_Nub = 0, 
	RecordType_Pro, 
	RecordType_NubAndPro, 
	RECORD_COUNT
}



// =========================  FORWARDS  ========================= //

/**
 * Called when a player's time has been processed by GOKZ Local Ranks.
 *
 * @param client		Client index.
 * @param steamID		SteamID32 of the player.
 * @param mapID 		MapID from the "Maps" database table.
 * @param course    	Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode			Player's movement mode.
 * @param style			Player's movement style.
 * @param runTime		Player's end time.
 * @param teleportsUsed	Number of teleportsUsed used by player.
 * @param firstTime		Whether this is player's first time on this course.
 * @param pbDiff		Difference between new time and PB in seconds.
 * @param rank			New rank of the player's PB time.
 * @param maxRank		New total number of players with times.
 * @param firstTimePro	Whether this is player's first PRO time on this course.
 * @param pbDiffPro		Difference between new time and PRO PB seconds.
 * @param rankPro		New rank of the player's PB PRO time.
 * @param maxRankPro	New total number of players with PRO times.
 * @noreturn
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
 * @param steamID			SteamID32 of the player.
 * @param mapID 			MapID from the "Maps" table.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param style				Player's movement style.
 * @param recordType		Type of record.
 * @noreturn
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
 * Called when a player misses a local record.
 *
 * @param client			Client index.
 * @param float				Record time missed.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param style				Player's movement style.
 * @param recordType		Type of record.
 * @noreturn
 */
forward void GOKZ_LR_OnRecordMissed(int client, float recordTime, int course, int mode, int style, int recordType);



// =========================  DEPENDENCY  ========================= //

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