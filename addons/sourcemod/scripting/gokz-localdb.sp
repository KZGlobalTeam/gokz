#include <sourcemod>

#include <geoip>

#include <gokz/core>
#include <gokz/localdb>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/jumpstats>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Local DB", 
	author = "DanZay", 
	description = "Provides database for players, maps, courses and times", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-localdb.txt"

Database gH_DB = null;
DatabaseType g_DBType = DatabaseType_None;
bool gB_ClientSetUp[MAXPLAYERS + 1];
bool gB_ClientPostAdminChecked[MAXPLAYERS + 1];
bool gB_Cheater[MAXPLAYERS + 1];
int gI_PBJSCache[MAXPLAYERS + 1][MODE_COUNT][JUMPTYPE_COUNT][JUMPSTATDB_CACHE_COUNT];
bool gB_MapSetUp;
int gI_DBCurrentMapID;

#include "gokz-localdb/api.sp"
#include "gokz-localdb/commands.sp"
#include "gokz-localdb/options.sp"

#include "gokz-localdb/db/sql.sp"
#include "gokz-localdb/db/helpers.sp"
#include "gokz-localdb/db/cache_js.sp"
#include "gokz-localdb/db/create_tables.sp"
#include "gokz-localdb/db/save_js.sp"
#include "gokz-localdb/db/save_time.sp"
#include "gokz-localdb/db/set_cheater.sp"
#include "gokz-localdb/db/setup_client.sp"
#include "gokz-localdb/db/setup_database.sp"
#include "gokz-localdb/db/setup_map.sp"
#include "gokz-localdb/db/setup_map_courses.sp"
#include "gokz-localdb/db/timer_setup.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-localdb");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-localdb.phrases");
	
	CreateGlobalForwards();
	RegisterCommands();
	DB_SetupDatabase();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	
	char auth[32];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientAuthorized(client) && GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth)))
		{
			OnClientAuthorized(client, auth);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}



// =====[ OTHER EVENTS ]=====

public void OnConfigsExecuted()
{
	DB_SetupMap();
}

public void GOKZ_DB_OnMapSetup(int mapID)
{
	DB_SetupMapCourses();
	
	for (int client = 1; client < MAXPLAYERS + 1; client++)
	{
		if (IsValidClient(client) && !IsFakeClient(client) &&
			gB_ClientPostAdminChecked[client] &&
			GOKZ_GetOption(client, gC_DBOptionNames[DBOption_AutoLoadTimerSetup]) == DBOption_Enabled)
		{
			DB_LoadTimerSetup(client);
		}
	}
}

public void OnMapEnd()
{
	gB_MapSetUp = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	DB_SetupClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	// We need this after OnClientPutInServer cause that's where the VBs get reset
	gB_ClientPostAdminChecked[client] = true;
	
	if (gB_MapSetUp && GOKZ_GetOption(client, gC_DBOptionNames[DBOption_AutoLoadTimerSetup]) == DBOption_Enabled)
	{
		DB_LoadTimerSetup(client);
	}
}

public void GOKZ_DB_OnClientSetup(int client, int steamID, bool cheater)
{
	DB_CacheJSPBs(client, steamID);
}

public void GOKZ_OnOptionsLoaded(int client)
{
	if (gB_MapSetUp && gB_ClientPostAdminChecked[client] && GOKZ_GetOption(client, gC_DBOptionNames[DBOption_AutoLoadTimerSetup]) == DBOption_Enabled)
	{
		DB_LoadTimerSetup(client);
	}
}

public void OnClientDisconnect(int client)
{
	gB_ClientSetUp[client] = false;
	gB_ClientPostAdminChecked[client] = false;
}

public void GOKZ_OnCourseRegistered(int course)
{
	if (gB_MapSetUp)
	{
		DB_SetupMapCourse(course);
	}
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int style = GOKZ_GetCoreOption(client, Option_Style);
	DB_SaveTime(client, course, mode, style, time, teleportsUsed);
}

public void GOKZ_JS_OnLanding(Jump jump)
{
	OnLanding_SaveJumpstat(jump);
}
