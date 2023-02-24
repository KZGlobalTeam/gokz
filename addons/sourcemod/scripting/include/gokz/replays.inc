/*
	gokz-replays Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_replays_included_
#endinput
#endif
#define _gokz_replays_included_

// Bit of a hack, but need it for other plugins that depend on replays to compile
#if defined REQUIRE_PLUGIN
#undef REQUIRE_PLUGIN
#include <gokz/anticheat>
#define REQUIRE_PLUGIN
#else
#include <gokz/anticheat>
#endif



// =====[ ENUMS ]=====
enum
{
	ReplayType_Run = 0,
	ReplayType_Cheater,
	ReplayType_Jump,
	REPLAYTYPE_COUNT
};

enum ReplaySaveState
{
	ReplaySave_Local = 0,
	ReplaySave_Temp,
	ReplaySave_Disabled
};

// NOTE: Replays use delta compression for storage.
// This enum is the indices of the ReplayTickData enum struct.
// NOTE: This has to match the ReplayTickData enum struct!!!
enum
{
	RPDELTA_DELTAFLAGS = 0,
	RPDELTA_DELTAFLAGS2,
	RPDELTA_VEL_X,
	RPDELTA_VEL_Y,
	RPDELTA_VEL_Z,
	RPDELTA_MOUSE_X,
	RPDELTA_MOUSE_Y,
	RPDELTA_ORIGIN_X,
	RPDELTA_ORIGIN_Y,
	RPDELTA_ORIGIN_Z,
	RPDELTA_ANGLES_X,
	RPDELTA_ANGLES_Y,
	RPDELTA_ANGLES_Z,
	RPDELTA_VELOCITY_X,
	RPDELTA_VELOCITY_Y,
	RPDELTA_VELOCITY_Z,
	RPDELTA_FLAGS,
	RPDELTA_PACKETSPERSECOND,
	RPDELTA_LAGGEDMOVEMENTVALUE,
	RPDELTA_BUTTONSFORCED,
	
	RP_V2_TICK_DATA_BLOCKSIZE
};



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
	float playerSensitivity;
	float playerMYaw;
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
	float sync;
	float pre;
	float max;
	int airtime;
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

// NOTE: Make sure to change the RPDELTA_* enum, TickDataToArray() and TickDataFromArray() when adding/removing stuff from this!!!
enum struct ReplayTickData
{
	int deltaFlags;
	int deltaFlags2;
	float vel[3];
	int mouse[2];
	float origin[3];
	float angles[3];
	float velocity[3];
	int flags;
	float packetsPerSecond;
	float laggedMovementValue;
	int buttonsForced;
}



// =====[ CONSTANTS ]=====

#define RP_DIRECTORY "data/gokz-replays" // In Path_SM
#define RP_DIRECTORY_RUNS "data/gokz-replays/_runs" // In Path_SM
#define RP_DIRECTORY_RUNS_TEMP "data/gokz-replays/_tempRuns" // In Path_SM
#define RP_DIRECTORY_CHEATERS "data/gokz-replays/_cheaters" // In Path_SM
#define RP_DIRECTORY_JUMPS "data/gokz-replays/_jumps" // In Path_SM
#define RP_DIRECTORY_BLOCKJUMPS "blocks"
#define RP_FILE_EXTENSION "replay"
#define RP_MAGIC_NUMBER 0x676F6B7A
#define RP_FORMAT_VERSION 0x02
#define RP_NAV_FILE "maps/gokz-replays.nav"
#define RP_V1_TICK_DATA_BLOCKSIZE 7
#define RP_CACHE_BLOCKSIZE 4
#define RP_MAX_BOTS 4
#define RP_PLAYBACK_BREATHER_TIME 2.0
#define RP_MIN_CHEATER_REPLAY_LENGTH 30 // 30 seconds
#define RP_MAX_CHEATER_REPLAY_LENGTH 120 // 2 minutes
#define RP_MAX_BHOP_GROUND_TICKS 5
#define RP_SKIP_TIME 10 // 10 seconds
#define RP_MAX_DURATION 6451200 // 14 hours on 128 tick
#define RP_JUMP_STEP_SOUND_THRESHOLD 140.0
#define RP_PLAYER_ACCELSPEED 450.0

#define RP_MOVETYPE_MASK		(0xF)
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
#define RP_IN_USE				(1 << 16)
#define RP_IN_BULLRUSH			(1 << 17)
#define RP_FL_ONGROUND			(1 << 18)
#define RP_FL_DUCKING			(1 << 19)
#define RP_FL_SWIM				(1 << 20)
#define RP_UNDER_WATER			(1 << 21)
#define RP_TELEPORT_TICK		(1 << 22)
#define RP_TAKEOFF_TICK			(1 << 23)
#define RP_HIT_PERF				(1 << 24)
#define RP_SECONDARY_EQUIPPED	(1 << 25)



// =====[ FORWARDS ]=====

/**
 * Called when a replay of a player is written to disk.
 * This includes replays of cheaters which are saved if
 * the player is marked as a cheater by gokz-localdb.
 *
 * @param client			The client ID of the player who completed the run.
 * @param replayType		The type of the replay (Run/Jump/Cheater).
 * @param map				The name of the map the run was completed on.
 * @param course			The specific course on the map the run was completed on.
 * @param timeType			The type of time (Pro/Nub).
 * @param time				The time the run was completed in.
 * @param filePath			Replay file path.
 * @param tempReplay		Whether the replay file should only be temporaily stored. 
 * @return					Plugin_Handled to take over the temporary replay deletion, Plugin_Continue to allow temporary replay deletion by the replay plugin.
 */
forward Action GOKZ_RP_OnReplaySaved(int client, int replayType, const char[] map, int course, int timeType, float time, const char[] filePath, bool tempReplay);

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

/**
 * Called by the LocalDB to initiate a replay of a jump
 *
 * @param client			Client index.
 * @param path				Path to the replay file.
 * @return					The client ID of the bot performing the replay.
 */
native int GOKZ_RP_LoadJumpReplay(int client, char[] path);

/**
 * Called by the HUD to show the replay control menu.
 *
 * @param client			Client index.
 */
native bool GOKZ_RP_UpdateReplayControlMenu(int client);


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
	MarkNativeAsOptional("GOKZ_RP_LoadJumpReplay");
	MarkNativeAsOptional("GOKZ_RP_UpdateReplayControlMenu");
}
#endif
