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
int gI_TouchingEntities[MAXPLAYERS + 1];

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
	SDKHook(client, SDKHook_StartTouchPost, SDKHook_StartTouch_Callback);
	SDKHook(client, SDKHook_EndTouchPost, SDKHook_EndTouch_Callback);
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



// =========================  GOKZ  ========================= //

public void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump)
{
	OnJumpValidated_JumpTracking(client, jumped, ladderJump);
}

public void GOKZ_OnJumpInvalidated(int client)
{
	OnJumpInvalidated_JumpTracking(client);
}

public void GOKZ_JS_OnLanding(int client, JumpType jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	if (jumpType == JumpType_Invalid)
	{
		return;
	}
	
	PrintJumpReportToConsole(client, jumpType, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
	PrintJumpReportToChat(client, jumpType, distance, offset, preSpeed, maxSpeed, strafes, sync);
}

static void PrintJumpReportToConsole(int client, JumpType jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	PrintToConsole(client, 
		"You did a %s (%s). Here's your stats report:\n %.3f units\t| %d Offset\t| %.2f Height\t| %.3f Seconds\n %d Strafes\t| %.2f Pre\t| %.2f Max\t| %.2f%% Sync\n", 
		gC_JumpTypes[jumpType], gC_JumpTypesShort[jumpType], distance, RoundFloat(offset), height, duration, strafes, preSpeed, maxSpeed, sync);
}

static void PrintJumpReportToChat(int client, JumpType jumpType, float distance, float offset, float preSpeed, float maxSpeed, int strafes, float sync)
{
	GOKZ_PrintToChat(client, true, 
		"{grey}%s: %s units [%s | %s | %s | %s]", 
		gC_JumpTypesShort[jumpType], 
		GetDistanceString(distance, offset), 
		GetStrafesString(strafes), 
		GetPreSpeedString(client, preSpeed), 
		GetMaxSpeedString(maxSpeed), 
		GetSyncString(sync));
}

static char[] GetDistanceString(float distance, float offset)
{
	char distanceString[64];
	if (RoundFloat(offset) == 0)
	{
		FormatEx(distanceString, sizeof(distanceString), "%.2f", distance);
	}
	else if (RoundFloat(offset) > 0)
	{
		FormatEx(distanceString, sizeof(distanceString), "%.2f ({green}+%d{grey})", distance, RoundFloat(offset));
	}
	else
	{
		FormatEx(distanceString, sizeof(distanceString), "%.2f ({darkred}%d{grey})", distance, RoundFloat(offset));
	}
	return distanceString;
}

static char[] GetStrafesString(int strafes)
{
	char strafesString[32];
	if (strafes == 1)
	{
		strafesString = "{lime}1{grey} Strafe";
	}
	else
	{
		FormatEx(strafesString, sizeof(strafesString), "{lime}%d{grey} Strafes", strafes);
	}
	return strafesString;
}

static char[] GetPreSpeedString(int client, float preSpeed)
{
	char preSpeedString[32];
	if (GOKZ_GetHitPerf(client))
	{
		FormatEx(preSpeedString, sizeof(preSpeedString), "{green}%.0f{grey} Pre", preSpeed);
	}
	else
	{
		FormatEx(preSpeedString, sizeof(preSpeedString), "{lime}%.0f{grey} Pre", preSpeed);
	}
	return preSpeedString;
}

static char[] GetMaxSpeedString(float maxSpeed)
{
	char maxSpeedString[32];
	FormatEx(maxSpeedString, sizeof(maxSpeedString), "{lime}%.0f{grey} Max", maxSpeed);
	return maxSpeedString;
}

static char[] GetSyncString(float sync)
{
	char syncString[32];
	FormatEx(syncString, sizeof(syncString), "{lime}%.0f%%%%{grey} Sync", sync);
	return syncString;
} 