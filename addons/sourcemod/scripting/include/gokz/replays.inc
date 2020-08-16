/*
	gokz-replays Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_replays_included_
#endinput
#endif
#define _gokz_replays_included_



// =====[ CONSTANTS ]=====

#define RP_DIRECTORY "data/gokz-replays" // In Path_SM
#define RP_DIRECTORY_CHEATERS "data/gokz-replays/_cheaters" // In Path_SM
#define RP_FILE_EXTENSION "replay"
#define RP_MAGIC_NUMBER 0x676F6B7A
#define RP_FORMAT_VERSION 0x01
#define RP_NAV_FILE "maps/gokz-replays.nav"
#define RP_TICK_DATA_BLOCKSIZE 7
#define RP_CACHE_BLOCKSIZE 4
#define RP_MAX_BOTS 2
#define RP_PLAYBACK_BREATHER_TIME 2.0
#define RP_MIN_CHEATER_REPLAY_LENGTH 3840 // 30 seconds
#define RP_MAX_CHEATER_REPLAY_LENGTH 15360 // 2 minutes
#define RP_MAX_BHOP_GROUND_TICKS 5
#define RP_SKIP_TICKS 1280 // 10 seconds



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
