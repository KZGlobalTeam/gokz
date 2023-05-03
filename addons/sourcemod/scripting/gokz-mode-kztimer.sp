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
	name = "GOKZ Mode - KZTimer", 
	author = "DanZay", 
	description = "KZTimer mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-mode-kztimer.txt"

#define MODE_VERSION 217
#define DUCK_SPEED_NORMAL 8.0
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
float gF_RealPreVelMod[MAXPLAYERS + 1];
int gI_PreTickCounter[MAXPLAYERS + 1];
Handle gH_GetPlayerMaxSpeed;
DynamicDetour gH_CanUnduck;
int gI_TickCount[MAXPLAYERS + 1];
DynamicDetour gH_AirAccelerate;
int gI_OldButtons[MAXPLAYERS + 1];
int gI_OldFlags[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
float gF_OldVelocity[MAXPLAYERS + 1][3];
bool gB_Jumpbugged[MAXPLAYERS + 1];
int gI_OffsetCGameMovement_player;



// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	if (FloatAbs(1.0 / GetTickInterval() - 128.0) > EPSILON)
	{
		SetFailState("gokz-mode-kztimer only supports 128 tickrate servers.");
	}
	HookEvents();
	CreateConVars();
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
		Updater_AddPlugin(UPDATER_URL);
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
	if (IsValidClient(client))
	{
		HookClientEvents(client);
	}
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
	gF_RealPreVelMod[player.ID] = CalcPrestrafeVelMod(player);
	ReduceDuckSlowdown(player);
	FixWaterBoost(player, buttons);
	FixDisplacementStuck(player);
	
	gB_Jumpbugged[player.ID] = false;
	gI_OldButtons[player.ID] = buttons;
	gI_OldFlags[player.ID] = GetEntityFlags(client);
	gB_OldOnGround[player.ID] = Movement_GetOnGround(client);
	gI_TickCount[player.ID] = tickcount;
	Movement_GetVelocity(client, gF_OldVelocity[client]);
	return Plugin_Continue;
}

public MRESReturn DHooks_OnGetPlayerMaxSpeed(int client, Handle hReturn)
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return MRES_Ignored;
	}

	DHookSetReturn(hReturn, SPEED_NORMAL * gF_RealPreVelMod[client]);
	return MRES_Supercede;
}

public MRESReturn DHooks_OnAirAccelerate_Pre(Address pThis, DHookParam hParams)
{
	int client = GOKZGetClientFromGameMovementAddress(pThis, gI_OffsetCGameMovement_player);
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return MRES_Ignored;
	}
	
	// NOTE: Prestrafing changes GetPlayerMaxSpeed, which changes
	// air acceleration, so remove gF_PreVelMod[client] from wishspeed/maxspeed.
	// This also applies to when the player is ducked: their wishspeed is
	// 85 and with prestrafing can be ~93.
	float wishspeed = DHookGetParam(hParams, 2);
	if (gF_PreVelMod[client] > 1.0)
	{
		DHookSetParam(hParams, 2, wishspeed / gF_PreVelMod[client]);
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHooks_OnCanUnduck_Pre(Address pThis, DHookReturn hReturn)
{
	int client = GOKZGetClientFromGameMovementAddress(pThis, gI_OffsetCGameMovement_player);
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return MRES_Ignored;
	}
	// Just landed fully ducked, you can't unduck.
	if (Movement_GetLandingTick(client) == (gI_TickCount[client] - 1) && GetEntPropFloat(client, Prop_Send, "m_flDuckAmount") >= 1.0 && GetEntProp(client, Prop_Send, "m_bDucked"))
	{
		hReturn.Value = false;
		return MRES_Supercede;
	}
	return MRES_Ignored;
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

public Action Movement_OnCategorizePositionPost(int client, float origin[3], float velocity[3])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	return SlopeFix(client, origin, velocity);
}

public Action Movement_OnJumpPre(int client, float origin[3], float velocity[3])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	
	KZPlayer player = KZPlayer(client);
	return TweakJump(player, velocity);
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

public void Movement_OnStopTouchGround(int client)
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
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
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
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_KZTimer)
	{
		ReplicateConVars(client);
	}
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	KZPlayer player = KZPlayer(client);
	ResetPrestrafeVelMod(player);
}



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_KZTimer;
}

