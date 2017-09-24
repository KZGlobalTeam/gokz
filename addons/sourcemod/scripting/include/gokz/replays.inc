/* 	
	GOKZ Replays Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_replays_included_
#endinput
#endif
#define _gokz_replays_included_



// =========================  DEFINITIONS  ========================= //

#define REPLAY_DIRECTORY "data/gokz-replays" // In Path_SM
#define REPLAY_FILE_EXTENSION "rec"
#define REPLAY_MAGIC_NUMBER 0x676F6B7A
#define REPLAY_FORMAT_VERSION 0x01



// =========================  DEPENDENCY  ========================= //

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