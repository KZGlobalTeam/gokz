#include <sourcemod>

#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#include <gokz/core>
#include <gokz/localranks>
#include <gokz/replays>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/localdb>
#include <gokz/hud>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Replays", 
	author = "DanZay", 
	description = "Records runs to disk and allows playback using bots", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-replays.txt"

bool gB_GOKZLocalDB;
char gC_CurrentMap[64];
bool gB_HideNameChange;
bool gB_NubRecordMissed[MAXPLAYERS + 1];
ArrayList g_ReplayInfoCache;
ConVar gCV_bot_quota;

#include "gokz-replays/commands.sp"
#include "gokz-replays/nav.sp"
#include "gokz-replays/playback.sp"
#include "gokz-replays/recording.sp"
#include "gokz-replays/replay_cache.sp"
#include "gokz-replays/replay_menu.sp"
#include "gokz-replays/api.sp"
#include "gokz-replays/controls.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-replays");
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (FloatAbs(1.0 / GetTickInterval() - 128.0) > EPSILON)
	{
		SetFailState("gokz-replays only supports 128 tickrate servers.");
	}
	
	LoadTranslations("gokz-replays.phrases");
	
	CreateGlobalForwards();
	CreateConVars();
	HookEvents();
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZLocalDB = LibraryExists("gokz-localdb");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZLocalDB = gB_GOKZLocalDB || StrEqual(name, "gokz-localdb");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZLocalDB = gB_GOKZLocalDB && !StrEqual(name, "gokz-localdb");
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	UpdateCurrentMap(); // Do first
	OnMapStart_Nav();
	OnMapStart_Recording();
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
	gCV_bot_quota.IntValue = RP_MAX_BOTS;
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

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] intValue)
{
	// Keep the bots in the server
	if (convar == gCV_bot_quota)
	{
		gCV_bot_quota.IntValue = RP_MAX_BOTS;
	}
}



// =====[ CLIENT EVENTS ]=====

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
	OnPlayerRunCmd_Playback(client, buttons);
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_Recording(client, buttons);
	OnPlayerRunCmdPost_ReplayControls(client, cmdnum);
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

public void GOKZ_AC_OnPlayerSuspected(int client)
{
	GOKZ_OnPlayerSuspected_Recording(client);
}



// =====[ PRIVATE ]=====

static void CreateConVars()
{
	gCV_bot_quota = FindConVar("bot_quota");
	gCV_bot_quota.Flags &= ~FCVAR_NOTIFY;
	gCV_bot_quota.AddChangeHook(OnConVarChanged);
}

static void HookEvents()
{
	HookUserMessage(GetUserMessageId("SayText2"), Hook_SayText2, true);
}

static void UpdateCurrentMap()
{
	GetCurrentMapDisplayName(gC_CurrentMap, sizeof(gC_CurrentMap));
} 