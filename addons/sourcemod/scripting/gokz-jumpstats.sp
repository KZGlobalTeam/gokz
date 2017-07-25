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

#define BHOP_ON_GROUND_TICKS 4

bool gB_LateLoad;
bool gB_HitSomething[MAXPLAYERS + 1];
JumpType g_CurrentJumpType[MAXPLAYERS + 1];
JumpType g_LastJumpType[MAXPLAYERS + 1];
float gF_JumpDistance[MAXPLAYERS + 1];
float gF_JumpOffset[MAXPLAYERS + 1];



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
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

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouch, SDKHook_StartTouch_Callback);
}

public Action SDKHook_StartTouch_Callback(int client, int touched)
{
	if (!Movement_GetOnGround(client))
	{
		gB_HitSomething[client] = true;
	}
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	BeginJump(client, DetermineJumpType(client, jumped));
}

public void Movement_OnStartTouchGround(int client)
{
	if (GOKZ_GetValidJump(client) && !gB_HitSomething[client])
	{
		gF_JumpDistance[client] = CalcJumpDistance(client);
		gF_JumpOffset[client] = CalcJumpOffset(client);
		g_LastJumpType[client] = g_CurrentJumpType[client];
		PrintJumpReport(client);
	}
	else
	{
		g_LastJumpType[client] = JumpType_Invalid;
	}
}

public void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType)
{
	if (oldMoveType == MOVETYPE_LADDER && newMoveType == MOVETYPE_WALK)
	{
		BeginJump(client, JumpType_LadderJump);
	}
}



// =========================  PRIVATE  ========================= //

static void BeginJump(int client, JumpType jumpType)
{
	g_CurrentJumpType[client] = jumpType;
	gB_HitSomething[client] = false;
}

static JumpType DetermineJumpType(int client, bool jumped)
{
	if (!jumped)
	{
		return JumpType_Fall;
	}
	else if (HitBhop(client))
	{
		if (g_LastJumpType[client] == JumpType_Fall)
		{
			return JumpType_WeirdJump;
		}
		else if (LastJumpWasBhop(client) || g_LastJumpType[client] == JumpType_Invalid)
		{
			return JumpType_MultiBhop;
		}
		else if (gF_JumpOffset[client] < 0.0)
		{
			return JumpType_DropBhop;
		}
		else
		{
			return JumpType_Bhop;
		}
	}
	else
	{
		return JumpType_LongJump;
	}
}

static bool HitBhop(int client)
{
	return Movement_GetTakeoffTick(client) - Movement_GetLandingTick(client) <= BHOP_ON_GROUND_TICKS;
}

static bool LastJumpWasBhop(int client)
{
	return g_LastJumpType[client] == JumpType_Bhop
	 || g_LastJumpType[client] == JumpType_MultiBhop
	 || g_LastJumpType[client] == JumpType_DropBhop
	 || g_LastJumpType[client] == JumpType_WeirdJump;
}

static float CalcJumpDistance(int client)
{
	float takeoffOrigin[3], landingOrigin[3];
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetLandingOrigin(client, landingOrigin);
	return GetVectorHorizontalDistance(takeoffOrigin, landingOrigin) + 32.0;
}

static float CalcJumpOffset(int client)
{
	float takeoffOrigin[3], landingOrigin[3];
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetLandingOrigin(client, landingOrigin);
	return landingOrigin[2] - takeoffOrigin[2];
}

static void PrintJumpReport(int client)
{
	GOKZ_PrintToChat(client, true, 
		"%s - Dist: {yellow}%.3f{grey}, Offset: {yellow}%.1f{grey}, Pre: {yellow}%.1f{grey}", 
		gC_JumpTypes[g_CurrentJumpType[client]], 
		gF_JumpDistance[client], 
		gF_JumpOffset[client], 
		Movement_GetTakeoffSpeed(client));
} 