#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>
#include <gokz/localdb>
#include <gokz/localranks>

#include <sourcemod-colors>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/global>
#include <gokz/jumpstats>
#include <gokz/replays>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Local Ranks", 
	author = "DanZay", 
	description = "Extends and provides in-game functionality for local database", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-localranks.txt"

bool gB_GOKZGlobal;
Database gH_DB = null;
DatabaseType g_DBType = DatabaseType_None;
bool gB_RecordExistsCache[GOKZ_MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
float gF_RecordTimesCache[GOKZ_MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
bool gB_RecordMissed[MAXPLAYERS + 1][TIMETYPE_COUNT];
bool gB_PBExistsCache[MAXPLAYERS + 1][GOKZ_MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
float gF_PBTimesCache[MAXPLAYERS + 1][GOKZ_MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
bool gB_PBMissed[MAXPLAYERS + 1][TIMETYPE_COUNT];
char gC_BeatRecordSound[256];


#include "gokz-localranks/api.sp"
#include "gokz-localranks/commands.sp"
#include "gokz-localranks/misc.sp"

#include "gokz-localranks/db/sql.sp"
#include "gokz-localranks/db/helpers.sp"
#include "gokz-localranks/db/cache_pbs.sp"
#include "gokz-localranks/db/cache_records.sp"
#include "gokz-localranks/db/create_tables.sp"
#include "gokz-localranks/db/get_completion.sp"
#include "gokz-localranks/db/js_top.sp"
#include "gokz-localranks/db/map_top.sp"
#include "gokz-localranks/db/player_top.sp"
#include "gokz-localranks/db/print_average.sp"
#include "gokz-localranks/db/print_js.sp"
#include "gokz-localranks/db/print_pbs.sp"
#include "gokz-localranks/db/print_records.sp"
#include "gokz-localranks/db/process_new_time.sp"
#include "gokz-localranks/db/recent_records.sp"
#include "gokz-localranks/db/update_ranked_map_pool.sp"
#include "gokz-localranks/db/display_js.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-localranks");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-localranks.phrases");
	
	CreateGlobalForwards();
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZGlobal = LibraryExists("gokz-global");
	
	gH_DB = GOKZ_DB_GetDatabase();
	if (gH_DB != null)
	{
		g_DBType = GOKZ_DB_GetDatabaseType();
		DB_CreateTables();
		CompletionMVPStarsUpdateAll();
	}
	
	if (GOKZ_DB_IsMapSetUp())
	{
		GOKZ_DB_OnMapSetup(GOKZ_DB_GetCurrentMapID());
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (GOKZ_DB_IsClientSetUp(i))
		{
			GOKZ_DB_OnClientSetup(i, GetSteamAccountID(i), GOKZ_DB_IsCheater(i));
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZGlobal = gB_GOKZGlobal || StrEqual(name, "gokz-global");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZGlobal = gB_GOKZGlobal && !StrEqual(name, "gokz-global");
}



// =====[ CLIENT EVENTS ]=====

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	UpdateRecordMissed(client);
	UpdatePBMissed(client);
	return Plugin_Continue;
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	ResetRecordMissed(client);
	ResetPBMissed(client);
}

public void GOKZ_DB_OnClientSetup(int client, int steamID, bool cheater)
{
	if (GOKZ_DB_IsMapSetUp())
	{
		DB_CachePBs(client, steamID);
		CompletionMVPStarsUpdate(client);
	}
}

public void GOKZ_DB_OnTimeInserted(int client, int steamID, int mapID, int course, int mode, int style, int runTimeMS, int teleportsUsed)
{
	if (GOKZ_DB_IsCheater(client))
	{
		DB_CachePBs(client, GetSteamAccountID(client));
	}
	else
	{
		DB_ProcessNewTime(client, steamID, mapID, course, mode, style, runTimeMS, teleportsUsed);
	}
}

public void GOKZ_LR_OnTimeProcessed(
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
	int maxRankPro)
{
	if (mapID != GOKZ_DB_GetCurrentMapID())
	{
		return;
	}
	
	AnnounceNewTime(client, course, mode, runTime, teleportsUsed, firstTime, pbDiff, rank, maxRank, firstTimePro, pbDiffPro, rankPro, maxRankPro);
	
	if (mode == GOKZ_GetDefaultMode() && firstTimePro)
	{
		CompletionMVPStarsUpdate(client);
	}
	
	// If new PB, update PB cache
	if (firstTime || firstTimePro || pbDiff < 0.0 || pbDiffPro < 0.0)
	{
		DB_CachePBs(client, GetSteamAccountID(client));
	}
}

public void GOKZ_LR_OnNewRecord(int client, int steamID, int mapID, int course, int mode, int style, int recordType)
{
	if (mapID != GOKZ_DB_GetCurrentMapID())
	{
		return;
	}
	
	AnnounceNewRecord(client, course, mode, recordType);
	DB_CacheRecords(mapID);
}

public void GOKZ_LR_OnPBMissed(int client, float pbTime, int course, int mode, int style, int recordType)
{
	DoPBMissedReport(client, pbTime, recordType);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	PrecacheAnnouncementSounds();
}

public void GOKZ_DB_OnDatabaseConnect(DatabaseType DBType)
{
	gH_DB = GOKZ_DB_GetDatabase();
	g_DBType = DBType;
	DB_CreateTables();
	CompletionMVPStarsUpdateAll();
}

public void GOKZ_DB_OnMapSetup(int mapID)
{
	DB_CacheRecords(mapID);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GOKZ_DB_IsClientSetUp(client))
		{
			DB_CachePBs(client, GetSteamAccountID(client));
		}
	}
}

public Action GOKZ_OnTimerEndMessage(int client, int course, float time, int teleportsUsed)
{
	if (GOKZ_DB_IsCheater(client))
	{
		return Plugin_Continue;
	}
	
	// Block timer end messages from GOKZ Core - this plugin handles them
	return Plugin_Stop;
} 