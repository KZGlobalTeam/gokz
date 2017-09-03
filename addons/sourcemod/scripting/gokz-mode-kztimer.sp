#include <sourcemod>

#include <sdktools>
#include <sdkhooks>

#include <gokz>
#include <movementapi>

#undef REQUIRE_PLUGIN
#include <gokz/core>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Mode - KZTimer", 
	author = "DanZay", 
	description = "GOKZ Mode Module - KZTimer", 
	version = "0.14.0", 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define DUCK_SPEED_MINIMUM 7.0
#define PRE_VELMOD_MAX 1.104 // Calculated 276/250
#define PERF_SPEED_CAP 380.0

float gF_ModeCVarValues[MODECVAR_COUNT] =  { 6.5, 5.0, 100.0, 1.0, 3500.0, 800.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 320.0, 10.0, 0.4, 0.0 };
bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];
float gF_PreVelMod[MAXPLAYERS + 1];
float gF_PreVelModLastChange[MAXPLAYERS + 1];
int gI_PreTickCounter[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];
float gF_OldAngles[MAXPLAYERS + 1][3];



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-mode-vanilla");
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	CreateConVars();
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
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true);
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
		return;
	}
	
	KZPlayer player = new KZPlayer(client);
	RemoveCrouchJumpBind(player, buttons);
	TweakVelMod(player);
	gI_OldButtons[client] = buttons;
	gF_OldAngles[client] = angles;
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
	gCV_ModeCVar[ModeCVar_Accelerate] = FindConVar("sv_accelerate");
	gCV_ModeCVar[ModeCVar_Friction] = FindConVar("sv_friction");
	gCV_ModeCVar[ModeCVar_AirAccelerate] = FindConVar("sv_airaccelerate");
	gCV_ModeCVar[ModeCVar_LadderScaleSpeed] = FindConVar("sv_ladder_scale_speed");
	gCV_ModeCVar[ModeCVar_MaxVelocity] = FindConVar("sv_maxvelocity");
	gCV_ModeCVar[ModeCVar_Gravity] = FindConVar("sv_gravity");
	gCV_ModeCVar[ModeCVar_EnableBunnyhopping] = FindConVar("sv_enablebunnyhopping");
	gCV_ModeCVar[ModeCVar_AutoBunnyhopping] = FindConVar("sv_autobunnyhopping");
	gCV_ModeCVar[ModeCVar_StaminaMax] = FindConVar("sv_staminamax");
	gCV_ModeCVar[ModeCVar_StaminaLandCost] = FindConVar("sv_staminalandcost");
	gCV_ModeCVar[ModeCVar_StaminaJumpCost] = FindConVar("sv_staminajumpcost");
	gCV_ModeCVar[ModeCVar_StaminaRecoveryRate] = FindConVar("sv_staminarecoveryrate");
	gCV_ModeCVar[ModeCVar_MaxSpeed] = FindConVar("sv_maxspeed");
	gCV_ModeCVar[ModeCVar_WaterAccelerate] = FindConVar("sv_wateraccelerate");
	gCV_ModeCVar[ModeCVar_TimeBetweenDucks] = FindConVar("sv_timebetweenducks");
	gCV_ModeCVar[ModeCVar_AccelerateUseWeaponSpeed] = FindConVar("sv_accelerate_use_weapon_speed");
	
	// Remove these notify flags because these ConVars are being set constantly
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].Flags &= ~FCVAR_NOTIFY;
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