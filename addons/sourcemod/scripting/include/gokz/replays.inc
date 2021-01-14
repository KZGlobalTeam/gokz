/*
	gokz-replays Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_replays_included_
#endinput
#endif
#define _gokz_replays_included_

#include <gokz/anticheat>



// =====[ ENUMS ]=====
enum
{
	ReplayType_Run = 0,
	ReplayType_Cheater,
	ReplayType_Jump,
	REPLAYTYPE_COUNT
};

/*enum (<<= 1)
{
	RP_MOVETYPE_WALK = 1 << 0,
	RP_MOVETYPE_LADDER,
	RP_MOVETYPE_NOCLIP,
	RP_MOVETYPE_NONE,
	RP_IN_ATTACK,
	RP_IN_ATTACK2,
	RP_IN_JUMP,
	RP_IN_DUCK,
	RP_IN_FORWARD,
	RP_IN_BACK,
	RP_IN_LEFT,
	RP_IN_RIGHT,
	RP_IN_MOVELEFT,
	RP_IN_MOVERIGHT,
	RP_IN_RELOAD,
	RP_IN_SPEED,
	RP_FL_ONGROUND,
	RP_FL_DUCKING,
	RP_FL_SWIM,
	RP_UNDER_WATER,
	RP_TELEPORT_TICK,
	RP_TAKEOFF_TICK,
	RP_HIT_PERF,
	RP_SECONDARY_EQUIPPED,
};*/


// =====[ STRUCTS ] =====

enum struct GeneralReplayHeader
{
	int magicNumber;
	int formatVersion;
	int replayType;
	char gokzVersion[32];
	char mapName[64];
	int mapFileSize;
	int serverIP;
	int timestamp;
    char playerAlias[MAX_NAME_LENGTH];
    int playerSteamID;
    int mode;
    int style;
    float tickrate;
    int tickCount;
	int equippedWeapon;
	int equippedKnife;
}

enum struct JumpReplayHeader
{
	int jumpType;
	float distance;
	int blockDistance;
	int strafeCount;
}

enum struct CheaterReplayHeader
{
	ACReason ACReason;
}

enum struct RunReplayHeader
{
	float time;
	int course;
	int teleportsUsed;
}

enum struct ReplayTickData
{
	float origin[3];
	float angles[3];
	int flags;
	float speed;
}



// =====[ CONSTANTS ]=====

#define RP_DIRECTORY "data/gokz-replays" // In Path_SM
#define RP_DIRECTORY_RUNS "data/gokz-replays/_runs" // In Path_SM
#define RP_DIRECTORY_CHEATERS "data/gokz-replays/_cheaters" // In Path_SM
#define RP_DIRECTORY_JUMPS "data/gokz-replays/_jumps" // In Path_SM
#define RP_FILE_EXTENSION "replay"
#define RP_MAGIC_NUMBER 0x676F6B7A
#define RP_FORMAT_VERSION 0x02
#define RP_NAV_FILE "maps/gokz-replays.nav"
#define RP_TICK_DATA_BLOCKSIZE 7
#define RP_CACHE_BLOCKSIZE 4
#define RP_MAX_BOTS 2
#define RP_PLAYBACK_BREATHER_TIME 2.0
#define RP_MIN_CHEATER_REPLAY_LENGTH 30 // 30 seconds
#define RP_MAX_CHEATER_REPLAY_LENGTH 120 // 2 minutes
#define RP_MAX_BHOP_GROUND_TICKS 5
#define RP_SKIP_TICKS 10 // 10 seconds


#define RP_MOVETYPE_WALK		(1 << 0)
#define RP_MOVETYPE_LADDER		(1 << 1)
#define RP_MOVETYPE_NOCLIP		(1 << 2)
#define RP_MOVETYPE_NONE		(1 << 3)
#define RP_IN_ATTACK			(1 << 4)
#define RP_IN_ATTACK2			(1 << 5)
#define RP_IN_JUMP				(1 << 6)
#define RP_IN_DUCK				(1 << 7)
#define RP_IN_FORWARD			(1 << 8)
#define RP_IN_BACK				(1 << 9)
#define RP_IN_LEFT				(1 << 10)
#define RP_IN_RIGHT				(1 << 11)
#define RP_IN_MOVELEFT			(1 << 12)
#define RP_IN_MOVERIGHT			(1 << 13)
#define RP_IN_RELOAD			(1 << 14)
#define RP_IN_SPEED				(1 << 15)
#define RP_FL_ONGROUND			(1 << 16)
#define RP_FL_DUCKING			(1 << 17)
#define RP_FL_SWIM				(1 << 18)
#define RP_UNDER_WATER			(1 << 19)
#define RP_TELEPORT_TICK		(1 << 20)
#define RP_TAKEOFF_TICK			(1 << 21)
#define RP_HIT_PERF				(1 << 22)
#define RP_EQUIPPED_WEAPON		(1 << 23)




// =====[ FORWARDS ]=====

/**
 * Called when a replay of a player is written to disk.
 * This includes replays of cheaters which are saved if
 * the player is marked as a cheater by gokz-localdb.
 *
 * @param client			Client index.
 * @param filePath			Replay file path.
 */
forward void GOKZ_RP_OnReplaySaved(int client, const char[] filePath);

/**
 * Called when a currently being recorded replay is discarded from
 * memory and recording has been stopped (without writing it to disk).
 *
 * @param client			Client index.
 */
forward void GOKZ_RP_OnReplayDiscarded(int client);

/**
 * Called when a player has ended their timer, and gokz-replays has
 * processed the time and has possibly written a replay to disk.
 *
 * @param client			Client index.
 * @param filePath			Replay file path, or "" if no replay saved.
 * @param course    		Course number.
 * @param time				Player's end time.
 * @param teleportsUsed		Number of teleports used by player.
 */
forward void GOKZ_RP_OnTimerEnd_Post(int client, const char[] filePath, int course, float time, int teleportsUsed);



// =====[ NATIVES ]====

/**
 * Called by the HUD to get the state of the current replay.
 *
 * @param client			Client index.
 * @param info				Struct to pass the values into.
 * @return					If successful
 */
native int GOKZ_RP_GetPlaybackInfo(int client, any[] info);



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_replays = 
{
	name = "gokz-replays", 
	file = "gokz-replays.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_replays_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_RP_GetPlaybackInfo");
}
#endif
