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
	name = "GOKZ Mode - SimpleKZ", 
	author = "DanZay", 
	description = "GOKZ Mode Module - SimpleKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://dzy.crabdance.com/updater/gokz-mode-simplekz.txt"

#define DUCK_SPEED_MINIMUM 7.0
#define PERF_TICKS 2
#define PRE_VELMOD_MAX 1.104 // Calculated 276/250
#define PRE_MINIMUM_DELTA_ANGLE 0.3515625 // Calculated 45 degrees/128 ticks 
#define PRE_VELMOD_INCREMENT 0.0014 // Per tick when prestrafing
#define PRE_VELMOD_DECREMENT 0.0021 // Per tick when not prestrafing
#define PRE_VELMOD_DECREMENT_MIDAIR 0.0011063829787234 // Per tick when in air - Calculated 0.104velmod/94ticks (lose all pre in 0 offset, normal jump duration)

float gF_ModeCVarValues[MODECVAR_COUNT] =  { 6.5, 5.2, 100.0, 1.0, 3500.0, 800.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 320.0, 10.0, 0.4, 0.0, 301.993377 };

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];
float gF_PreVelMod[MAXPLAYERS + 1];
float gF_PreVelModLanding[MAXPLAYERS + 1];
bool gB_PreTurningLeft[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];
float gF_OldAngles[MAXPLAYERS + 1][3];
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
		GOKZ_SetModeLoaded(Mode_SimpleKZ, false);
	}
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_SimpleKZ, true);
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
		GOKZ_SetModeLoaded(Mode_SimpleKZ, true);
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
	TweakVelMod(player, angles);
	if (gB_Jumpbugged[player.id])
	{
		TweakJumpbug(player);
	}
	
	gB_Jumpbugged[player.id] = false;
	gI_OldButtons[player.id] = buttons;
	gF_OldAngles[player.id] = angles;
	
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
	gF_PreVelModLanding[player.id] = gF_PreVelMod[player.id];
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
	return !gB_GOKZCore || GOKZ_GetOption(client, Option_Mode) == Mode_SimpleKZ;
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

static void TweakVelMod(KZPlayer player, const float angles[3])
{
	player.velocityModifier = CalcPrestrafeVelMod(player, angles) * CalcWeaponVelMod(player);
}

static float CalcPrestrafeVelMod(KZPlayer player, const float angles[3])
{
	// If player is in mid air, decrement their velocity modifier
	if (!player.onGround)
	{
		gF_PreVelMod[player.id] -= PRE_VELMOD_DECREMENT_MIDAIR;
	}
	// If player is turning at the required speed, and has the correct button inputs, increment their velocity modifier
	else if (FloatAbs(CalcDeltaAngle(gF_OldAngles[player.id][1], angles[1])) >= PRE_MINIMUM_DELTA_ANGLE && ValidPrestrafeButtons(player))
	{
		// If player changes their prestrafe direction, reset it
		if (player.turningLeft && !gB_PreTurningLeft[player.id] || player.turningRight && gB_PreTurningLeft[player.id])
		{
			gF_PreVelMod[player.id] = 1.0;
		}
		gB_PreTurningLeft[player.id] = player.turningLeft;
		gF_PreVelMod[player.id] += PRE_VELMOD_INCREMENT;
	}
	else
	{
		gF_PreVelMod[player.id] -= PRE_VELMOD_DECREMENT;
	}
	
	// Keep prestrafe velocity modifier within range
	if (gF_PreVelMod[player.id] < 1.0)
	{
		gF_PreVelMod[player.id] = 1.0;
	}
	else if (gF_PreVelMod[player.id] > PRE_VELMOD_MAX)
	{
		gF_PreVelMod[player.id] = PRE_VELMOD_MAX;
	}
	
	return gF_PreVelMod[player.id];
}

static bool ValidPrestrafeButtons(KZPlayer player)
{
	bool forwardOrBack = player.buttons & IN_FORWARD && !(player.buttons & IN_BACK) || !(player.buttons & IN_FORWARD) && player.buttons & IN_BACK;
	bool leftOrRight = player.buttons & IN_MOVELEFT && !(player.buttons & IN_MOVERIGHT) || !(player.buttons & IN_MOVELEFT) && player.buttons & IN_MOVERIGHT;
	return forwardOrBack && leftOrRight;
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
	if (player.takeoffCmdNum - player.landingCmdNum <= PERF_TICKS)
	{
		if (!player.hitPerf || player.takeoffSpeed > SPEED_NORMAL)
		{
			// Note that resulting velocity has same direction as landing velocity, not current velocity
			float velocity[3], baseVelocity[3], newVelocity[3];
			player.GetVelocity(velocity);
			player.GetBaseVelocity(baseVelocity);
			player.GetLandingVelocity(newVelocity);
			newVelocity[2] = velocity[2];
			SetVectorHorizontalLength(newVelocity, CalcTweakedTakeoffSpeed(player));
			AddVectors(newVelocity, baseVelocity, newVelocity);
			player.SetVelocity(newVelocity);
			// Restore prestrafe lost due to briefly being on the ground
			gF_PreVelMod[player.id] = gF_PreVelModLanding[player.id];
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
	if (player.speed > SPEED_NORMAL)
	{
		Movement_SetSpeed(player.id, CalcTweakedTakeoffSpeed(player, true), true);
	}
	if (gB_GOKZCore)
	{
		player.gokzHitPerf = true;
		player.gokzTakeoffSpeed = player.speed;
	}
}

// Takeoff speed assuming player has met the conditions to need tweaking
static float CalcTweakedTakeoffSpeed(KZPlayer player, bool jumpbug = false)
{
	// Formula
	if (jumpbug)
	{
		return FloatMin(player.speed, (0.2 * player.speed + 200) * gF_PreVelMod[player.id]);
	}
	else if (player.landingSpeed > SPEED_NORMAL)
	{
		return FloatMin(player.landingSpeed, (0.2 * player.landingSpeed + 200) * gF_PreVelModLanding[player.id]);
	}
	return player.landingSpeed;
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