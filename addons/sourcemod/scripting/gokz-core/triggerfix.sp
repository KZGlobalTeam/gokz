

// Credits:
// RNGFix made by rio https://github.com/jason-e/rngfix


// Engine constants, NOT settings (do not change)
#define LAND_HEIGHT 2.0 					// Maximum height above ground at which you can "land"
#define MIN_STANDABLE_ZNRM 0.7				// Minimum surface normal Z component of a walkable surface

static int processMovementTicks[MAXPLAYERS+1];
static float playerFrameTime[MAXPLAYERS+1];

static bool touchingTrigger[MAXPLAYERS+1][2048];
static bool triggerTouchFired[MAXPLAYERS+1][2048];
static int lastGroundEnt[MAXPLAYERS + 1];
static bool duckedLastTick[MAXPLAYERS + 1];
static bool mapTeleportedSequentialTicks[MAXPLAYERS+1];
static bool jumpBugged[MAXPLAYERS + 1];
static float jumpBugOrigin[MAXPLAYERS + 1][3];

static ConVar cvGravity;

static Handle acceptInputHookPre;
static Handle processMovementHookPre;
static Address serverGameEnts;
static Handle markEntitiesAsTouching;
static Handle passesTriggerFilters;

public void OnPluginStart_Triggerfix()
{
	HookEvent("player_jump", Event_PlayerJump);
	
	cvGravity = FindConVar("sv_gravity");
	if (cvGravity == null)
	{
		SetFailState("Could not find sv_gravity");
	}
	
	GameData gamedataConf = LoadGameConfigFile("gokz-core.games");
	if (gamedataConf == null)
	{
		SetFailState("Failed to load gokz-core gamedata");
	}
	
	// PassesTriggerFilters
	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(gamedataConf, SDKConf_Virtual, "CBaseTrigger::PassesTriggerFilters"))
	{
		SetFailState("Failed to get CBaseTrigger::PassesTriggerFilters offset");
	}
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	passesTriggerFilters = EndPrepSDKCall();

	if (passesTriggerFilters == null) SetFailState("Unable to prepare SDKCall for CBaseTrigger::PassesTriggerFilters");
	
	// CreateInterface
	// Thanks SlidyBat and ici
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(gamedataConf, SDKConf_Signature, "CreateInterface"))
	{
		SetFailState("Failed to get CreateInterface");
	}
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle CreateInterface = EndPrepSDKCall();
	
	if (CreateInterface == null)
	{
		SetFailState("Unable to prepare SDKCall for CreateInterface");
	}
	
	char interfaceName[64];
	
	// ProcessMovement
	if (!GameConfGetKeyValue(gamedataConf, "IGameMovement", interfaceName, sizeof(interfaceName)))
	{
		SetFailState("Failed to get IGameMovement interface name");
	}
	Address IGameMovement = SDKCall(CreateInterface, interfaceName, 0);
	if (!IGameMovement)
	{
		SetFailState("Failed to get IGameMovement pointer");
	}
	
	int offset = GameConfGetOffset(gamedataConf, "ProcessMovement");
	if (offset == -1)
	{
		SetFailState("Failed to get ProcessMovement offset");
	}
	
	processMovementHookPre = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, DHook_ProcessMovementPre);
	DHookAddParam(processMovementHookPre, HookParamType_CBaseEntity);
	DHookAddParam(processMovementHookPre, HookParamType_ObjectPtr);
	DHookRaw(processMovementHookPre, false, IGameMovement);
	
	// MarkEntitiesAsTouching
	if (!GameConfGetKeyValue(gamedataConf, "IServerGameEnts", interfaceName, sizeof(interfaceName)))
	{
		SetFailState("Failed to get IServerGameEnts interface name");
	}
	serverGameEnts = SDKCall(CreateInterface, interfaceName, 0);
	if (!serverGameEnts)
	{
		SetFailState("Failed to get IServerGameEnts pointer");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(gamedataConf, SDKConf_Virtual, "IServerGameEnts::MarkEntitiesAsTouching"))
	{
		SetFailState("Failed to get IServerGameEnts::MarkEntitiesAsTouching offset");
	}
	PrepSDKCall_AddParameter(SDKType_Edict, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Edict, SDKPass_Pointer);
	markEntitiesAsTouching = EndPrepSDKCall();
	
	if (markEntitiesAsTouching == null)
	{
		SetFailState("Unable to prepare SDKCall for IServerGameEnts::MarkEntitiesAsTouching");
	}

	gamedataConf = LoadGameConfigFile("sdktools.games/engine.csgo");
	offset = gamedataConf.GetOffset("AcceptInput");
	if (offset == -1)
	{
		SetFailState("Failed to get AcceptInput offset");
	}

	acceptInputHookPre = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, DHooks_AcceptInput);
	DHookAddParam(acceptInputHookPre, HookParamType_CharPtr);
	DHookAddParam(acceptInputHookPre, HookParamType_CBaseEntity);
	DHookAddParam(acceptInputHookPre, HookParamType_CBaseEntity);
	//varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
	DHookAddParam(acceptInputHookPre, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP);
	DHookAddParam(acceptInputHookPre, HookParamType_Int);
	
	delete CreateInterface;
	delete gamedataConf;
	
	if (gB_LateLoad)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client)) OnClientPutInServer(client);
		}
		
		char classname[64];
		for (int entity = MaxClients+1; entity < sizeof(touchingTrigger[]); entity++)
		{
			if (!IsValidEntity(entity)) continue;
			GetEntPropString(entity, Prop_Data, "m_iClassname", classname, sizeof(classname));
			HookTrigger(entity, classname);
		}
	}
}

