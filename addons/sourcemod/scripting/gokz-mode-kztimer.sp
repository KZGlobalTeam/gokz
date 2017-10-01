#include <sourcemod>

#include <sdktools>
#include <sdkhooks>

#include <gokz>

#include <movementapi>
#undef REQUIRE_PLUGIN
#include <gokz/core>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Mode - KZTimer", 
	author = "DanZay", 
	description = "GOKZ Mode Module - KZTimer", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://dzy.crabdance.com/updater/gokz-mode-kztimer.txt"

#define DUCK_SPEED_MINIMUM 7.0
#define PRE_VELMOD_MAX 1.104 // Calculated 276/250
#define PERF_SPEED_CAP 380.0

float gF_ModeCVarValues[MODECVAR_COUNT] =  { 6.5, 5.0, 100.0, 1.0, 3500.0, 800.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 320.0, 10.0, 0.4, 0.0, 301.993377 };

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



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
	
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

public void OnAllPluginsLoaded()
{
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true);
	}
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true);
	}
	else if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = false;
	}
}



// =========================  GENERAL  ========================= //

public void OnGameFrame()
{
	/* 
		Why are we using OnGameFrame() for slope boost fix?
		
		MovementAPI measures landing speed, calls forwards etc. during 
		OnPlayerRunCmd.	We want the slope fix to apply it's speed before 
		MovementAPI does this, so that we can apply tweaks based on the 
		'fixed' landing speed.
	*/
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && IsUsingMode(client))
		{
			SlopeFix(client);
		}
	}
}



// =========================  CLIENT  ========================= //

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	
	KZPlayer player = new KZPlayer(client);
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
	
	KZPlayer player = new KZPlayer(client);
	ReduceDuckSlowdown(player);
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = new KZPlayer(client);
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
	
	KZPlayer player = new KZPlayer(client);
	if (gB_GOKZCore && newMoveType == MOVETYPE_WALK)
	{
		player.gokzHitPerf = false;
		player.gokzTakeoffSpeed = player.takeoffSpeed;
	}
}



// =========================  PRIVATE  ========================= //

static bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetOption(client, Option_Mode) == Mode_KZTimer;
}


// CONVARS

static void CreateConVars()
{
	for (int cvar = 0; cvar < MODECVAR_COUNT; cvar++)
	{
		gCV_ModeCVar[cvar] = FindConVar(gC_ModeCVars[cvar]);
		// Remove notify flags because these ConVars are being set constantly
		gCV_ModeCVar[cvar].Flags &= ~FCVAR_NOTIFY;
	}
}

static void TweakConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].FloatValue = gF_ModeCVarValues[i];
	}
}


// VELOCITY MODIFIER

static void TweakVelMod(KZPlayer player)
{
	player.velocityModifier = CalcPrestrafeVelMod(player) * CalcWeaponVelMod(player);
}

static float CalcPrestrafeVelMod(KZPlayer player)
{
	// No changes to prestrafe velocity modifier in midair
	if (!player.onGround)
	{
		return gF_PreVelMod[player.id];
	}
	
	// KZTimer prestrafe (not exactly the same, and is only for 128 tick)
	if (!player.turning)
	{
		if (GetEngineTime() - gF_PreVelModLastChange[player.id] > 0.2)
		{
			gF_PreVelMod[player.id] = 1.0;
			gF_PreVelModLastChange[player.id] = GetEngineTime();
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
	}
	else
	{
		gF_PreVelMod[player.id] -= 0.04;
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
	
	return gF_PreVelMod[player.id];
}

static float CalcWeaponVelMod(KZPlayer player)
{
	int weaponEnt = GetEntPropEnt(player.id, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(weaponEnt))
	{
		return SPEED_NORMAL / SPEED_NO_WEAPON; // Weapon entity not found, so no weapon
	}
	
	char weaponName[64];
	GetEntityClassname(weaponEnt, weaponName, sizeof(weaponName)); // Weapon the client is holding
	
	// Get weapon speed and work out how much to scale the modifier
	int weaponCount = sizeof(gC_WeaponNames);
	for (int weaponID = 0; weaponID < weaponCount; weaponID++)
	{
		if (StrEqual(weaponName, gC_WeaponNames[weaponID]))
		{
			return SPEED_NORMAL / gI_WeaponRunSpeeds[weaponID];
		}
	}
	
	return 1.0; // If weapon isn't found (new weapon?)
}


// JUMPING

static void TweakJump(KZPlayer player)
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

static void TweakJumpbug(KZPlayer player)
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



// SLOPEFIX
// ORIGINAL AUTHORS : Mev & Blacky
// URL : https://forums.alliedmods.net/showthread.php?p=2322788
// NOTE : Modified by DanZay for this plugin

void SlopeFix(int client)
{
	// Check if player landed on the ground
	if (Movement_GetOnGround(client) && !gB_OldOnGround[client])
	{
		// Set up and do tracehull to find out if the player landed on a slope
		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		
		float vMins[3];
		GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
		
		float vMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
		
		float vEndPos[3];
		vEndPos[0] = vPos[0];
		vEndPos[1] = vPos[1];
		vEndPos[2] = vPos[2] - FindConVar("sv_maxvelocity").FloatValue;
		
		TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		
		if (TR_DidHit())
		{
			// Gets the normal vector of the surface under the player
			float vPlane[3], vLast[3];
			TR_GetPlaneNormal(INVALID_HANDLE, vPlane);
			
			// Make sure it's not flat ground and not a surf ramp (1.0 = flat ground, < 0.7 = surf ramp)
			if (0.7 <= vPlane[2] < 1.0)
			{
				/*
					Copy the ClipVelocity function from sdk2013 
					(https://mxr.alliedmods.net/hl2sdk-sdk2013/source/game/shared/gamemovement.cpp#3145)
					With some minor changes to make it actually work
					*/
				vLast[0] = gF_OldVelocity[client][0];
				vLast[1] = gF_OldVelocity[client][1];
				vLast[2] = gF_OldVelocity[client][2];
				vLast[2] -= (FindConVar("sv_gravity").FloatValue * GetTickInterval() * 0.5);
				
				float fBackOff = GetVectorDotProduct(vLast, vPlane);
				
				float change, vVel[3];
				for (int i; i < 2; i++)
				{
					change = vPlane[i] * fBackOff;
					vVel[i] = vLast[i] - change;
				}
				
				float fAdjust = GetVectorDotProduct(vVel, vPlane);
				if (fAdjust < 0.0)
				{
					for (int i; i < 2; i++)
					{
						vVel[i] -= (vPlane[i] * fAdjust);
					}
				}
				
				vVel[2] = 0.0;
				vLast[2] = 0.0;
				
				// Make sure the player is going down a ramp by checking if they actually will gain speed from the boost
				if (GetVectorLength(vVel) > GetVectorLength(vLast))
				{
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
				}
			}
		}
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 < entity <= MaxClients);
}



// OTHER

static void RemoveCrouchJumpBind(KZPlayer player, int &buttons)
{
	if (player.onGround && buttons & IN_JUMP && !(gI_OldButtons[player.id] & IN_JUMP) && !(gI_OldButtons[player.id] & IN_DUCK))
	{
		buttons &= ~IN_DUCK;
	}
}

static void ReduceDuckSlowdown(KZPlayer player)
{
	if (player.duckSpeed < DUCK_SPEED_MINIMUM)
	{
		player.duckSpeed = DUCK_SPEED_MINIMUM;
	}
} 