#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <colorvariables>
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

Handle gH_OnTimeProcessed;
Handle gH_OnNewRecord;

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

#include "gokz-localranks/database/sql.sp"

#include "gokz-localranks/api.sp"
#include "gokz-localranks/commands.sp"
#include "gokz-localranks/database.sp"
#include "gokz-localranks/misc.sp"

#include "gokz-localranks/database/create_tables.sp"
#include "gokz-localranks/database/get_completion.sp"
#include "gokz-localranks/database/open_maptop.sp"
#include "gokz-localranks/database/open_maptop20.sp"
#include "gokz-localranks/database/open_playertop20.sp"
#include "gokz-localranks/database/print_pbs.sp"
#include "gokz-localranks/database/print_records.sp"
#include "gokz-localranks/database/process_new_time.sp"
#include "gokz-localranks/database/update_ranked_map_pool.sp"

#include "gokz-localranks/menus/maptop.sp"
#include "gokz-localranks/menus/playertop.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-localranks");
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
}



// =========================  GOKZ  ========================= //

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
}

public void GOKZ_LR_OnNewRecord(int client, int steamID, int mapID, int course, int mode, int style, KZRecordType recordType)
{
	if (mapID != GOKZ_DB_GetCurrentMapID())
	{
		return;
	}
	
	AnnounceNewRecord(client, course, mode, recordType);
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