#include <sourcemod>

#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#include <gokz>

#include <gokz/core>
#include <gokz/localranks>
#include <gokz/replays>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Replays", 
	author = "DanZay", 
	description = "GOKZ Replays Plugin", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define MAX_BOTS 2
#define TICK_DATA_BLOCKSIZE 7
#define REPLAY_CACHE_BLOCKSIZE 4
#define PLAYBACK_BREATHER_TIME 2.0
#define BASE_NAV_FILE_PATH "maps/gokz-replays.nav"

bool gB_LateLoad;
char gC_CurrentMap[64];
bool gB_HideNameChange;
bool gB_NubRecordMissed[MAXPLAYERS + 1];
ArrayList g_ReplayInfoCache;
ConVar gCV_bot_quota;

#include "gokz-replays/commands.sp"
#include "gokz-replays/playback.sp"
#include "gokz-replays/recording.sp"
#include "gokz-replays/replaycache.sp"
#include "gokz-replays/replaymenu.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-replays");
	gB_LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	LoadTranslations("gokz-replays.phrases");
	
	CreateConVars();
	CreateCommands();
	CreateHooks();
	
	if (gB_LateLoad)
	{
		OnLateLoad();
	}
}

void OnLateLoad()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}



// =========================  GENERAL  ========================= //

public void OnMapStart()
{
	UpdateCurrentMap();
	if (!CheckForNavFile())
	{
		GenerateNavFile();
		return;
	}
	CreateReplaysDirectory(gC_CurrentMap);
	OnMapStart_ReplayCache();
}

public void OnConfigsExecuted()
{
	FindConVar("mp_autoteambalance").BoolValue = false;
	FindConVar("mp_limitteams").IntValue = 0;
	// Stop the bots!
	FindConVar("bot_stop").BoolValue = true;
	FindConVar("bot_chatter").SetString("off");
	FindConVar("bot_zombie").BoolValue = true;
	FindConVar("bot_join_after_player").BoolValue = false;
	FindConVar("bot_quota_mode").SetString("normal");
	gCV_bot_quota.IntValue = MAX_BOTS;
}

