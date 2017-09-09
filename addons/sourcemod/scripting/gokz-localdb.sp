#include <sourcemod>

#include <sdktools>
#include <geoip>
#include <regex>

#include <gokz>

#include <gokz/core>
#include <gokz/localdb>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Local DB", 
	author = "DanZay", 
	description = "GOKZ Local Database Module", 
	version = "0.14.0", 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

Handle gH_OnDatabaseConnect;
Handle gH_OnClientSetup;
Handle gH_OnMapSetup;
Handle gH_OnTimeInserted;

bool gB_LateLoad;
Regex gRE_BonusStartButton;

Database gH_DB = null;
DatabaseType g_DBType = DatabaseType_None;
bool gB_MapSetUp;
int gI_DBCurrentMapID;

#include "gokz-localdb/api.sp"
#include "gokz-localdb/database.sp"

#include "gokz-localdb/database/sql.sp"
#include "gokz-localdb/database/create_tables.sp"
#include "gokz-localdb/database/load_options.sp"
#include "gokz-localdb/database/save_options.sp"
#include "gokz-localdb/database/save_time.sp"
#include "gokz-localdb/database/setup_client.sp"
#include "gokz-localdb/database/setup_database.sp"
#include "gokz-localdb/database/setup_map.sp"
#include "gokz-localdb/database/setup_map_courses.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-localdb");
	gB_LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	CreateGlobalForwards();
	CreateRegexes();
	
	DB_SetupDatabase();
	
	if (gB_LateLoad)
	{
		OnLateLoad();
	}
}

void OnLateLoad()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GOKZ_IsClientSetUp(client))
		{
			GOKZ_OnClientSetup(client);
		}
	}
}



// =========================  OTHER  ========================= //

public void GOKZ_OnClientSetup(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	DB_SetupClient(client);
	DB_LoadOptions(client);
}

public void GOKZ_DB_OnMapSetup(int mapID)
{
	DB_SetupMapCourses();
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	DB_SaveOptions(client);
}

public void OnMapStart()
{
	DB_SetupMap();
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	int mode = GOKZ_GetOption(client, Option_Mode);
	int style = GOKZ_GetOption(client, Option_Style);
	DB_SaveTime(client, course, mode, style, time, teleportsUsed);
}



// =========================  PRIVATE  ========================= //

static void CreateRegexes()
{
	gRE_BonusStartButton = CompileRegex("^climb_bonus(\\d+)_startbutton$");
} 