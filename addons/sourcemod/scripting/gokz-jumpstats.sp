#include <sourcemod>

#include <sdkhooks>

#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/jumpstats>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Jumpstats", 
	author = "DanZay", 
	description = "GOKZ Jumpstats Module", 
	version = "0.14.0", 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

bool gB_LateLoad;

#include "gokz-jumpstats/api.sp"
#include "gokz-jumpstats/jumptracking.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-jumpstats");
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



// =========================  CLIENT  ========================= //

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_JumpTracking(client);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouch, SDKHook_StartTouch_Callback);
}

public Action SDKHook_StartTouch_Callback(int client, int touched)
{
	OnStartTouch_JumpTracking(client);
}



// =========================  MOVEMENTAPI  ========================= //

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	OnStopTouchGround_JumpTracking(client, jumped);
}

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_JumpTracking(client);
}

public void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType)
{
	OnChangeMoveType_JumpTracking(client, oldMoveType, newMoveType);
}



// =========================  GOKZ  ========================= //

public void GOKZ_OnJumpInvalidated(int client)
{
	OnJumpInvalidated_JumpTracking(client);
}

public void GOKZ_JS_OnLanding(int client, JumpType jumpType, float distance, float offset, float height, float maxSpeed, int strafes, float sync, float duration)
{
	PrintJumpReport(client, jumpType, distance, offset, height, maxSpeed, strafes, sync, duration);
}

static void PrintJumpReport(int client, JumpType jumpType, float distance, float offset, float height, float maxSpeed, int strafes, float sync, float duration)
{
	// TODO Make this not bad
	if (jumpType == JumpType_Invalid)
	{
		return;
	}
	GOKZ_PrintToChat(client, true, 
		"%s | Dist %.3f (%.0f) | Pre %.0f | Max %.0f | Height %.0f | Strafes %d | Sync %.0f | Duration %.3f", 
		gC_JumpTypes[jumpType], distance, offset, GOKZ_GetTakeoffSpeed(client), maxSpeed, height, strafes, sync, duration);
} 