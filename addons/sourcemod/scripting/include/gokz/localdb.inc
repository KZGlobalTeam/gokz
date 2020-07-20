/*
	gokz-localdb Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_localdb_included_
#endinput
#endif
#define _gokz_localdb_included_



// =====[ ENUMS ]=====

enum DatabaseType
{
	DatabaseType_None = -1, 
	DatabaseType_MySQL, 
	DatabaseType_SQLite
};

enum
{
	JumpstatDB_Lookup_JumpID = 0, 
	JumpstatDB_Lookup_Distance, 
	JumpstatDB_Lookup_Block
};

enum
{
	JumpstatDB_FindPlayer_SteamID32 = 0, 
	JumpstatDB_FindPlayer_Alias
};

enum
{
	JumpstatDB_Top20_SteamID = 0, 
	JumpstatDB_Top20_Alias, 
	JumpstatDB_Top20_Block, 
	JumpstatDB_Top20_Distance, 
	JumpstatDB_Top20_Strafes, 
	JumpstatDB_Top20_Sync, 
	JumpstatDB_Top20_Pre, 
	JumpstatDB_Top20_Max, 
	JumpstatDB_Top20_Air
};

enum
{
	JumpstatDB_Cache_Distance = 0, 
	JumpstatDB_Cache_Block, 
	JumpstatDB_Cache_BlockDistance, 
	JUMPSTATDB_CACHE_COUNT
};

enum
{
	TimerSetupDB_GetVBPos_SteamID = 0, 
	TimerSetupDB_GetVBPos_MapID, 
	TimerSetupDB_GetVBPos_Course, 
	TimerSetupDB_GetVBPos_IsStart, 
	TimerSetupDB_GetVBPos_PositionX, 
	TimerSetupDB_GetVBPos_PositionY, 
	TimerSetupDB_GetVBPos_PositionZ
};

enum
{
	TimerSetupDB_GetStartPos_SteamID = 0, 
	TimerSetupDB_GetStartPos_MapID, 
	TimerSetupDB_GetStartPos_PositionX, 
	TimerSetupDB_GetStartPos_PositionY, 
	TimerSetupDB_GetStartPos_PositionZ, 
	TimerSetupDB_GetStartPos_Angle0, 
	TimerSetupDB_GetStartPos_Angle1
};

enum DBOption:
{
	DBOption_AutoLoadTimerSetup = 0, 
	DBOPTION_COUNT
};

enum
{
	DBOption_Disabled = 0, 
	DBOption_Enabled, 
	DBOPTIONBOOL_COUNT
};



// =====[ CONSTANTS ]=====

#define GOKZ_DB_JS_DISTANCE_PRECISION 10000
#define GOKZ_DB_JS_SYNC_PRECISION 100
#define GOKZ_DB_JS_PRE_PRECISION 100
#define GOKZ_DB_JS_MAX_PRECISION 100
#define GOKZ_DB_JS_AIRTIME_PRECISION 10000
#define GOKZ_DB_JS_MAX_JUMPS_PER_PLAYER 20

stock char gC_DBOptionNames[DBOPTION_COUNT][] = 
{
	"GOKZ DB - Auto Load Timer Setup"
};

stock char gC_DBOptionDescriptions[DBOPTION_COUNT][] = 
{
	"Automatically load timer setup on map start - 0 = Disabled, 1 = Enabled"
}

stock int gI_DBOptionDefaultValues[DBOPTION_COUNT] = 
{
	DBOption_Disabled
};

stock int gI_DBOptionCounts[DBOPTION_COUNT] = 
{
	DBOPTIONBOOL_COUNT
};

stock char gC_DBOptionPhrases[DBOPTION_COUNT][] = 
{
	"Options Menu - Auto Load Timer Setup"
};



// =====[ TYPES ]=====

typeset GetVBPositionCallback
{
	function Action(int client, const float position[3], int course, bool isStart);
};

typeset GetStartPositionCallback
{
	function Action(int client, const float position[3], const float angles[3]);
};



// =====[ FORWARDS ]=====

/**
 * Called when gokz-localdb has connected to the database.
 * Use GOKZ_DB_GetDatabase to get a clone of the database handle.
 *
 * @param DBType		Database type.
 */
