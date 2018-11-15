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
	name = "GOKZ Mode - SimpleKZ", 
	author = "DanZay", 
	description = "SimpleKZ mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-mode-simplekz.txt"

#define MODE_VERSION 4
#define DUCK_SPEED_MINIMUM 7.0
#define PERF_TICKS 2
#define PRE_VELMOD_MAX 1.104 // Calculated 276/250
#define PRE_MINIMUM_DELTA_ANGLE 0.3515625 // Calculated 45 degrees/128 ticks 
#define PRE_VELMOD_INCREMENT 0.0014 // Per tick when prestrafing
#define PRE_VELMOD_DECREMENT 0.0021 // Per tick when not prestrafing
#define PRE_VELMOD_DECREMENT_MIDAIR 0.0011063829787234 // Per tick when in air - Calculated 0.104velmod/94ticks (lose all pre in 0 offset, normal jump duration)
#define PRE_GRACE_TICKS 3 // Number of ticks you're allowed to fail prestrafe checks when prestrafing - Helps players with low fps

float gF_ModeCVarValues[MODECVAR_COUNT] = 
{
	6.5,  // sv_accelerate
	0.0,  // sv_accelerate_use_weapon_speed
	100.0,  // sv_airaccelerate
	1.0,  // sv_enablebunnyhopping
	5.2,  // sv_friction
	800.0,  // sv_gravity
	301.993377,  // sv_jump_impulse
	1.0,  // sv_ladder_scale_speed
	320.0,  // sv_maxspeed
	3500.0,  // sv_maxvelocity
	0.0,  // sv_staminajumpcost
	0.0,  // sv_staminalandcost
	0.0,  // sv_staminamax
	0.0,  // sv_staminarecoveryrate
	0.0,  // sv_timebetweenducks
	10.0,  // sv_wateraccelerate
};

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];
float gF_PreVelMod[MAXPLAYERS + 1];
float gF_PreVelModLanding[MAXPLAYERS + 1];
bool gB_PreTurningLeft[MAXPLAYERS + 1];
int gI_PreTicksSinceIncrement[MAXPLAYERS + 1];
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
		GOKZ_SetModeLoaded(Mode_SimpleKZ, true, MODE_VERSION);
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
		GOKZ_SetModeLoaded(Mode_SimpleKZ, false);
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
		GOKZ_SetModeLoaded(Mode_SimpleKZ, true, MODE_VERSION);
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
	TweakVelMod(player, angles);
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
	gF_PreVelModLanding[player.id] = gF_PreVelMod[player.id];
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
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_SimpleKZ)
	{
		ReplicateConVars(client);
	}
}



// =====[ OTHER EVENTS ]=====

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



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_SimpleKZ;
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i] = FindConVar(gC_ModeCVars[i]);
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

void TweakVelMod(KZPlayer player, const float angles[3])
{
	player.velocityModifier = CalcPrestrafeVelMod(player, angles) * CalcWeaponVelMod(player);
}

float CalcPrestrafeVelMod(KZPlayer player, const float angles[3])
{
	// If player is in mid air, decrement their velocity modifier
	if (!player.onGround)
	{
		gF_PreVelMod[player.id] -= PRE_VELMOD_DECREMENT_MIDAIR;
	}
	// If player is turning at the required speed, and has the correct button inputs, increment their velocity modifier
	else if (ValidPrestrafeTurning(player, angles) && ValidPrestrafeButtons(player))
	{
		// If player changes their prestrafe direction, reset it
		if (player.turningLeft && !gB_PreTurningLeft[player.id] || player.turningRight && gB_PreTurningLeft[player.id])
		{
			gF_PreVelMod[player.id] = 1.0;
		}
		gB_PreTurningLeft[player.id] = player.turningLeft;
		
		// If missed a few ticks, then forgive and multiply increment amount by the number of ticks
		if (gI_PreTicksSinceIncrement[player.id] <= PRE_GRACE_TICKS)
		{
			gF_PreVelMod[player.id] += PRE_VELMOD_INCREMENT * gI_PreTicksSinceIncrement[player.id];
		}
		else
		{
			gF_PreVelMod[player.id] += PRE_VELMOD_INCREMENT;
		}
		gI_PreTicksSinceIncrement[player.id] = 1;
	}
	else
	{
		gI_PreTicksSinceIncrement[player.id]++;
		if (gI_PreTicksSinceIncrement[player.id] > PRE_GRACE_TICKS)
		{
			gF_PreVelMod[player.id] -= PRE_VELMOD_DECREMENT;
		}
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

bool ValidPrestrafeTurning(KZPlayer player, const float angles[3])
{
	// If missed a few ticks, then forgive but multiply required angle change
	if (gI_PreTicksSinceIncrement[player.id] <= PRE_GRACE_TICKS)
	{
		return FloatAbs(CalcDeltaAngle(gF_OldAngles[player.id][1], angles[1])) >= PRE_MINIMUM_DELTA_ANGLE * gI_PreTicksSinceIncrement[player.id];
	}
	// else
	return FloatAbs(CalcDeltaAngle(gF_OldAngles[player.id][1], angles[1])) >= PRE_MINIMUM_DELTA_ANGLE;
}

bool ValidPrestrafeButtons(KZPlayer player)
{
	bool forwardOrBack = player.buttons & (IN_FORWARD | IN_BACK) && !(player.buttons & IN_FORWARD && player.buttons & IN_BACK);
	bool leftOrRight = player.buttons & (IN_MOVELEFT | IN_MOVERIGHT) && !(player.buttons & IN_MOVELEFT && player.buttons & IN_MOVERIGHT);
	return forwardOrBack || leftOrRight;
}

float CalcWeaponVelMod(KZPlayer player)
{
	return SPEED_NORMAL / player.maxSpeed;
}



// =====[ JUMPING ]=====

void TweakJump(KZPlayer player)
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

void TweakJumpbug(KZPlayer player)
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
float CalcTweakedTakeoffSpeed(KZPlayer player, bool jumpbug = false)
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



// =====[ SLOPEFIX ]=====

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