public Action Hook_SayText2(UserMsg msg_id, any msg, const int[] players, int playersNum, bool reliable, bool init)
{
	// Name change supression
	// Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer
	if (!gB_HideNameChange)
	{
		return Plugin_Continue;
	}
	
	char msgName[24];
	Protobuf pbmsg = msg;
	pbmsg.ReadString("msg_name", msgName, sizeof(msgName));
	if (StrEqual(msgName, "#Cstrike_Name_Change"))
	{
		gB_HideNameChange = false;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Block trigger and door interaction for bots
	// Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer
	
	// trigger_once | trigger_multiple.. etc
	// func_door | func_door_rotating
	if (StrContains(classname, "trigger_") != -1 || StrContains(classname, "_door") != -1)
	{
		SDKHook(entity, SDKHook_StartTouch, HookTriggers);
		SDKHook(entity, SDKHook_EndTouch, HookTriggers);
		SDKHook(entity, SDKHook_Touch, HookTriggers);
	}
}

public Action HookTriggers(int entity, int other)
{
	if (other >= 1 && other <= MaxClients && IsFakeClient(other))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] intValue)
{
	// Keep the bots in the server
	if (convar == gCV_bot_quota)
	{
		gCV_bot_quota.IntValue = MAX_BOTS;
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_Recording(client);
	OnClientPutInServer_Playback(client);
}

public void OnClientDisconnect(int client)
{
	OnClientDisconnect_Playback(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_Recording(client, buttons);
	OnPlayerRunCmd_Playback(client, buttons);
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	gB_NubRecordMissed[client] = false;
	GOKZ_OnTimerStart_Recording(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	GOKZ_OnTimerEnd_Recording(client, course, time, teleportsUsed);
}

public void GOKZ_OnPause_Post(int client)
{
	GOKZ_OnPause_Recording(client);
}

public void GOKZ_OnResume_Post(int client)
{
	GOKZ_OnResume_Recording(client);
}

public void GOKZ_OnTimerStopped(int client)
{
	GOKZ_OnTimerStopped_Recording(client);
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	GOKZ_OnCountedTeleport_Recording(client);
}

public void GOKZ_LR_OnRecordMissed(int client, float recordTime, int course, int mode, int style, int recordType)
{
	if (recordType == RecordType_Nub)
	{
		gB_NubRecordMissed[client] = true;
	}
	GOKZ_LR_OnRecordMissed_Recording(client, recordType);
}



// =========================  PRIVATE  ========================= //

static void CreateConVars()
{
	gCV_bot_quota = FindConVar("bot_quota");
	gCV_bot_quota.AddChangeHook(OnConVarChanged);
	gCV_bot_quota.Flags &= ~FCVAR_NOTIFY;
}

static void CreateHooks()
{
	HookUserMessage(GetUserMessageId("SayText2"), Hook_SayText2, true);
}

static void UpdateCurrentMap()
{
	GetCurrentMap(gC_CurrentMap, sizeof(gC_CurrentMap));
	GetMapDisplayName(gC_CurrentMap, gC_CurrentMap, sizeof(gC_CurrentMap));
	String_ToLower(gC_CurrentMap, gC_CurrentMap, sizeof(gC_CurrentMap));
}

static void CreateReplaysDirectory(const char[] map)
{
	char path[PLATFORM_MAX_PATH];
	
	// Create parent replay directory
	BuildPath(Path_SM, path, sizeof(path), REPLAY_DIRECTORY);
	if (!DirExists(path))
	{
		CreateDirectory(path, 511);
	}
	
	// Create map's replay directory
	BuildPath(Path_SM, path, sizeof(path), "%s/%s", REPLAY_DIRECTORY, map);
	if (!DirExists(path))
	{
		CreateDirectory(path, 511);
	}
}

static bool CheckForNavFile()
{
	// Make sure there's a nav file
	// Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer
	
	char mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapPath, sizeof(mapPath));
	
	char navFilePath[PLATFORM_MAX_PATH];
	FormatEx(navFilePath, PLATFORM_MAX_PATH, "maps/%s.nav", mapPath);
	
	return FileExists(navFilePath);
}

static void GenerateNavFile()
{
	// Generate (copy a) .nav file for the map
	// Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer
	
	char mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapPath, sizeof(mapPath));
	
	char[] navFilePath = new char[PLATFORM_MAX_PATH];
	FormatEx(navFilePath, PLATFORM_MAX_PATH, "maps/%s.nav", mapPath);
	
	if (!FileExists(BASE_NAV_FILE_PATH))
	{
		SetFailState("Could not generate .nav file because \"%s\" does not exist.", BASE_NAV_FILE_PATH);
	}
	File_Copy(BASE_NAV_FILE_PATH, navFilePath);
	ForceChangeLevel(gC_CurrentMap, "[gokz-replays] Generate .nav file.");
}

/*
 * Copies file source to destination
 * Based on code of javalia:
 * http://forums.alliedmods.net/showthread.php?t=159895
 *
 * Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer
 *
 * @param source		Input file
 * @param destination	Output file
 */
bool File_Copy(const char[] source, const char[] destination)
{
	File file_source = OpenFile(source, "rb");
	
	if (file_source == null)
	{
		return false;
	}
	
	File file_destination = OpenFile(destination, "wb");
	
	if (file_destination == null)
	{
		delete file_source;
		
		return false;
	}
	
	int[] buffer = new int[32];
	int cache = 0;
	
	while (!IsEndOfFile(file_source))
	{
		cache = ReadFile(file_source, buffer, 32, 1);
		
		file_destination.Write(buffer, cache, 1);
	}
	
	delete file_source;
	delete file_destination;
	
	return true;
} 