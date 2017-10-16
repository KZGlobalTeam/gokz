#include <sourcemod>

#include <emitsoundany>
#include <gokz>

#include <GlobalAPI-Core>
#include <gokz/core>
#include <gokz/replays>
#include <gokz/globals>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Globals", 
	author = "DanZay & Sikari", 
	description = "GOKZ Globals Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.simplekz.com/gokz-globals.txt"

#define RECORD_SOUND_PATH "gokz/holyshit.mp3"

bool gB_APIKeyCheck = false;
bool gB_VersionCheck = false;
char gC_CurrentMap[64];
char gC_CurrentMapPath[PLATFORM_MAX_PATH];

#include "gokz-globals/api.sp"
#include "gokz-globals/commands.sp"
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
	CreateCommands();
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_PrintRecords(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	SendTime(client, course, time, teleportsUsed);
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	SetupAPI();
	PrecacheSounds();
}

public void API_OnAPIKeyReloaded()
{
	GlobalAPI API;
	API.GetAuthStatus(OnAuthStatusCallback);
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
	API.GetModeInfo("kz_simple", OnModeInfoCallback); // TODO Other modes/better version checking
}

public int OnAuthStatusCallback(bool failure, bool authenticated)
{
	if (failure)
	{
		LogError("Failed to check API key with global API.");
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

public int OnModeInfoCallback(bool failure, const char[] name, int latest_version, const char[] latest_version_description)
{
	if (failure)
	{
		LogError("Failed to check mode version with global API.");
		gB_VersionCheck = false;
	}
	else
	{
		if (!StrEqual(GOKZ_VERSION, latest_version_description))
		{
			LogError("Global API requires GOKZ %s. You have GOKZ %s.", latest_version_description, GOKZ_VERSION);
			gB_VersionCheck = false;
		}
		else
		{
			gB_VersionCheck = true;
		}
	}
}

static void PrecacheSounds()
{
	char downloadPath[PLATFORM_MAX_PATH];
	FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", RECORD_SOUND_PATH);
	AddFileToDownloadsTable(downloadPath);
	PrecacheSoundAny(RECORD_SOUND_PATH);
} 