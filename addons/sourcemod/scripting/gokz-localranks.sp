#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <colorvariables>
#include <emitsoundany>
#include <gokz>

#include <gokz/core>
#include <gokz/localdb>
#include <gokz/localranks>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Local Ranks", 
	author = "DanZay", 
	description = "GOKZ Local Ranks Module", 
	version = "0.14.0", 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define SOUNDS_CFG_PATH "cfg/sourcemod/gokz/gokz-localranks-sounds.cfg"

bool gB_LateLoad;

Database gH_DB = null;
DatabaseType g_DBType = DatabaseType_None;

Menu gH_MapTopMenu[MAXPLAYERS + 1];
Menu gH_MapTopSubMenu[MAXPLAYERS + 1];
char gC_MapTopMapName[MAXPLAYERS + 1][64];
int gI_MapTopMapID[MAXPLAYERS + 1];
int gI_MapTopCourse[MAXPLAYERS + 1];
int g_MapTopMode[MAXPLAYERS + 1];

Menu gH_PlayerTopMenu[MAXPLAYERS + 1];
Menu gH_PlayerTopSubMenu[MAXPLAYERS + 1];
int g_PlayerTopMode[MAXPLAYERS + 1];

bool gB_RecordExistsCache[MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
float gF_RecordTimesCache[MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
bool gB_RecordMissed[MAXPLAYERS + 1][TIMETYPE_COUNT];

bool gB_PBExistsCache[MAXPLAYERS + 1][MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
float gF_PBTimesCache[MAXPLAYERS + 1][MAX_COURSES][MODE_COUNT][TIMETYPE_COUNT];
bool gB_PBMissed[MAXPLAYERS + 1][TIMETYPE_COUNT];

char gC_BeatRecordSound[256];

#include "gokz-localranks/database/sql.sp"

#include "gokz-localranks/api.sp"
#include "gokz-localranks/commands.sp"
#include "gokz-localranks/database.sp"
#include "gokz-localranks/misc.sp"

#include "gokz-localranks/database/cache_pbs.sp"
#include "gokz-localranks/database/cache_records.sp"
#include "gokz-localranks/database/create_tables.sp"
#include "gokz-localranks/database/get_completion.sp"
#include "gokz-localranks/database/open_maptop.sp"
#include "gokz-localranks/database/open_maptop20.sp"
#include "gokz-localranks/database/open_playertop20.sp"
#include "gokz-localranks/database/print_average.sp"
#include "gokz-localranks/database/print_pbs.sp"
#include "gokz-localranks/database/print_records.sp"
#include "gokz-localranks/database/process_new_time.sp"
#include "gokz-localranks/database/update_ranked_map_pool.sp"

#include "gokz-localranks/menus/maptop.sp"
#include "gokz-localranks/menus/playertop.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-localranks");
	gB_LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	LoadTranslations("gokz-core.phrases");
	LoadTranslations("gokz-localranks.phrases");
	
	CreateMenus();
	CreateGlobalForwards();
	CreateCommands();
	
	TryGetDatabaseInfo();
	
	if (gB_LateLoad)
	{
		OnLateLoad();
	}
}

void OnLateLoad()
{
	if (GOKZ_DB_IsMapSetUp())
	{
		GOKZ_DB_OnMapSetup(GOKZ_DB_GetCurrentMapID());
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GOKZ_DB_IsClientSetUp(client))
		{
			GOKZ_DB_OnClientSetup(client, GetSteamAccountID(client));
		}
	}
}



// =========================  GOKZ  ========================= //

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	ResetRecordMissed(client);
	ResetPBMissed(client);
}

public Action GOKZ_OnTimerEndMessage(int client, int course, float time, int teleportsUsed)
{
	// Block timer end messages from GOKZ Core - this plugin handles them
	return Plugin_Stop;
}

public void GOKZ_DB_OnDatabaseConnect(Database database, DatabaseType DBType)
{
	gH_DB = database;
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

public void GOKZ_DB_OnClientSetup(int client, int steamID)
{
	if (GOKZ_DB_IsMapSetUp())
	{
		DB_CachePBs(client, steamID);
	}
}

public void GOKZ_DB_OnTimeInserted(int client, int steamID, int mapID, int course, int mode, int style, int runTimeMS, int teleportsUsed)
{
	DB_ProcessNewTime(client, steamID, mapID, course, mode, style, runTimeMS, teleportsUsed);
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
	
	if (course == 0 && mode == GOKZ_GetDefaultMode() && firstTimePro)
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



// =========================  OTHER  ========================= //

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	UpdateRecordMissed(client);
	UpdatePBMissed(client);
}

public void OnMapStart()
{
	OnMapStart_Announcements();
}



// =========================  PRIVATE  ========================= //

static void CreateMenus()
{
	MapTopMenuCreateMenus();
	PlayerTopMenuCreateMenus();
}

static void TryGetDatabaseInfo()
{
	GOKZ_DB_GetDatabase(gH_DB);
	if (gH_DB != null)
	{
		g_DBType = GOKZ_DB_GetDatabaseType();
		DB_CreateTables();
		CompletionMVPStarsUpdateAll();
	}
} 