forward void GOKZ_DB_OnDatabaseConnect(DatabaseType DBType);

/**
 * Called when a player is ready for database interaction.
 * At this point, the player is present and updated in the "Players" table.
 *
 * @param client		Client index.
 * @param steamID		SteamID32 of the player (from GetSteamAccountID()).
 * @param cheater		Whether player is marked as a cheater in the database.
 */
forward void GOKZ_DB_OnClientSetup(int client, int steamID, bool cheater);

/**
 * Called when the current map is ready for database interaction.
 * At this point, the map is present and updated in the "Maps" table.
 *
 * @param mapID			MapID from the "Maps" table.
 */
forward void GOKZ_DB_OnMapSetup(int mapID);

/**
 * Called when a time has been inserted into the database.
 *
 * @param client			Client index.
 * @param steamID			SteamID32 of the player (from GetSteamAccountID()).
 * @param mapID				MapID from the "Maps" table.
 * @param course    		Course number e.g. 0=main, 1='bonus1' etc.
 * @param mode				Player's movement mode.
 * @param style				Player's movement style.
 * @param runTimeMS			Player's end time in milliseconds.
 * @param teleportsUsed		Number of teleports used by player.
 */
forward void GOKZ_DB_OnTimeInserted(
	int client, 
	int steamID, 
	int mapID, 
	int course, 
	int mode, 
	int style, 
	int runTimeMS, 
	int teleportsUsed);



// =====[ NATIVES ]=====

/**
 * Gets a clone of the GOKZ local database handle.
 *
 * @param database		Database handle, or null if connection hasn't been made.
 */
native Database GOKZ_DB_GetDatabase();

/**
 * Gets the GOKZ local database type.
 *
 * @return				Database type.
 */
native DatabaseType GOKZ_DB_GetDatabaseType();

/**
 * Gets whether client has been set up for GOKZ Local DB.
 *
 * @param client		Client index.
 * @return				Whether GOKZ Local DB has set up the client.
 */
native bool GOKZ_DB_IsClientSetUp(int client);

/**
 * Gets whether GOKZ Local DB is set up for the current map.
 *
 * @return				Whether GOKZ Local DB has set up the current map.
 */
native bool GOKZ_DB_IsMapSetUp();

/**
 * Gets the current map's MapID as in the "Maps" table.
 *
 * @return				MapID from the "Maps" table.
 */
native int GOKZ_DB_GetCurrentMapID();

/**
 * Gets whether player is marked as a cheater in the database.
 *
 * @param client		Client index.
 * @return				Whether player is marked as a cheater in the database.
 */
native bool GOKZ_DB_IsCheater(int client);

/**
 * Sets wheter player is marked as a cheater in the database.
 *
 * @param client		Client index.
 * @param cheater		Whether to mark the player as a cheater.
 */
native void GOKZ_DB_SetCheater(int client, bool cheater);



// =====[ STOCKS ]=====

/**
 * Converts a time float (seconds) to an integer (milliseconds).
 *
 * @param time			Time in seconds.
 * @return				Time in milliseconds.
 */
stock int GOKZ_DB_TimeFloatToInt(float time)
{
	return RoundFloat(time * 1000.0);
}

/**
 * Converts a time integer (milliseconds) to a float (seconds).
 *
 * @param time			Time in milliseconds.
 * @return				Time in seconds.
 */
stock float GOKZ_DB_TimeIntToFloat(int time)
{
	return time / 1000.0;
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_localdb = 
{
	name = "gokz-localdb", 
	file = "gokz-localdb.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_localdb_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_DB_GetDatabase");
	MarkNativeAsOptional("GOKZ_DB_GetDatabaseType");
	MarkNativeAsOptional("GOKZ_DB_IsClientSetUp");
	MarkNativeAsOptional("GOKZ_DB_IsMapSetUp");
	MarkNativeAsOptional("GOKZ_DB_GetCurrentMapID");
	MarkNativeAsOptional("GOKZ_DB_IsCheater");
	MarkNativeAsOptional("GOKZ_DB_SetCheater");
}
#endif
