#include <sourcemod>

#include <emitsoundany>
#include <gokz>

#include <GlobalAPI-Core>
#include <gokz/core>
#include <gokz/antimacro>
#include <gokz/replays>
#include <gokz/globals>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/localdb>
#include <gokz/localranks>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Globals", 
	author = "DanZay", 
	description = "GOKZ Globals Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.global/gokz-globals.txt"

#define RECORD_SOUND_PATH "gokz/holyshit.mp3"

bool gB_GOKZLocalDB;
bool gB_APIKeyCheck;
bool gB_ModeCheck[MODE_COUNT];
char gC_CurrentMap[64];
char gC_CurrentMapPath[PLATFORM_MAX_PATH];
bool gB_InValidRun[MAXPLAYERS + 1];
bool gB_GloballyVerified[MAXPLAYERS + 1];

#include "gokz-globals/api.sp"
#include "gokz-globals/commands.sp"
#include "gokz-globals/convars.sp"
#include "gokz-globals/print_records.sp"
#include "gokz-globals/misc.sp"
#include "gokz-globals/send_time.sp"
#include "gokz-globals/menus/map_top.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	CreateNatives();
	RegPluginLibrary("gokz-globals");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-core.phrases");
	LoadTranslations("gokz-globals.phrases");
	
	CreateGlobalForwards();
	CreateConVars();
	CreateCommands();
}

public void OnAllPluginsLoaded()
{
	gB_GOKZLocalDB = LibraryExists("gokz-localdb");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gokz-localdb"))
	{
		gB_GOKZLocalDB = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gokz-localdb"))
	{
		gB_GOKZLocalDB = false;
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_PrintRecords(client);
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	KZPlayer player = new KZPlayer(client);
	int mode = player.mode;
	gB_InValidRun[client] = GlobalsEnabled(mode);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	if (gB_GloballyVerified[client] && gB_InValidRun[client])
	{
		SendTime(client, course, time, teleportsUsed);
	}
}

public void GOKZ_AM_OnPlayerSuspected(int client, AMReason reason, const char[] notes, const char[] stats)
{
	switch (reason)
	{
		case AMReason_BhopHack:GlobalAPI_BanPlayer(client, "bhop_hack", notes, stats);
		case AMReason_BhopMacro:GlobalAPI_BanPlayer(client, "bhop_macro", notes, stats);
	}
}

public void GlobalAPI_OnPlayer_Joined(int client, bool banned)
{
	gB_GloballyVerified[client] = !banned;
	
	if (banned && gB_GOKZLocalDB)
	{
		GOKZ_DB_SetCheater(client, true);
	}
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	SetupAPI();
	PrecacheSounds();
}

public void GlobalAPI_OnAPIKeyReloaded()
{
	GlobalAPI API;
	API.GetAuthStatus(OnAuthStatusCallback);
}

public void GOKZ_OnModeUnloaded(int mode)
{
	gB_ModeCheck[mode] = false;
}

public Action GOKZ_OnTimerNativeCalledExternally(Handle plugin)
{
	char pluginName[64];
	GetPluginInfo(plugin, PlInfo_Name, pluginName, sizeof(pluginName));
	LogMessage("gokz-core native called by \"%s\" was blocked.", pluginName);
	return Plugin_Stop;
}

public void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall)
{
	AnnounceNewTopTime(client, course, mode, timeType, rank, rankOverall);
}



// =========================  PRIVATE  ========================= //

static void SetupAPI()
{
	GlobalAPI API;
	API.GetMapName(gC_CurrentMap, sizeof(gC_CurrentMap));
	API.GetMapPath(gC_CurrentMapPath, sizeof(gC_CurrentMapPath));
	API.GetAuthStatus(OnAuthStatusCallback);
	API.GetModeInfo(GOKZ_GL_GetGlobalMode(Mode_Vanilla), OnModeInfoCallback, Mode_Vanilla);
	API.GetModeInfo(GOKZ_GL_GetGlobalMode(Mode_SimpleKZ), OnModeInfoCallback, Mode_SimpleKZ);
	API.GetModeInfo(GOKZ_GL_GetGlobalMode(Mode_KZTimer), OnModeInfoCallback, Mode_KZTimer);
}

public int OnAuthStatusCallback(bool failure, bool authenticated)
{
	if (failure)
	{
		LogError("Failed to check API key with Global API.");
		gB_APIKeyCheck = false;
	}
	else
	{
		if (!authenticated)
		{
			LogError("Global API key was found to be missing or invalid.");
		}
		gB_APIKeyCheck = authenticated;
	}
}

public int OnModeInfoCallback(bool failure, const char[] name, int latest_version, const char[] latest_version_description, int mode)
{
	if (failure)
	{
		LogError("Failed to check a mode version with Global API.");
	}
	else if (latest_version <= GOKZ_GetModeVersion(mode))
	{
		gB_ModeCheck[mode] = true;
	}
	else
	{
		gB_ModeCheck[mode] = false;
		LogError("Global API requires %s mode version %d (%s). You have version %d (%s).", 
			gC_ModeNames[mode], latest_version, latest_version_description, GOKZ_GetModeVersion(mode), GOKZ_VERSION);
	}
}

static void PrecacheSounds()
{
	char downloadPath[PLATFORM_MAX_PATH];
	FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", RECORD_SOUND_PATH);
	AddFileToDownloadsTable(downloadPath);
	PrecacheSoundAny(RECORD_SOUND_PATH);
} 