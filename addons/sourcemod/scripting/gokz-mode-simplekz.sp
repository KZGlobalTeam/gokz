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
	name = "GOKZ Mode - SimpleKZ", 
	author = "DanZay", 
	description = "SimpleKZ mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-mode-simplekz.txt"

#define MODE_VERSION 21
#define PS_MAX_REWARD_TURN_RATE 0.703125 // Degrees per tick (90 degrees per second)
#define PS_MAX_TURN_RATE_DECREMENT 0.015625 // Degrees per tick (2 degrees per second)
#define PS_SPEED_MAX 26.54321 // Units
#define PS_SPEED_INCREMENT 0.35 // Units per tick
#define PS_SPEED_DECREMENT_MIDAIR 0.2824 // Units per tick (lose PS_SPEED_MAX in 0 offset jump i.e. 94 ticks)
#define PS_GRACE_TICKS 3 // No. of ticks allowed to fail prestrafe checks when prestrafing - helps players with low fps
#define DUCK_SPEED_NORMAL 8.0
#define DUCK_SPEED_MINIMUM 6.0234375 // Equal to if you just ducked/unducked for the first time in a while

float gF_ModeCVarValues[MODECVAR_COUNT] = 
{
	6.5,  // sv_accelerate
	0.0,  // sv_accelerate_use_weapon_speed
	100.0,  // sv_airaccelerate
	30.0,  // sv_air_max_wishspeed
	1.0,  // sv_enablebunnyhopping
	5.2,  // sv_friction
	800.0,  // sv_gravity
	301.993377,  // sv_jump_impulse
	1.0,  // sv_ladder_scale_speed
	0.0,  // sv_ledge_mantle_helper
	320.0,  // sv_maxspeed
	3500.0,  // sv_maxvelocity
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
bool gB_HitTweakedPerf[MAXPLAYERS + 1];
int gI_Cmdnum[MAXPLAYERS + 1];
float gF_PSBonusSpeed[MAXPLAYERS + 1];
float gF_PSVelMod[MAXPLAYERS + 1];
float gF_PSVelModLanding[MAXPLAYERS + 1];
bool gB_PSTurningLeft[MAXPLAYERS + 1];
float gF_PSTurnRate[MAXPLAYERS + 1];
int gI_PSTicksSinceIncrement[MAXPLAYERS + 1];
Handle gH_GetPlayerMaxSpeed;
DynamicDetour gH_CanUnduck;
int gI_TickCount[MAXPLAYERS + 1];
DynamicDetour gH_AirAccelerate;
int gI_OldButtons[MAXPLAYERS + 1];
int gI_OldFlags[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
float gF_OldOrigin[MAXPLAYERS + 1][3];
float gF_OldAngles[MAXPLAYERS + 1][3];
float gF_OldVelocity[MAXPLAYERS + 1][3];
int gI_LastJumpButtonCmdnum[MAXPLAYERS + 1];
int gI_OffsetCGameMovement_player;



// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	if (FloatAbs(1.0 / GetTickInterval() - 128.0) > EPSILON)
	{
		SetFailState("gokz-mode-simplekz only supports 128 tickrate servers.");
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
		Updater_AddPlugin(UPDATER_URL);
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
	ResetClient(client);
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
	ReduceDuckSlowdown(player);
	CalcPrestrafeVelMod(player, angles);
	FixWaterBoost(player, buttons);
	FixDisplacementStuck(player);

	gB_HitTweakedPerf[player.ID] = false;
	gI_Cmdnum[player.ID] = cmdnum;
	gI_OldButtons[player.ID] = buttons;
	gI_OldFlags[player.ID] = GetEntityFlags(player.ID);
	gB_OldOnGround[player.ID] = player.OnGround;
	gI_TickCount[player.ID] = tickcount;
	player.GetOrigin(gF_OldOrigin[player.ID]);
	player.GetEyeAngles(gF_OldAngles[player.ID]);
	player.GetVelocity(gF_OldVelocity[player.ID]);
	
	return Plugin_Continue;
}

public MRESReturn DHooks_OnGetPlayerMaxSpeed(int client, Handle hReturn)
{
	if (!IsUsingMode(client))
	{
		return MRES_Ignored;
	}
	DHookSetReturn(hReturn, SPEED_NORMAL * gF_PSVelMod[client]);
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
	if (gF_PSVelMod[client] > 1.0)
	{
		DHookSetParam(hParams, 2, wishspeed / gF_PSVelMod[client]);
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

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return;
	}
	
	if (buttons & IN_JUMP)
	{
		gI_LastJumpButtonCmdnum[client] = cmdnum;
	}
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
	gF_PSVelModLanding[player.ID] = gF_PSVelMod[player.ID];
}

public Action Movement_OnJumpPre(int client, float origin[3], float velocity[3])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	
	KZPlayer player = KZPlayer(client);
	return TweakJump(player, origin, velocity);
}

public Action Movement_OnCategorizePositionPost(int client, float origin[3], float velocity[3])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	return SlopeFix(client, origin, velocity);
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
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_SimpleKZ)
	{
		ReplicateConVars(client);
	}
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	ResetClient(client);
}



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_SimpleKZ;
}

