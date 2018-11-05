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