public void OnEntityCreated_Triggerfix(int entity, const char[] classname)
{
	if (entity >= sizeof(touchingTrigger[]))
	{
		return;
	}
	HookTrigger(entity, classname);
}

public void OnClientConnected_Triggerfix(int client)
{
	processMovementTicks[client] = 0;
	for (int i = 0; i < sizeof(touchingTrigger[]); i++)
	{
		touchingTrigger[client][i] = false;
		triggerTouchFired[client][i] = false;
	}
}

public void OnClientPutInServer_Triggerfix(int client)
{
	SDKHook(client, SDKHook_PostThink, Hook_PlayerPostThink);
	DHookEntity(acceptInputHookPre, false, client);
}

public void OnGameFrame_Triggerfix()
{
	// Loop through all the players and make sure that triggers that are supposed to be fired but weren't now
	// get fired properly.
	// This must be run OUTSIDE of usercmd, because sometimes usercmd gets delayed heavily.
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client) && !CheckWater(client) && 
			(GetEntityMoveType(client) == MOVETYPE_WALK || GetEntityMoveType(client) == MOVETYPE_LADDER))
		{
			DoTriggerFix(client);

			// Reset the Touch tracking. 
			// We save a bit of performance by putting this inside the loop
			// Even if triggerTouchFired is not correct, touchingTrigger still is. 
			// That should prevent DoTriggerFix from activating the wrong triggers. 
			// Plus, players respawn where they previously are as well with a timer on,
			// so this should not be a big problem.
			for (int trigger = 0; trigger < sizeof(triggerTouchFired[]); trigger++)
			{
				triggerTouchFired[client][trigger] = false;
			}
		}
	}
}

static void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	jumpBugged[client] = !!lastGroundEnt[client];
	if (jumpBugged[client])
	{
		GetClientAbsOrigin(client, jumpBugOrigin[client]);
		// if player's origin is still in the ducking position then adjust for that.
		if (duckedLastTick[client] && !Movement_GetDucking(client))
		{
			jumpBugOrigin[client][2] -= 9.0;
		}
	}
}

static Action Hook_TriggerStartTouch(int entity, int other)
{
	if (1 <= other <= MaxClients)
	{
		touchingTrigger[other][entity] = true;
	}
	
	return Plugin_Continue;
}

static Action Hook_TriggerEndTouch(int entity, int other)
{
	if (1 <= other <= MaxClients)
	{
	 	touchingTrigger[other][entity] = false;
	}
	return Plugin_Continue;
}

