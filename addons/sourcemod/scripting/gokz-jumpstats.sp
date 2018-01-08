#include <sourcemod>

#include <sdkhooks>

#include <emitsoundany>
#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/jumpstats>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Jumpstats", 
	author = "DanZay", 
	description = "GOKZ Jumpstats Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.global/gokz-jumpstats.txt"

#define BHOP_ON_GROUND_TICKS 5
#define WEIRDJUMP_MAX_FALL_OFFSET 64.0
#define MAX_TRACKED_STRAFES 32

int gI_TouchingEntities[MAXPLAYERS + 1];

#include "gokz-jumpstats/api.sp"
#include "gokz-jumpstats/commands.sp"
#include "gokz-jumpstats/distancetiers.sp"
#include "gokz-jumpstats/jumpreporting.sp"
#include "gokz-jumpstats/jumptracking.sp"
#include "gokz-jumpstats/options.sp"
#include "gokz-jumpstats/optionsmenu.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	CreateNatives();
	RegPluginLibrary("gokz-jumpstats");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-core.phrases");
	LoadTranslations("gokz-jumpstats.phrases");
	
	CreateGlobalForwards();
	CreateCommands();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}



// =========================  CLIENT  ========================= //

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_JumpTracking(client, cmdnum);
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	gI_TouchingEntities[client] = 0;
	SDKHook(client, SDKHook_StartTouchPost, SDKHook_StartTouch_Callback);
	SDKHook(client, SDKHook_EndTouchPost, SDKHook_EndTouch_Callback);
	OnClientPutInServer_Options(client);
}

public void SDKHook_StartTouch_Callback(int client, int touched)
{
	gI_TouchingEntities[client]++;
	OnStartTouch_JumpTracking(client);
}

public void SDKHook_EndTouch_Callback(int client, int touched)
{
	gI_TouchingEntities[client]--;
}



// =========================  MOVEMENTAPI  ========================= //

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_JumpTracking(client);
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	OnPlayerJump_JumpTracking(client, jumpbug);
}



// =========================  GOKZ  ========================= //

public void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump)
{
	OnJumpValidated_JumpTracking(client, jumped, ladderJump);
}

public void GOKZ_OnJumpInvalidated(int client)
{
	OnJumpInvalidated_JumpTracking(client);
}

public void GOKZ_OnOptionChanged(int client, Option option, int newValue)
{
	OnOptionChanged_JumpTracking(client, option);
}

public void GOKZ_JS_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	OnLanding_JumpReporting(client, jumpType, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	OnMapStart_DistanceTiers();
	OnMapStart_JumpReporting();
	OnMapStart_Options();
} 