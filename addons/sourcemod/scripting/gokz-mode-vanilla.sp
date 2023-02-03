#include <sourcemod>

#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#include <movementapi>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/core>
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Mode - Vanilla", 
	author = "DanZay", 
	description = "Vanilla mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-mode-vanilla.txt"

#define MODE_VERSION 16

float gF_ModeCVarValues[MODECVAR_COUNT] = 
{
	5.5,  // sv_accelerate
	1.0,  // sv_accelerate_use_weapon_speed
	12.0,  // sv_airaccelerate
	30.0,  // sv_air_max_wishspeed
	0.0,  // sv_enablebunnyhopping
	5.2,  // sv_friction
	800.0,  // sv_gravity
	301.993377,  // sv_jump_impulse
	0.78,  // sv_ladder_scale_speed
	1.0,  // sv_ledge_mantle_helper
	320.0,  // sv_maxspeed
	3500.0,  // sv_maxvelocity
	0.080,  // sv_staminajumpcost
	0.050,  // sv_staminalandcost
	80.0,  // sv_staminamax
	60.0,  // sv_staminarecoveryrate
	0.7,  // sv_standable_normal
	0.4,  // sv_timebetweenducks
	0.7,  // sv_walkable_normal
	10.0,  // sv_wateraccelerate
	0.8,  // sv_water_movespeed_multiplier
	0.0,  // sv_water_swim_mode 
	0.85,  // sv_weapon_encumbrance_per_item
	0.0 // sv_weapon_encumbrance_scale
};

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];
bool gB_ProcessingMaxSpeed[MAXPLAYERS + 1];
Handle gH_GetPlayerMaxSpeed;
Handle gH_GetPlayerMaxSpeed_SDKCall;

// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	CreateConVars();
	HookEvents();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_Vanilla, true, MODE_VERSION);
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnPluginEnd()
{
	if (gB_GOKZCore)
	{
		GOKZ_SetModeLoaded(Mode_Vanilla, false);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	else if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_Vanilla, true, MODE_VERSION);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZCore = gB_GOKZCore && !StrEqual(name, "gokz-core");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{
		HookClientEvents(client);
	}
	if (IsUsingMode(client))
	{
		ReplicateConVars(client);
	}
}

void HookClientEvents(int client)
{
	DHookEntity(gH_GetPlayerMaxSpeed, true, client);
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
}

public MRESReturn DHooks_OnGetPlayerMaxSpeed(int client, Handle hReturn)
{
	if (!IsUsingMode(client) || gB_ProcessingMaxSpeed[client])
	{
		return MRES_Ignored;
	}
	gB_ProcessingMaxSpeed[client] = true;
	float maxSpeed = SDKCall(gH_GetPlayerMaxSpeed_SDKCall, client);
	// Prevent players from running faster than 250u/s
	if (maxSpeed > SPEED_NORMAL)
	{
		DHookSetReturn(hReturn, SPEED_NORMAL);
		gB_ProcessingMaxSpeed[client] = false;
		return MRES_Supercede;
	}
	gB_ProcessingMaxSpeed[client] = false;
	return MRES_Ignored;
}

public void SDKHook_OnClientPreThink_Post(int client)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	// Don't tweak convars if GOKZ isn't running
	if (gB_GOKZCore)
	{
		TweakConVars();
	}
}

public Action Movement_OnJumpPost(int client)
{
	if (!IsUsingMode(client))
	{
		return Plugin_Continue;
	}

	KZPlayer player = KZPlayer(client);
	if (gB_GOKZCore)
	{
		player.GOKZHitPerf = player.HitPerf;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
	return Plugin_Continue;
}
public void Movement_OnStopTouchGround(int client, bool jumped)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (gB_GOKZCore)
	{
		player.GOKZHitPerf = player.HitPerf;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

public void Movement_OnChangeMovetype(int client, MoveType oldMovetype, MoveType newMovetype)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (gB_GOKZCore && newMovetype == MOVETYPE_WALK)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_Vanilla)
	{
		ReplicateConVars(client);
	}
}



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_Vanilla;
}

void HookEvents()
{
	GameData gameData = LoadGameConfigFile("movementapi.games");
	int offset = gameData.GetOffset("GetPlayerMaxSpeed");
	if (offset == -1)
	{
		SetFailState("Failed to get GetPlayerMaxSpeed offset");
	}
	gH_GetPlayerMaxSpeed = DHookCreate(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHooks_OnGetPlayerMaxSpeed);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "GetPlayerMaxSpeed");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	gH_GetPlayerMaxSpeed_SDKCall = EndPrepSDKCall();
}


// =====[ CONVARS ]=====

void CreateConVars()
{
	for (int cvar = 0; cvar < MODECVAR_COUNT; cvar++)
	{
		gCV_ModeCVar[cvar] = FindConVar(gC_ModeCVars[cvar]);
	}
}

void TweakConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].FloatValue = gF_ModeCVarValues[i];
	}
}

void ReplicateConVars(int client)
{
	// Replicate convars only when player changes mode in GOKZ
	// so that lagg isn't caused by other players using other
	// modes, and also as an optimisation.
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].ReplicateToClient(client, FloatToStringEx(gF_ModeCVarValues[i]));
	}
} 