void ResetClient(int client)
{
	KZPlayer player = KZPlayer(client);
	ResetVelMod(player);
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
	/*
		Replicate convars only when player changes mode in GOKZ
		so that lagg isn't caused by other players using other
		modes, and also as an optimisation.
	*/
	
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

void ResetVelMod(KZPlayer player)
{
	gF_PSBonusSpeed[player.ID] = 0.0;
	gF_PSVelMod[player.ID] = 1.0;
	gF_PSTurnRate[player.ID] = 0.0;
}

void CalcPrestrafeVelMod(KZPlayer player, const float angles[3])
{
	gI_PSTicksSinceIncrement[player.ID]++;
	
	// Short circuit if speed is 0 (also avoids divide by 0 errors)
	if (player.Speed < EPSILON)
	{
		ResetVelMod(player);
		return;
	}
	
	// Current speed without bonus
	float baseSpeed = FloatMin(SPEED_NORMAL, player.Speed / gF_PSVelMod[player.ID]);
	
	float newBonusSpeed = gF_PSBonusSpeed[player.ID];
	
	// If player is in mid air, decrement their velocity modifier
	if (!player.OnGround)
	{
		newBonusSpeed -= PS_SPEED_DECREMENT_MIDAIR;
	}
	// If player is turning at the required speed, and has the correct button inputs, reward it
	else if (player.Turning && ValidPrestrafeButtons(player))
	{
		// If player changes their prestrafe direction, reset it
		if (player.TurningLeft && !gB_PSTurningLeft[player.ID]
			 || player.TurningRight && gB_PSTurningLeft[player.ID])
		{
			ResetVelMod(player);
			newBonusSpeed = 0.0;
		}
		
		// Keep track of the direction of the turn
		gB_PSTurningLeft[player.ID] = player.TurningLeft;
		
		// Step one of calculating new turn rate
		float newTurningRate = FloatAbs(CalcDeltaAngle(gF_OldAngles[player.ID][1], angles[1]));
		
		// If no turning for just a few ticks, then forgive and calculate reward based on that no. of ticks
		if (gI_PSTicksSinceIncrement[player.ID] <= PS_GRACE_TICKS)
		{
			// This turn occurred over multiple ticks, so scale appropriately
			// Also cap turn rate at maximum reward turn rate
			newTurningRate = FloatMin(PS_MAX_REWARD_TURN_RATE, 
				newTurningRate / gI_PSTicksSinceIncrement[player.ID]);
			
			// Limit how fast turn rate can decrease (also scaled appropriately)
			gF_PSTurnRate[player.ID] = FloatMax(newTurningRate, 
				gF_PSTurnRate[player.ID] - PS_MAX_TURN_RATE_DECREMENT * gI_PSTicksSinceIncrement[player.ID]);
			
			newBonusSpeed += CalcPreRewardSpeed(gF_PSTurnRate[player.ID], baseSpeed) * gI_PSTicksSinceIncrement[player.ID];
		}
		else
		{
			// Cap turn rate at maximum reward turn rate
			newTurningRate = FloatMin(PS_MAX_REWARD_TURN_RATE, newTurningRate);
			
			// Limit how fast turn rate can decrease
			gF_PSTurnRate[player.ID] = FloatMax(newTurningRate, 
				gF_PSTurnRate[player.ID] - PS_MAX_TURN_RATE_DECREMENT);
			
			// This is normal turning behaviour
			newBonusSpeed += CalcPreRewardSpeed(gF_PSTurnRate[player.ID], baseSpeed);
		}
		
		gI_PSTicksSinceIncrement[player.ID] = 0;
	}
	else if (gI_PSTicksSinceIncrement[player.ID] > PS_GRACE_TICKS)
	{
		// They definitely aren't turning, but limit how fast turn rate can decrease
		gF_PSTurnRate[player.ID] = FloatMax(0.0, 
			gF_PSTurnRate[player.ID] - PS_MAX_TURN_RATE_DECREMENT);
	}
	
	if (newBonusSpeed < 0.0)
	{
		// Keep velocity modifier positive
		newBonusSpeed = 0.0;
	}
	else
	{
		// Scale the bonus speed based on current base speed and turn rate
		float baseSpeedScaleFactor = baseSpeed / SPEED_NORMAL; // Max 1.0
		float turnRateScaleFactor = FloatMin(1.0, gF_PSTurnRate[player.ID] / PS_MAX_REWARD_TURN_RATE);
		float scaledMaxBonusSpeed = PS_SPEED_MAX * baseSpeedScaleFactor * turnRateScaleFactor;
		newBonusSpeed = FloatMin(newBonusSpeed, scaledMaxBonusSpeed);
	}
	
	gF_PSBonusSpeed[player.ID] = newBonusSpeed;
	gF_PSVelMod[player.ID] = 1.0 + (newBonusSpeed / baseSpeed);
}

bool ValidPrestrafeButtons(KZPlayer player)
{
	bool forwardOrBack = player.Buttons & (IN_FORWARD | IN_BACK) && !(player.Buttons & IN_FORWARD && player.Buttons & IN_BACK);
	bool leftOrRight = player.Buttons & (IN_MOVELEFT | IN_MOVERIGHT) && !(player.Buttons & IN_MOVELEFT && player.Buttons & IN_MOVERIGHT);
	return forwardOrBack || leftOrRight;
}

float CalcPreRewardSpeed(float yawDiff, float baseSpeed)
{
	// Formula
	float reward;
	if (yawDiff >= PS_MAX_REWARD_TURN_RATE)
	{
		reward = PS_SPEED_INCREMENT;
	}
	else
	{
		reward = PS_SPEED_INCREMENT * (yawDiff / PS_MAX_REWARD_TURN_RATE);
	}
	
	return reward * baseSpeed / SPEED_NORMAL;
}




// =====[ JUMPING ]=====

Action TweakJump(KZPlayer player, float origin[3], float velocity[3])
{
	// TakeoffCmdnum and TakeoffSpeed is not defined here because the player technically hasn't taken off yet.
	int cmdsSinceLanding = gI_Cmdnum[player.ID] - player.LandingCmdNum;
	gB_HitTweakedPerf[player.ID] = cmdsSinceLanding <= 1
	 || cmdsSinceLanding <= 3 && gI_Cmdnum[player.ID] - gI_LastJumpButtonCmdnum[player.ID] <= 3;
	
	if (gB_HitTweakedPerf[player.ID])
	{
		if (cmdsSinceLanding <= 1)
		{
			NerfRealPerf(player, origin);
		}

		ApplyTweakedTakeoffSpeed(player, velocity);

		if (cmdsSinceLanding > 1 || player.TakeoffSpeed > SPEED_NORMAL)
		{
			// Restore prestrafe lost due to briefly being on the ground
			gF_PSVelMod[player.ID] = gF_PSVelModLanding[player.ID];
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action Movement_OnJumpPost(int client)
{
	if (!IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	KZPlayer player = KZPlayer(client);
	player.GOKZHitPerf = gB_HitTweakedPerf[player.ID];
	player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	return Plugin_Continue;
}

public void Movement_OnStopTouchGround(int client)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	KZPlayer player = KZPlayer(client);
	player.GOKZHitPerf = gB_HitTweakedPerf[player.ID];
	player.GOKZTakeoffSpeed = player.TakeoffSpeed;
}

void NerfRealPerf(KZPlayer player, float origin[3])
{
	// Not worth worrying about if player is already falling
	// player.VerticalVelocity is not updated yet! Use processing velocity.
	float velocity[3];
	Movement_GetProcessingVelocity(player.ID, velocity);
	if (velocity[2] < EPSILON)
	{
		return;
	}
	
	// Work out where the ground was when they bunnyhopped
	float startPosition[3], endPosition[3], mins[3], maxs[3], groundOrigin[3];
	
	startPosition = origin;
	
	endPosition = startPosition;
	endPosition[2] = endPosition[2] - 2.0; // Should be less than 2.0 units away
	
	GetEntPropVector(player.ID, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(player.ID, Prop_Send, "m_vecMaxs", maxs);
	
	Handle trace = TR_TraceHullFilterEx(
		startPosition, 
		endPosition, 
		mins, 
		maxs, 
		MASK_PLAYERSOLID, 
		TraceEntityFilterPlayers, 
		player.ID);
	
	// This is expected to always hit, previously this can fail upon jumpbugs.
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(groundOrigin, trace);
		origin[2] = groundOrigin[2];
	}
	
	delete trace;
}

void ApplyTweakedTakeoffSpeed(KZPlayer player, float velocity[3])
{
	// Note that resulting velocity has same direction as landing velocity, not current velocity
	// because current velocity direction can change drastically in just one tick (eg. walls)
	// and it doesnt make sense for the new velocity to push you in that direction.

	float newVelocity[3], baseVelocity[3];
	player.GetLandingVelocity(newVelocity);
	player.GetBaseVelocity(baseVelocity);
	SetVectorHorizontalLength(newVelocity, CalcTweakedTakeoffSpeed(player));
	AddVectors(newVelocity, baseVelocity, newVelocity); // For backwards compatibility
	velocity[0] = newVelocity[0];
	velocity[1] = newVelocity[1];
}

// Takeoff speed assuming player has met the conditions to need tweaking
float CalcTweakedTakeoffSpeed(KZPlayer player)
{
	// Formula
	if (player.LandingSpeed > SPEED_NORMAL)
	{
		return FloatMin(player.LandingSpeed, (0.2 * player.LandingSpeed + 200) * gF_PSVelModLanding[player.ID]);
	}
	return player.LandingSpeed;
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
			
			TR_TraceHullFilter(newOrigin, newOrigin, view_as<float>( { -16.0, -16.0, 0.0 } ), view_as<float>( { 16.0, 16.0, 54.0 } ), MASK_PLAYERSOLID, TraceEntityFilterPlayers);
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
	/*
		Duck speed is reduced by the game upon ducking or unducking.
		The goal here is to accept that duck speed is reduced, but
		stop it from being reduced further when spamming duck.

		This is done by enforcing a minimum duck speed equivalent to
		the value as if the player only ducked once. When not in not
		in the middle of ducking, duck speed is reset to its normal
		value in effort to reduce the number of times the minimum
		duck speed is enforced. This should reduce noticeable lagg.
	*/
	
	if (!GetEntProp(player.ID, Prop_Send, "m_bDucking")
		 && player.DuckSpeed < DUCK_SPEED_NORMAL - EPSILON)
	{
		player.DuckSpeed = DUCK_SPEED_NORMAL;
	}
	else if (player.DuckSpeed < DUCK_SPEED_MINIMUM - EPSILON)
	{
		player.DuckSpeed = DUCK_SPEED_MINIMUM;
	}
}
