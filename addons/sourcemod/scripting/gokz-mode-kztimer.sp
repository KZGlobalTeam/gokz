#include <sourcemod>

#include <sdktools>
#include <sdkhooks>

#include <gokz>

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
	name = "GOKZ Mode - KZTimer", 
	author = "DanZay", 
	description = "KZTimer mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-mode-kztimer.txt"

#define MODE_VERSION 198
#define DUCK_SPEED_MINIMUM 7.0
#define PRE_VELMOD_MAX 1.104 // Calculated 276/250
#define PERF_SPEED_CAP 380.0

float gF_ModeCVarValues[MODECVAR_COUNT] = 
{
	6.5,  // sv_accelerate
	0.0,  // sv_accelerate_use_weapon_speed
	100.0,  // sv_airaccelerate
	30.0,  // sv_air_max_wishspeed
	1.0,  // sv_enablebunnyhopping
	5.0,  // sv_friction
	800.0,  // sv_gravity
	301.993377,  // sv_jump_impulse
	1.0,  // sv_ladder_scale_speed
	0.0,  // sv_ledge_mantle_helper
	320.0,  // sv_maxspeed
	2000.0,  // sv_maxvelocity
	0.0,  // sv_staminajumpcost
	0.0,  // sv_staminalandcost
	0.0,  // sv_staminamax
	0.0,  // sv_staminarecoveryrate
	0.7,  // sv_standable_normal
	0.0,  // sv_timebetweenducks
	0.7,  // sv_walkable_normal
	10.0,  // sv_wateraccelerate
	0.8,  // sv_water_movespeed_multiplier
	0.0,  // sv_water_swim_mode 
	0.0,  // sv_weapon_encumbrance_per_item
	0.0 // sv_weapon_encumbrance_scale
};

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];
float gF_PreVelMod[MAXPLAYERS + 1];
float gF_PreVelModLastChange[MAXPLAYERS + 1];
int gI_PreTickCounter[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
float gF_OldAngles[MAXPLAYERS + 1][3];
float gF_OldVelocity[MAXPLAYERS + 1][3];
bool gB_Jumpbugged[MAXPLAYERS + 1];



// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true, MODE_VERSION);
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
		GOKZ_SetModeLoaded(Mode_KZTimer, false);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	else if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true, MODE_VERSION);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZCore = gB_GOKZCore && !StrEqual(name, "gokz-core");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
	if (IsUsingMode(client))
	{
		ReplicateConVars(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	
	KZPlayer player = KZPlayer(client);
	RemoveCrouchJumpBind(player, buttons);
	TweakVelMod(player);
	if (gB_Jumpbugged[player.id])
	{
		TweakJumpbug(player);
	}
	
	gB_Jumpbugged[player.id] = false;
	gI_OldButtons[player.id] = buttons;
	gB_OldOnGround[player.id] = Movement_GetOnGround(client);
	gF_OldAngles[player.id] = angles;
	Movement_GetVelocity(client, gF_OldVelocity[client]);
	
	return Plugin_Continue;
}

public void SDKHook_OnClientPreThink_Post(int client)
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return;
	}
	
	// Don't tweak convars if GOKZ isn't running
	if (gB_GOKZCore)
	{
		TweakConVars();
	}
}

public void Movement_OnStartTouchGround(int client)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	ReduceDuckSlowdown(player);
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (jumped)
	{
		TweakJump(player);
	}
	else if (gB_GOKZCore)
	{
		player.gokzHitPerf = false;
		player.gokzTakeoffSpeed = player.takeoffSpeed;
	}
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	if (jumpbug)
	{
		gB_Jumpbugged[client] = true;
	}
}

public void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (gB_GOKZCore && newMoveType == MOVETYPE_WALK)
	{
		player.gokzHitPerf = false;
		player.gokzTakeoffSpeed = player.takeoffSpeed;
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_KZTimer)
	{
		ReplicateConVars(client);
	}
}



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_KZTimer;
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



// =====[ VELOCITY MODIFIER ]=====

void TweakVelMod(KZPlayer player)
{
	player.velocityModifier = CalcPrestrafeVelMod(player) * CalcWeaponVelMod(player);
}