static Action Hook_TriggerTouch(int entity, int other)
{
	if (1 <= other <= MaxClients)
	{
	 	triggerTouchFired[other][entity] = true;
	}
	return Plugin_Continue;	
}

static MRESReturn DHook_ProcessMovementPre(Handle hParams)
{
	int client = DHookGetParam(hParams, 1);
	
	processMovementTicks[client]++;
	playerFrameTime[client] = GetTickInterval() * GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
	mapTeleportedSequentialTicks[client] = false;
	
	if (IsPlayerAlive(client))
	{
		if (GetEntityMoveType(client) == MOVETYPE_WALK
			&& !CheckWater(client))
		{
			lastGroundEnt[client] = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");
		}
		duckedLastTick[client] = Movement_GetDucking(client);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHooks_AcceptInput(int client, DHookReturn hReturn, DHookParam hParams)
{	
	if (!IsValidClient(client) || !IsPlayerAlive(client) || CheckWater(client) || 
		(GetEntityMoveType(client) != MOVETYPE_WALK && GetEntityMoveType(client) != MOVETYPE_LADDER))
	{
		return MRES_Ignored;
	}
	
	// Get args
	static char param[64];
	static char command[64];
	DHookGetParamString(hParams, 1, command, sizeof(command));
	if (StrEqual(command, "AddOutput"))
	{
		DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, param, sizeof(param));
		char kv[16];
		SplitString(param, " ", kv, sizeof(kv));
		// KVs are case insensitive.
		// Any of these inputs can change the filter behavior.
		if (StrEqual(kv[0], "targetname", false) || StrEqual(kv[0], "teamnumber", false) || StrEqual(kv[0], "classname", false) || StrEqual(command, "ResponseContext", false))
		{
			DoTriggerFix(client, true);
		}
	}
	else if (StrEqual(command, "AddContext") || StrEqual(command, "RemoveContext") || StrEqual(command, "ClearContext"))
	{
		DoTriggerFix(client, true);
	}
	return MRES_Ignored;
}

static bool DoTriggerFix(int client, bool filterFix = false)
{
	// Adapted from DoTriggerjumpFix right below.
	float landingMins[3], landingMaxs[3];
	float origin[3];

	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	GetEntPropVector(client, Prop_Data, "m_vecMins", landingMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", landingMaxs);

	ArrayList triggers = new ArrayList();
	// Get a list of triggers that we are touching now.

	TR_EnumerateEntitiesHull(origin, origin, landingMins, landingMaxs, true, AddTrigger, triggers);
	
	bool didSomething = false;
	
	for (int i = 0; i < triggers.Length; i++)
	{
		int trigger = triggers.Get(i);
		if (!touchingTrigger[client][trigger])
		{
			// Normally this wouldn't happen, because the trigger should be colliding with the player's hull if it gets here.
			continue;
		}
		char className[64];
		GetEntityClassname(trigger, className, sizeof(className));
		if (StrEqual(className, "trigger_push"))
		{
			// Completely ignore push triggers.
			continue;
		}
		if (filterFix && SDKCall(passesTriggerFilters, trigger, client))
		{
			// MarkEntitiesAsTouching always fires the Touch function even if it was already fired this tick.
			SDKCall(markEntitiesAsTouching, serverGameEnts, client, trigger);
			
			// Player properties might be changed right after this so it will need to be triggered again.
			triggerTouchFired[client][trigger] = false;
			didSomething = true;
		}
		else if (!triggerTouchFired[client][trigger])
		{
			// If the player is still touching the trigger on this tick, and Touch was not called for whatever reason
			// in the last tick, we make sure that it is called now.
			SDKCall(markEntitiesAsTouching, serverGameEnts, client, trigger);
			didSomething = true;
		}
	}
	
	delete triggers;
	
	return didSomething;
}

static bool DoTriggerjumpFix(int client, const float landingPoint[3], const float landingMins[3], const float landingMaxs[3])
{
	// It's possible to land above a trigger but also in another trigger_teleport, have the teleport move you to
	// another location, and then the trigger jumping fix wouldn't fire the other trigger you technically landed above,
	// but I can't imagine a mapper would ever actually stack triggers like that.
	
	float origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	
	float landingMaxsBelow[3];
	landingMaxsBelow[0] = landingMaxs[0];
	landingMaxsBelow[1] = landingMaxs[1];
	landingMaxsBelow[2] = origin[2] - landingPoint[2];
	
	ArrayList triggers = new ArrayList();
	
	// Find triggers that are between us and the ground (using the bounding box quadrant we landed with if applicable).
	// This will fail on triggers thinner than 0.03125 unit thick, but it's highly unlikely that a mapper would put a trigger that thin.
	TR_EnumerateEntitiesHull(landingPoint, landingPoint, landingMins, landingMaxsBelow, true, AddTrigger, triggers);
	
	bool didSomething = false;
	
	for (int i = 0; i < triggers.Length; i++)
	{
		int trigger = triggers.Get(i);
		
		// MarkEntitiesAsTouching always fires the Touch function even if it was already fired this tick.
		// In case that could cause side-effects, manually keep track of triggers we are actually touching
		// and don't re-touch them.
		if (touchingTrigger[client][trigger])
		{
			continue;
		}
		
		SDKCall(markEntitiesAsTouching, serverGameEnts, client, trigger);
		didSomething = true;
	}
	
	delete triggers;
	
	return didSomething;
}

// PostThink works a little better than a ProcessMovement post hook because we need to wait for ProcessImpacts (trigger activation)
static void Hook_PlayerPostThink(int client)
{
	if (!IsPlayerAlive(client)
		|| GetEntityMoveType(client) != MOVETYPE_WALK
		|| CheckWater(client))
	{
		return;
	}
	
	bool landed = (GetEntPropEnt(client, Prop_Data, "m_hGroundEntity") != -1
		&& lastGroundEnt[client] == -1)
		|| jumpBugged[client];
	
	float landingMins[3], landingMaxs[3], landingPoint[3];
	
	// Get info about the ground we landed on (if we need to do landing fixes).
	if (landed)
	{
		float origin[3], nrm[3], velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		
		if (jumpBugged[client])
		{
			origin = jumpBugOrigin[client];
		}
		
		GetEntPropVector(client, Prop_Data, "m_vecMins", landingMins);
		GetEntPropVector(client, Prop_Data, "m_vecMaxs", landingMaxs);
		
		float originBelow[3];
		originBelow[0] = origin[0];
		originBelow[1] = origin[1];
		originBelow[2] = origin[2] - LAND_HEIGHT;
		
		TR_TraceHullFilter(origin, originBelow, landingMins, landingMaxs, MASK_PLAYERSOLID, PlayerFilter);
		
		if (!TR_DidHit())
		{
			// This should never happen, since we know we are on the ground.
			landed = false;
		}
		else
		{
			TR_GetPlaneNormal(null, nrm);
			
			if (nrm[2] < MIN_STANDABLE_ZNRM)
			{
				// This is rare, and how the incline fix should behave isn't entirely clear because maybe we should
				// collide with multiple faces at once in this case, but let's just get the ground we officially
				// landed on and use that for our ground normal.
				
				// landingMins and landingMaxs will contain the final values used to find the ground after returning.
				if (TracePlayerBBoxForGround(origin, originBelow, landingMins, landingMaxs))
				{
					TR_GetPlaneNormal(null, nrm);
				}
				else
				{
					// This should also never happen.
					landed = false;
				}
			}
			
			TR_GetEndPosition(landingPoint);
		}
	}
	
	// reset it here because we don't need it again
	jumpBugged[client] = false;
	
	// Must use TR_DidHit because if the unduck origin is closer than 0.03125 units from the ground, 
	// the trace fraction would return 0.0.
	if (landed && TR_DidHit())
	{
		DoTriggerjumpFix(client, landingPoint, landingMins, landingMaxs);
		// Check if a trigger we just touched put us in the air (probably due to a teleport).
		if (GetEntityFlags(client) & FL_ONGROUND == 0)
		{
			landed = false;
		}
	}
}

static bool PlayerFilter(int entity, int mask)
{
	return !(1 <= entity <= MaxClients);
}

static void HookTrigger(int entity, const char[] classname)
{
	if (StrContains(classname, "trigger_") != -1)
	{
		SDKHook(entity, SDKHook_StartTouchPost, Hook_TriggerStartTouch);
		SDKHook(entity, SDKHook_EndTouchPost, Hook_TriggerEndTouch);
		SDKHook(entity, SDKHook_TouchPost, Hook_TriggerTouch);
	}
}

static bool CheckWater(int client)
{
	// The cached water level is updated multiple times per tick, including after movement happens,
	// so we can just check the cached value here.
	return GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1;
}

public bool AddTrigger(int entity, ArrayList triggers)
{
	TR_ClipCurrentRayToEntity(MASK_ALL, entity);
	if (TR_DidHit())
	{
		triggers.Push(entity);
	}
	
	return true;
}

static bool TracePlayerBBoxForGround(const float origin[3], const float originBelow[3], float mins[3], float maxs[3])
{
	// See CGameMovement::TracePlayerBBoxForGround()
	
	float origMins[3], origMaxs[3];
	origMins = mins;
	origMaxs = maxs;
	
	float nrm[3];
	
	mins = origMins;
	
	// -x -y
	maxs[0] = origMaxs[0] > 0.0 ? 0.0 : origMaxs[0];
	maxs[1] = origMaxs[1] > 0.0 ? 0.0 : origMaxs[1];
	maxs[2] = origMaxs[2];
	
	TR_TraceHullFilter(origin, originBelow, mins, maxs, MASK_PLAYERSOLID, PlayerFilter);
	
	if (TR_DidHit())
	{
		TR_GetPlaneNormal(null, nrm);
		if (nrm[2] >= MIN_STANDABLE_ZNRM)
		{
			return true;
		}
	}
	
	// +x +y
	mins[0] = origMins[0] < 0.0 ? 0.0 : origMins[0];
	mins[1] = origMins[1] < 0.0 ? 0.0 : origMins[1];
	mins[2] = origMins[2];
	
	maxs = origMaxs;
	
	TR_TraceHullFilter(origin, originBelow, mins, maxs, MASK_PLAYERSOLID, PlayerFilter);

	if (TR_DidHit())
	{
		TR_GetPlaneNormal(null, nrm);
		if (nrm[2] >= MIN_STANDABLE_ZNRM)
		{
			return true;
		}
	}
	
	// -x +y
	mins[0] = origMins[0];
	mins[1] = origMins[1] < 0.0 ? 0.0 : origMins[1];
	mins[2] = origMins[2];
	
	maxs[0] = origMaxs[0] > 0.0 ? 0.0 : origMaxs[0];
	maxs[1] = origMaxs[1];
	maxs[2] = origMaxs[2];
	
	TR_TraceHullFilter(origin, originBelow, mins, maxs, MASK_PLAYERSOLID, PlayerFilter);
	
	if (TR_DidHit())
	{
		TR_GetPlaneNormal(null, nrm);
		if (nrm[2] >= MIN_STANDABLE_ZNRM)
		{
			return true;
		}
	}
	
	// +x -y
	mins[0] = origMins[0] < 0.0 ? 0.0 : origMins[0];
	mins[1] = origMins[1];
	mins[2] = origMins[2];
	
	maxs[0] = origMaxs[0];
	maxs[1] = origMaxs[1] > 0.0 ? 0.0 : origMaxs[1];
	maxs[2] = origMaxs[2];
	
	TR_TraceHullFilter(origin, originBelow, mins, maxs, MASK_PLAYERSOLID, PlayerFilter);
	
	if (TR_DidHit())
	{
		TR_GetPlaneNormal(null, nrm);
		if (nrm[2] >= MIN_STANDABLE_ZNRM)
		{
			return true;
		}
	}

	return false;
}