void HookEvents()
{
	GameData gameData = LoadGameConfigFile("movementapi.games");
	if (gameData == INVALID_HANDLE)
	{
		SetFailState("Failed to find movementapi.games config");
	}
	
	int offset = gameData.GetOffset("GetPlayerMaxSpeed");
	if (offset == -1)
	{
		SetFailState("Failed to get GetPlayerMaxSpeed offset");
	}
	gH_GetPlayerMaxSpeed = DHookCreate(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHooks_OnGetPlayerMaxSpeed);
	
	gH_AirAccelerate = DynamicDetour.FromConf(gameData, "CGameMovement::AirAccelerate");
	if (gH_AirAccelerate == INVALID_HANDLE)
	{
		SetFailState("Failed to find CGameMovement::AirAccelerate function signature");
	}
	
	if (!gH_AirAccelerate.Enable(Hook_Pre, DHooks_OnAirAccelerate_Pre))
	{
		SetFailState("Failed to enable detour on CGameMovement::AirAccelerate");
	}
	
	char buffer[16];
	if (!gameData.GetKeyValue("CGameMovement::player", buffer, sizeof(buffer)))
	{
		SetFailState("Failed to get CGameMovement::player offset.");
	}
	gI_OffsetCGameMovement_player = StringToInt(buffer);

	gameData = LoadGameConfigFile("gokz-core.games");
	gH_CanUnduck = DynamicDetour.FromConf(gameData, "CCSGameMovement::CanUnduck");
	if (gH_CanUnduck == INVALID_HANDLE)
	{
		SetFailState("Failed to find CCSGameMovement::CanUnduck function signature");
	}
	
	if (!gH_CanUnduck.Enable(Hook_Pre, DHooks_OnCanUnduck_Pre))
	{
		SetFailState("Failed to enable detour on CCSGameMovement::CanUnduck");
	}
	delete gameData;
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

void HookClientEvents(int client)
{
	DHookEntity(gH_GetPlayerMaxSpeed, true, client);
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
}

// Adapted from KZTimerGlobal
float CalcPrestrafeVelMod(KZPlayer player)
{
	if (!player.OnGround)
	{
		return gF_PreVelMod[player.ID];
	}
	
	if (!player.Turning)
	{
		if (GetEngineTime() - gF_PreVelModLastChange[player.ID] > 0.2)
		{
			gF_PreVelMod[player.ID] = 1.0;
			gF_PreVelModLastChange[player.ID] = GetEngineTime();
		}
		else if (gF_PreVelMod[player.ID] > PRE_VELMOD_MAX + 0.007)
		{
			return PRE_VELMOD_MAX - 0.001; // Returning without setting the variable is intentional
		}
	}
	else if ((player.Buttons & IN_MOVELEFT || player.Buttons & IN_MOVERIGHT) && player.Speed > 248.9)
	{
		float increment = 0.0009;
		if (gF_PreVelMod[player.ID] > 1.04)
		{
			increment = 0.001;
		}
		
		bool forwards = GetClientMovingDirection(player.ID, false) > 0.0;
		
		if ((player.Buttons & IN_MOVERIGHT && player.TurningRight || player.TurningLeft && !forwards)
			 || (player.Buttons & IN_MOVELEFT && player.TurningLeft || player.TurningRight && !forwards))
		{
			gI_PreTickCounter[player.ID]++;
			
			if (gI_PreTickCounter[player.ID] < 75)
			{
				gF_PreVelMod[player.ID] += increment;
				if (gF_PreVelMod[player.ID] > PRE_VELMOD_MAX)
				{
					if (gF_PreVelMod[player.ID] > PRE_VELMOD_MAX + 0.007)
					{
						gF_PreVelMod[player.ID] = PRE_VELMOD_MAX - 0.001;
					}
					else
					{
						gF_PreVelMod[player.ID] -= 0.007;
					}
				}
				gF_PreVelMod[player.ID] += increment;
			}
			else
			{
				gF_PreVelMod[player.ID] -= 0.0045;
				gI_PreTickCounter[player.ID] -= 2;
				
				if (gF_PreVelMod[player.ID] < 1.0)
				{
					gF_PreVelMod[player.ID] = 1.0;
					gI_PreTickCounter[player.ID] = 0;
				}
			}
		}
		else
		{
			gF_PreVelMod[player.ID] -= 0.04;
			
			if (gF_PreVelMod[player.ID] < 1.0)
			{
				gF_PreVelMod[player.ID] = 1.0;
			}
		}
		
		gF_PreVelModLastChange[player.ID] = GetEngineTime();
	}
	else
	{
		gI_PreTickCounter[player.ID] = 0;
		return 1.0; // Returning without setting the variable is intentional
	}
	
	return gF_PreVelMod[player.ID];
}

// Adapted from KZTimerGlobal
float GetClientMovingDirection(int client, bool ladder)
{
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
	
	float fEyeAngles[3];
	GetClientEyeAngles(client, fEyeAngles);
	
	if (fEyeAngles[0] > 70.0)fEyeAngles[0] = 70.0;
	if (fEyeAngles[0] < -70.0)fEyeAngles[0] = -70.0;
	
	float fViewDirection[3];
	
	if (ladder)
	{
		GetEntPropVector(client, Prop_Send, "m_vecLadderNormal", fViewDirection);
	}
	else
	{
		GetAngleVectors(fEyeAngles, fViewDirection, NULL_VECTOR, NULL_VECTOR);
	}
	
	NormalizeVector(fVelocity, fVelocity);
	NormalizeVector(fViewDirection, fViewDirection);
	
	float direction = GetVectorDotProduct(fVelocity, fViewDirection);
	if (ladder)
	{
		direction = direction * -1;
	}
	return direction;
}

void ResetPrestrafeVelMod(KZPlayer player)
{
	gF_PreVelMod[player.ID] = 1.0;
	gI_PreTickCounter[player.ID] = 0;
}



// =====[ SLOPEFIX ]=====

// ORIGINAL AUTHORS : Mev & Blacky
// URL : https://forums.alliedmods.net/showthread.php?p=2322788
// NOTE : Modified by DanZay for this plugin

Action SlopeFix(int client, float origin[3], float velocity[3])
{
	KZPlayer player = KZPlayer(client);
	// Check if player landed on the ground
	if (Movement_GetOnGround(client) && !gB_OldOnGround[client])
	{
		float vMins[] = {-16.0, -16.0, 0.0};
		// Always use ducked hull as the real hull size isn't updated yet.
		// Might cause slight issues in extremely rare scenarios.
		float vMaxs[] = {16.0, 16.0, 54.0};
		
		float vEndPos[3];
		vEndPos[0] = origin[0];
		vEndPos[1] = origin[1];
		vEndPos[2] = origin[2] - gF_ModeCVarValues[ModeCVar_MaxVelocity];
		
		// Set up and do tracehull to find out if the player landed on a slope
		TR_TraceHullFilter(origin, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		
		if (TR_DidHit())
		{
			// Gets the normal vector of the surface under the player
			float vPlane[3], vLast[3];
			player.GetLandingVelocity(vLast);
			TR_GetPlaneNormal(null, vPlane);
			
			// Make sure it's not flat ground and not a surf ramp (1.0 = flat ground, < 0.7 = surf ramp)
			if (0.7 <= vPlane[2] < 1.0)
			{
				/*
					Copy the ClipVelocity function from sdk2013 
					(https://mxr.alliedmods.net/hl2sdk-sdk2013/source/game/shared/gamemovement.cpp#3145)
					With some minor changes to make it actually work
				*/
				
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
					CopyVector(vVel, velocity);
					player.SetLandingVelocity(velocity);
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 < entity <= MaxClients);
}



// =====[ JUMPING ]=====

Action TweakJump(KZPlayer player, float velocity[3])
{
	if (player.HitPerf)
	{
		if (GetVectorHorizontalLength(velocity) > PERF_SPEED_CAP)
		{
			SetVectorHorizontalLength(velocity, PERF_SPEED_CAP);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
// =====[ OTHER ]=====

void FixWaterBoost(KZPlayer player, int buttons)
{
	if (GetEntProp(player.ID, Prop_Send, "m_nWaterLevel") >= 2) // WL_Waist = 2
	{
		// If duck is being pressed and we're not already ducking or on ground
		if (GetEntityFlags(player.ID) & (FL_DUCKING | FL_ONGROUND) == 0
			&& buttons & IN_DUCK && ~gI_OldButtons[player.ID] & IN_DUCK)
		{
			float newOrigin[3];
			Movement_GetOrigin(player.ID, newOrigin);
			newOrigin[2] += 9.0;
			
			TR_TraceHullFilter(newOrigin, newOrigin, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 54.0}), MASK_PLAYERSOLID, TraceEntityFilterPlayers);
			if (!TR_DidHit())
			{
				TeleportEntity(player.ID, newOrigin, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

void FixDisplacementStuck(KZPlayer player)
{
	int flags = GetEntityFlags(player.ID);
	bool unducked = ~flags & FL_DUCKING && gI_OldFlags[player.ID] & FL_DUCKING;
	
	float standingMins[] = {-16.0, -16.0, 0.0};
	float standingMaxs[] = {16.0, 16.0, 72.0};
	
	if (unducked)
	{
		// check if we're stuck after unducking and if we're stuck then force duck
		float origin[3];
		Movement_GetOrigin(player.ID, origin);
		TR_TraceHullFilter(origin, origin, standingMins, standingMaxs, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
		
		if (TR_DidHit())
		{
			player.SetVelocity(gF_OldVelocity[player.ID]);
			SetEntProp(player.ID, Prop_Send, "m_bDucking", true);
		}
	}
}

void RemoveCrouchJumpBind(KZPlayer player, int &buttons)
{
	if (player.OnGround && buttons & IN_JUMP && !(gI_OldButtons[player.ID] & IN_JUMP) && !(gI_OldButtons[player.ID] & IN_DUCK))
	{
		buttons &= ~IN_DUCK;
	}
}

void ReduceDuckSlowdown(KZPlayer player)
{
	if (GetEntProp(player.ID, Prop_Data, "m_afButtonReleased") & IN_DUCK)
	{
		Movement_SetDuckSpeed(player.ID, DUCK_SPEED_NORMAL);
	}
} 