float CalcPrestrafeVelMod(KZPlayer player)
{
	// No changes to prestrafe velocity modifier in midair
	if (!player.onGround)
	{
		return gF_PreVelMod[player.id];
	}
	
	bool changed = false;
	
	// KZTimer prestrafe (not exactly the same, and is only for 128 tick)
	if (!player.turning)
	{
		if (GetEngineTime() - gF_PreVelModLastChange[player.id] > 0.2)
		{
			gF_PreVelMod[player.id] = 1.0;
			changed = true;
		}
	}
	else if ((player.buttons & IN_MOVELEFT || player.buttons & IN_MOVERIGHT) && player.speed > 248.9)
	{
		float increment = 0.0009;
		if (gF_PreVelMod[player.id] > 1.04)
		{
			increment = 0.001;
		}
		
		gI_PreTickCounter[player.id]++;
		if (gI_PreTickCounter[player.id] < 75)
		{
			gF_PreVelMod[player.id] += increment;
			if (gF_PreVelMod[player.id] > PRE_VELMOD_MAX)
			{
				if (gF_PreVelMod[player.id] > PRE_VELMOD_MAX + 0.007)
				{
					gF_PreVelMod[player.id] = PRE_VELMOD_MAX - 0.001;
				}
				else
				{
					gF_PreVelMod[player.id] -= 0.007;
				}
			}
			gF_PreVelMod[player.id] += increment;
		}
		else
		{
			gF_PreVelMod[player.id] -= 0.0045;
			gI_PreTickCounter[player.id] -= 2;
		}
		
		changed = true;
	}
	else
	{
		gF_PreVelMod[player.id] -= 0.04;
		changed = true;
	}
	
	// Keep prestrafe velocity modifier within range
	if (gF_PreVelMod[player.id] < 1.0)
	{
		gF_PreVelMod[player.id] = 1.0;
		gI_PreTickCounter[player.id] = 0;
	}
	else if (gF_PreVelMod[player.id] > PRE_VELMOD_MAX)
	{
		gF_PreVelMod[player.id] = PRE_VELMOD_MAX;
	}
	
	if (changed)
	{
		gF_PreVelModLastChange[player.id] = GetEngineTime();
	}
	
	return gF_PreVelMod[player.id];
}

float CalcWeaponVelMod(KZPlayer player)
{
	return SPEED_NORMAL / player.maxSpeed;
}



// =====[ JUMPING ]=====

void TweakJump(KZPlayer player)
{
	if (player.hitPerf)
	{
		if (player.takeoffSpeed > PERF_SPEED_CAP)
		{
			// Note that resulting velocity has same direction as landing velocity, not current velocity
			float velocity[3], baseVelocity[3], newVelocity[3];
			player.GetVelocity(velocity);
			player.GetBaseVelocity(baseVelocity);
			player.GetLandingVelocity(newVelocity);
			newVelocity[2] = velocity[2];
			SetVectorHorizontalLength(newVelocity, PERF_SPEED_CAP);
			AddVectors(newVelocity, baseVelocity, newVelocity);
			player.SetVelocity(newVelocity);
			if (gB_GOKZCore)
			{
				player.gokzHitPerf = true;
				player.gokzTakeoffSpeed = player.speed;
			}
		}
		else if (gB_GOKZCore)
		{
			player.gokzHitPerf = true;
			player.gokzTakeoffSpeed = player.takeoffSpeed;
		}
	}
	else if (gB_GOKZCore)
	{
		player.gokzHitPerf = false;
		player.gokzTakeoffSpeed = player.takeoffSpeed;
	}
}

void TweakJumpbug(KZPlayer player)
{
	if (player.speed > PERF_SPEED_CAP)
	{
		Movement_SetSpeed(player.id, PERF_SPEED_CAP, true);
	}
	if (gB_GOKZCore)
	{
		player.gokzHitPerf = true;
		player.gokzTakeoffSpeed = player.speed;
	}
}



// =====[ OTHER ]=====

void RemoveCrouchJumpBind(KZPlayer player, int &buttons)
{
	if (player.onGround && buttons & IN_JUMP && !(gI_OldButtons[player.id] & IN_JUMP) && !(gI_OldButtons[player.id] & IN_DUCK))
	{
		buttons &= ~IN_DUCK;
	}
}

void ReduceDuckSlowdown(KZPlayer player)
{
	if (player.duckSpeed < DUCK_SPEED_MINIMUM)
	{
		player.duckSpeed = DUCK_SPEED_MINIMUM;
	}
} 