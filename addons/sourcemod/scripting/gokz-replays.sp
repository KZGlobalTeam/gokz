#include <sourcemod>

#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#include <movementapi>

#include <gokz/core>
#include <gokz/localranks>
#include <gokz/replays>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/hud>
#include <gokz/jumpstats>
#include <gokz/localdb>
#include <updater>

#pragma newdecls required
#pragma semicolon 1

//#define DEBUG



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
int gI_CurrentMapFileSize;
bool gB_HideNameChange;
bool gB_NubRecordMissed[MAXPLAYERS + 1];
ArrayList g_ReplayInfoCache;

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
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-replays.phrases");
	
	CreateGlobalForwards();
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
	FindConVar("bot_quota").Flags &= ~FCVAR_NOTIFY;
	FindConVar("bot_quota").Flags &= ~FCVAR_REPLICATED;
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



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_Playback(client);
	OnClientPutInServer_Recording(client);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	OnClientAuthorized_Recording(client);
}

public void OnClientDisconnect(int client)
{
	OnClientDisconnect_Playback(client);
	OnClientDisconnect_Recording(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_Playback(client, buttons);
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_Recording(client, buttons, tickcount, vel, mouse);
	OnPlayerRunCmdPost_ReplayControls(client, cmdnum);
}

public Action GOKZ_OnTimerStart(int client, int course)
{
	Action action = GOKZ_OnTimerStart_Recording(client);
	if (action != Plugin_Continue)
	{
		return action;
	}
	
	return Plugin_Continue;
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	gB_NubRecordMissed[client] = false;
	GOKZ_OnTimerStart_Post_Recording(client);
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

public void GOKZ_AC_OnPlayerSuspected(int client, ACReason reason)
{
	GOKZ_AC_OnPlayerSuspected_Recording(client, reason);
}

public void GOKZ_DB_OnJumpstatPB(int client, int jumptype, int mode, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
	GOKZ_DB_OnJumpstatPB_Recording(client, jumptype, distance, block, strafes, sync, pre, max, airtime);
}



// =====[ PRIVATE ]=====


static void HookEvents()
{
	HookUserMessage(GetUserMessageId("SayText2"), Hook_SayText2, true);
}

static void UpdateCurrentMap()
{
	GetCurrentMapDisplayName(gC_CurrentMap, sizeof(gC_CurrentMap));
	gI_CurrentMapFileSize = GetCurrentMapFileSize();
}



// =====[ PUBLIC ]=====

// NOTE: These serialisation functions were made because the internal data layout of enum structs can change.
void TickDataToArray(ReplayTickData tickData, any result[RP_V2_TICK_DATA_BLOCKSIZE])
{
	// NOTE: HAS to match ReplayTickData exactly!
	result[0]  = tickData.deltaFlags;
	result[1]  = tickData.deltaFlags2;
	result[2]  = tickData.vel[0];
	result[3]  = tickData.vel[1];
	result[4]  = tickData.vel[2];
	result[5]  = tickData.mouse[0];
	result[6]  = tickData.mouse[1];
	result[7]  = tickData.origin[0];
	result[8]  = tickData.origin[1];
	result[9]  = tickData.origin[2];
	result[10] = tickData.angles[0];
	result[11] = tickData.angles[1];
	result[12] = tickData.angles[2];
	result[13] = tickData.velocity[0];
	result[14] = tickData.velocity[1];
	result[15] = tickData.velocity[2];
	result[16] = tickData.flags;
	result[17] = tickData.packetsPerSecond;
	result[18] = tickData.laggedMovementValue;
	result[19] = tickData.buttonsForced;
}

void TickDataFromArray(any array[RP_V2_TICK_DATA_BLOCKSIZE], ReplayTickData result)
{
	// NOTE: HAS to match ReplayTickData exactly!
	result.deltaFlags          = array[0];
	result.deltaFlags2         = array[1];
	result.vel[0]              = array[2];
	result.vel[1]              = array[3];
	result.vel[2]              = array[4];
	result.mouse[0]            = array[5];
	result.mouse[1]            = array[6];
	result.origin[0]           = array[7];
	result.origin[1]           = array[8];
	result.origin[2]           = array[9];
	result.angles[0]           = array[10];
	result.angles[1]           = array[11];
	result.angles[2]           = array[12];
	result.velocity[0]         = array[13];
	result.velocity[1]         = array[14];
	result.velocity[2]         = array[15];
	result.flags               = array[16];
	result.packetsPerSecond    = array[17];
	result.laggedMovementValue = array[18];
	result.buttonsForced       = array[19];
}
