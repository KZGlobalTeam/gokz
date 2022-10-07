/*
	Mapping API - Triggers
	
	Implements trigger related features.
*/



static float lastTrigMultiTouchTime[MAXPLAYERS + 1];
static float lastTrigTeleTouchTime[MAXPLAYERS + 1];
static float lastTouchGroundOrLadderTime[MAXPLAYERS + 1];
static int lastTouchSingleBhopEntRef[MAXPLAYERS + 1];
static ArrayList lastTouchSequentialBhopEntRefs[MAXPLAYERS + 1];
static int triggerTouchCount[MAXPLAYERS + 1];
static int antiCpTriggerTouchCount[MAXPLAYERS + 1];
static int antiPauseTriggerTouchCount[MAXPLAYERS + 1];
static int antiJumpstatTriggerTouchCount[MAXPLAYERS + 1];
static int mapMappingApiVersion = GOKZ_MAPPING_API_VERSION_NONE;
static int bhopTouchCount[MAXPLAYERS + 1];
static bool jumpedThisTick[MAXPLAYERS + 1];
static float jumpOrigin[MAXPLAYERS + 1][3];
static float jumpVelocity[MAXPLAYERS + 1][3];
static ArrayList triggerTouchList[MAXPLAYERS + 1]; // arraylist of TouchedTrigger that the player is currently touching. this array won't ever get long (unless the mapper does something weird).
static StringMap triggerTouchCounts[MAXPLAYERS + 1]; // stringmap of int touch counts with key being a string of the entity reference.
static StringMap antiBhopTriggers; // stringmap of AntiBhopTrigger with key being a string of the m_iHammerID entprop.
static StringMap teleportTriggers; // stringmap of TeleportTrigger with key being a string of the m_iHammerID entprop.
static StringMap timerButtonTriggers; // stringmap of legacy timer zone triggers with key being a string of the m_iHammerID entprop.
static ArrayList parseErrorStrings;



// =====[ PUBLIC ]=====

bool BhopTriggersJustTouched(int client)
{
	// NOTE: This is slightly incorrect since we touch triggers in the air, but
	// it doesn't matter since we can't checkpoint in the air.
	if (bhopTouchCount[client] > 0)
	{
		return true;
	}
	// GetEngineTime return changes between calls. We only call it once at the beginning.
	float engineTime = GetEngineTime();
	// If the player touches a teleport trigger, increase the delay required
	if (engineTime - lastTouchGroundOrLadderTime[client] < GOKZ_MULT_NO_CHECKPOINT_TIME // Just touched ground or ladder
		&& engineTime - lastTrigMultiTouchTime[client] < GOKZ_MULT_NO_CHECKPOINT_TIME // Just touched trigger_multiple
		|| engineTime - lastTrigTeleTouchTime[client] < GOKZ_BHOP_NO_CHECKPOINT_TIME) // Just touched trigger_teleport
	{
		return true;
	}
	
	return Movement_GetMovetype(client) == MOVETYPE_LADDER
		&& triggerTouchCount[client] > 0
		&& engineTime - lastTrigTeleTouchTime[client] < GOKZ_LADDER_NO_CHECKPOINT_TIME;
}

bool AntiCpTriggerIsTouched(int client)
{
	return antiCpTriggerTouchCount[client] > 0;
}

bool AntiPauseTriggerIsTouched(int client)
{
	return antiPauseTriggerTouchCount[client] > 0;
}

void PushMappingApiError(char[] format, any ...)
{
	char error[GOKZ_MAX_MAPTRIGGERS_ERROR_LENGTH];
	VFormat(error, sizeof(error), format, 2);
	parseErrorStrings.PushString(error);
}

TriggerType GetTriggerType(char[] targetName)
{
	TriggerType result = TriggerType_Invalid;
	
	if (StrEqual(targetName, GOKZ_ANTI_BHOP_TRIGGER_NAME))
	{
		result = TriggerType_Antibhop;
	}
	else if (StrEqual(targetName, GOKZ_TELEPORT_TRIGGER_NAME))
	{
		result = TriggerType_Teleport;
	}
	
	return result;
}

bool IsBhopTrigger(TeleportType type)
{
	return type == TeleportType_MultiBhop
			|| type == TeleportType_SingleBhop
			|| type == TeleportType_SequentialBhop;
}

bool IsTimerButtonTrigger(int entity, TimerButtonTrigger trigger)
{
	char hammerID[32];
	bool gotHammerID = GetEntityHammerIDString(entity, hammerID, sizeof(hammerID));
	if (gotHammerID && timerButtonTriggers.GetArray(hammerID, trigger, sizeof(trigger)))
	{
		return true;
	}
	return false;
}

// =====[ EVENTS ]=====

void OnPluginStart_MapTriggers()
{
	parseErrorStrings = new ArrayList(ByteCountToCells(GOKZ_MAX_MAPTRIGGERS_ERROR_LENGTH));
	antiBhopTriggers = new StringMap();
	teleportTriggers = new StringMap();
	timerButtonTriggers = new StringMap();
}

void OnMapStart_MapTriggers()
{
	parseErrorStrings.Clear();
	antiBhopTriggers.Clear();
	teleportTriggers.Clear();
	timerButtonTriggers.Clear();
	mapMappingApiVersion = GOKZ_MAPPING_API_VERSION_NONE;
	EntlumpParse(antiBhopTriggers, teleportTriggers, timerButtonTriggers, mapMappingApiVersion);
	
	if (mapMappingApiVersion > GOKZ_MAPPING_API_VERSION)
	{
		SetFailState("Map's mapping api version is too big! Maximum supported version is %i, but map has %i. If you're not on the latest GOKZ version, then update!",
			GOKZ_MAPPING_API_VERSION, mapMappingApiVersion);
	}
}

void OnClientPutInServer_MapTriggers(int client)
{
	triggerTouchCount[client] = 0;
	antiCpTriggerTouchCount[client] = 0;
	antiPauseTriggerTouchCount[client] = 0;
	antiJumpstatTriggerTouchCount[client] = 0;
	
	if (triggerTouchList[client] == null)
	{
		triggerTouchList[client] = new ArrayList(sizeof(TouchedTrigger));
	}
	else
	{
		triggerTouchList[client].Clear();
	}
	
	if (triggerTouchCounts[client] == null)
	{
		triggerTouchCounts[client] = new StringMap();
	}
	else
	{
		triggerTouchCounts[client].Clear();
	}
	
	bhopTouchCount[client] = 0;
	
	if (lastTouchSequentialBhopEntRefs[client] == null)
	{
		lastTouchSequentialBhopEntRefs[client] = new ArrayList();
	}
	else
	{
		lastTouchSequentialBhopEntRefs[client].Clear();
	}
}

void OnPlayerRunCmd_MapTriggers(int client, int &buttons)
{
	int flags = GetEntityFlags(client);
	MoveType moveType = GetEntityMoveType(client);
	
	// if the player isn't touching any bhop triggers on ground/a ladder, then
	// reset the singlebhop and sequential bhop state.
	if ((flags & FL_ONGROUND || moveType == MOVETYPE_LADDER)
		&& bhopTouchCount[client] == 0)
	{
		ResetBhopState(client);
	}
	
	if (antiJumpstatTriggerTouchCount[client] > 0)
	{
		if (GetFeatureStatus(FeatureType_Native, "GOKZ_JS_InvalidateJump") == FeatureStatus_Available)
		{
			GOKZ_JS_InvalidateJump(client);
		}
	}
	
	// Check if we're touching any triggers and act accordingly.
	// NOTE: Read through the touch list in reverse order, so some
	// trigger behaviours will be better. Trust me!
	int triggerTouchListLength = triggerTouchList[client].Length;
	for (int i = triggerTouchListLength - 1; i >= 0; i--)
	{
		TouchedTrigger touched;
		triggerTouchList[client].GetArray(i, touched);
		
		if (touched.triggerType == TriggerType_Antibhop)
		{
			TouchAntibhopTrigger(client, touched, buttons, flags);
		}
		else if (touched.triggerType == TriggerType_Teleport)
		{
			// Sometimes due to lag or whatever, the player can be
			// teleported twice by the same trigger. This fixes that.
			if (TouchTeleportTrigger(client, touched, flags))
			{
				RemoveTriggerFromTouchList(client, EntRefToEntIndex(touched.entRef));
				i--;
				triggerTouchListLength--;
			}
		}
	}
	jumpedThisTick[client] = false;
}

void OnPlayerSpawn_MapTriggers(int client)
{
	// Print trigger errors every time a player spawns so that
	// mappers and testers can very easily spot mistakes in names
	// and get them fixed asap.
	if (parseErrorStrings.Length > 0)
	{
		char errStart[] = "ERROR: Errors detected when trying to load triggers!";
		CPrintToChat(client, "{red}%s", errStart);
		PrintToConsole(client, "\n%s", errStart);
		
		int length = parseErrorStrings.Length;
		for (int err = 0; err < length; err++)
		{
			char error[GOKZ_MAX_MAPTRIGGERS_ERROR_LENGTH];
			parseErrorStrings.GetString(err, error, sizeof(error));
			CPrintToChat(client, "{red}%s", error);
			PrintToConsole(client, error);
		}
		CPrintToChat(client, "{red}If the errors get clipped off in the chat, then look in your developer console!\n");
	}
}

public void OnPlayerJump_Triggers(int client)
{
	jumpedThisTick[client] = true;
	GetClientAbsOrigin(client, jumpOrigin[client]);
	Movement_GetVelocity(client, jumpVelocity[client]);
}

void OnEntitySpawned_MapTriggers(int entity)
{
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	char name[64];
	GetEntityName(entity, name, sizeof(name));
	
	bool triggerMultiple = StrEqual("trigger_multiple", classname);
	if (triggerMultiple)
	{
		char hammerID[32];
		bool gotHammerID = GetEntityHammerIDString(entity, hammerID, sizeof(hammerID));
		
		if (StrEqual(GOKZ_TELEPORT_TRIGGER_NAME, name))
		{
			TeleportTrigger teleportTrigger;
			if (gotHammerID && teleportTriggers.GetArray(hammerID, teleportTrigger, sizeof(teleportTrigger)))
			{
				HookSingleEntityOutput(entity, "OnStartTouch", OnTeleportTrigTouchStart_MapTriggers);
				HookSingleEntityOutput(entity, "OnEndTouch", OnTeleportTrigTouchEnd_MapTriggers);
			}
			else
			{
				PushMappingApiError("ERROR: Couldn't match teleport trigger's Hammer ID %s with any Hammer ID from the map.", hammerID);
			}
		}
		else if (StrEqual(GOKZ_ANTI_BHOP_TRIGGER_NAME, name))
		{
			AntiBhopTrigger antiBhopTrigger;
			if (gotHammerID && antiBhopTriggers.GetArray(hammerID, antiBhopTrigger, sizeof(antiBhopTrigger)))
			{
				HookSingleEntityOutput(entity, "OnStartTouch", OnAntiBhopTrigTouchStart_MapTriggers);
				HookSingleEntityOutput(entity, "OnEndTouch", OnAntiBhopTrigTouchEnd_MapTriggers);
			}
			else
			{
				PushMappingApiError("ERROR: Couldn't match antibhop trigger's Hammer ID %s with any Hammer ID from the map.", hammerID);
			}
		}
		else if (StrEqual(GOKZ_BHOP_RESET_TRIGGER_NAME, name))
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnBhopResetTouchStart_MapTriggers);
		}
		else if (StrEqual(GOKZ_ANTI_CP_TRIGGER_NAME, name, false))
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnAntiCpTrigTouchStart_MapTriggers);
			HookSingleEntityOutput(entity, "OnEndTouch", OnAntiCpTrigTouchEnd_MapTriggers);
		}
		else if (StrEqual(GOKZ_ANTI_PAUSE_TRIGGER_NAME, name, false))
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnAntiPauseTrigTouchStart_MapTriggers);
			HookSingleEntityOutput(entity, "OnEndTouch", OnAntiPauseTrigTouchEnd_MapTriggers);
		}
		else if (StrEqual(GOKZ_ANTI_JUMPSTAT_TRIGGER_NAME, name, false))
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnAntiJumpstatTrigTouchStart_MapTriggers);
			HookSingleEntityOutput(entity, "OnEndTouch", OnAntiJumpstatTrigTouchEnd_MapTriggers);
		}
		else
		{
			// NOTE: SDKHook touch hooks bypass trigger filters. We want that only with
			// non mapping api triggers because it prevents checkpointing on bhop blocks.
			SDKHook(entity, SDKHook_StartTouchPost, OnTrigMultTouchStart_MapTriggers);
			SDKHook(entity, SDKHook_EndTouchPost, OnTrigMultTouchEnd_MapTriggers);
		}
	}
	else if (StrEqual("trigger_teleport", classname))
	{
		SDKHook(entity, SDKHook_StartTouchPost, OnTrigTeleTouchStart_MapTriggers);
		SDKHook(entity, SDKHook_EndTouchPost, OnTrigTeleTouchEnd_MapTriggers);
	}
}

public void OnAntiBhopTrigTouchStart_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	int touchCount = IncrementTriggerTouchCount(other, entity);
	if (touchCount <= 0)
	{
		// The trigger has fired a matching endtouch output before
		// the starttouch output, so ignore it.
		return;
	}
	
	if (jumpedThisTick[other])
	{
		TeleportEntity(other, jumpOrigin[other], NULL_VECTOR, jumpVelocity[other]);
	}
	
	AddTriggerToTouchList(other, entity, TriggerType_Antibhop);
}

public void OnAntiBhopTrigTouchEnd_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	DecrementTriggerTouchCount(other, entity);
	RemoveTriggerFromTouchList(other, entity);
}

public void OnTeleportTrigTouchStart_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	int touchCount = IncrementTriggerTouchCount(other, entity);
	if (touchCount <= 0)
	{
		// The trigger has fired a matching endtouch output before
		// the starttouch output, so ignore it.
		return;
	}
	
	char key[32];
	GetEntityHammerIDString(entity, key, sizeof(key));
	TeleportTrigger trigger;
	if (teleportTriggers.GetArray(key, trigger, sizeof(trigger))
		&& IsBhopTrigger(trigger.type))
	{
		bhopTouchCount[other]++;
	}
	
	AddTriggerToTouchList(other, entity, TriggerType_Teleport);
}

public void OnTeleportTrigTouchEnd_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	DecrementTriggerTouchCount(other, entity);
	
	char key[32];
	GetEntityHammerIDString(entity, key, sizeof(key));
	TeleportTrigger trigger;
	if (teleportTriggers.GetArray(key, trigger, sizeof(trigger))
		&& IsBhopTrigger(trigger.type))
	{
		bhopTouchCount[other]--;
	}
	
	RemoveTriggerFromTouchList(other, entity);
}

public void OnBhopResetTouchStart_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	ResetBhopState(other);
}

public void OnAntiCpTrigTouchStart_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	antiCpTriggerTouchCount[other]++;
}

public void OnAntiCpTrigTouchEnd_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	antiCpTriggerTouchCount[other]--;
}

public void OnAntiPauseTrigTouchStart_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	antiPauseTriggerTouchCount[other]++;
}

public void OnAntiPauseTrigTouchEnd_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	antiPauseTriggerTouchCount[other]--;
}

public void OnAntiJumpstatTrigTouchStart_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	antiJumpstatTriggerTouchCount[other]++;
}

public void OnAntiJumpstatTrigTouchEnd_MapTriggers(const char[] output, int entity, int other, float delay)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	antiJumpstatTriggerTouchCount[other]--;
}

public void OnTrigMultTouchStart_MapTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	lastTrigMultiTouchTime[other] = GetEngineTime();
	triggerTouchCount[other]++;
}

public void OnTrigMultTouchEnd_MapTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	triggerTouchCount[other]--;
}

public void OnTrigTeleTouchStart_MapTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	lastTrigTeleTouchTime[other] = GetEngineTime();
	triggerTouchCount[other]++;
}

public void OnTrigTeleTouchEnd_MapTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	triggerTouchCount[other]--;
}

void OnStartTouchGround_MapTriggers(int client)
{
	lastTouchGroundOrLadderTime[client] = GetEngineTime();
	
	for (int i = 0; i < triggerTouchList[client].Length; i++)
	{
		TouchedTrigger touched;
		triggerTouchList[client].GetArray(i, touched);
		// set the touched tick to the tick that the player touches the ground.
		touched.groundTouchTick = gI_TickCount[client];
		triggerTouchList[client].SetArray(i, touched);
	}
}

void OnStopTouchGround_MapTriggers(int client)
{
	for (int i = 0; i < triggerTouchList[client].Length; i++)
	{
		TouchedTrigger touched;
		triggerTouchList[client].GetArray(i, touched);
		
		if (touched.triggerType == TriggerType_Teleport)
		{
			char key[32];
			GetEntityHammerIDString(touched.entRef, key, sizeof(key));
			TeleportTrigger trigger;
			// set last touched triggers for single and sequential bhop.
			if (teleportTriggers.GetArray(key, trigger, sizeof(trigger))
				&& IsBhopTrigger(trigger.type))
			{
				if (trigger.type == TeleportType_SequentialBhop)
				{
					lastTouchSequentialBhopEntRefs[client].Push(touched.entRef);
				}
				// NOTE: For singlebhops, we don't care which type of bhop we last touched, because
				// otherwise jumping back and forth between a multibhop and a singlebhop wouldn't work.
				if (i == 0 && IsBhopTrigger(trigger.type))
				{
					// We only want to set this once in this loop.
					lastTouchSingleBhopEntRef[client] = touched.entRef;
				}
			}
		}
	}
}

void OnChangeMovetype_MapTriggers(int client, MoveType newMovetype)
{
	if (newMovetype == MOVETYPE_LADDER)
	{
		lastTouchGroundOrLadderTime[client] = GetEngineTime();
	}
}



// =====[ PRIVATE ]=====

static void AddTriggerToTouchList(int client, int trigger, TriggerType triggerType)
{
	int triggerEntRef = EntIndexToEntRef(trigger);
	
	TouchedTrigger touched;
	touched.triggerType = triggerType;
	touched.entRef = triggerEntRef;
	touched.startTouchTick = gI_TickCount[client];
	touched.groundTouchTick = -1;
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		touched.groundTouchTick = gI_TickCount[client];
	}
	
	triggerTouchList[client].PushArray(touched);
}

static void RemoveTriggerFromTouchList(int client, int trigger)
{
	int triggerEntRef = EntIndexToEntRef(trigger);
	for (int i = 0; i < triggerTouchList[client].Length; i++)
	{
		TouchedTrigger touched;
		triggerTouchList[client].GetArray(i, touched);
		if (touched.entRef == triggerEntRef)
		{
			triggerTouchList[client].Erase(i);
			break;
		}
	}
}

static int IncrementTriggerTouchCount(int client, int trigger)
{
	int entref = EntIndexToEntRef(trigger);
	char szEntref[64];
	FormatEx(szEntref, sizeof(szEntref), "%i", entref);
	
	int value = 0;
	triggerTouchCounts[client].GetValue(szEntref, value);
	
	value += 1;
	triggerTouchCounts[client].SetValue(szEntref, value);
	
	return value;
}

static void DecrementTriggerTouchCount(int client, int trigger)
{
	int entref = EntIndexToEntRef(trigger);
	char szEntref[64];
	FormatEx(szEntref, sizeof(szEntref), "%i", entref);
	
	int value = 0;
	triggerTouchCounts[client].GetValue(szEntref, value);
	
	value -= 1;
	triggerTouchCounts[client].SetValue(szEntref, value);
}

static void TouchAntibhopTrigger(int client, TouchedTrigger touched, int &newButtons, int flags)
{
	if (!(flags & FL_ONGROUND))
	{
		// Disable jump when the player is in the air.
		// This is a very simple way to fix jumpbugging antibhop triggers.
		newButtons &= ~IN_JUMP;
		return;
	}
	
	if (touched.groundTouchTick == -1)
	{
		// The player hasn't touched the ground inside this trigger yet.
		return;
	}
	
	char key[32];
	GetEntityHammerIDString(touched.entRef, key, sizeof(key));
	AntiBhopTrigger trigger;
	if (antiBhopTriggers.GetArray(key, trigger, sizeof(trigger)))
	{
		float touchTime = CalculateGroundTouchTime(client, touched);
		if (trigger.time == 0.0 || touchTime <= trigger.time)
		{
			// disable jump
			newButtons &= ~IN_JUMP;
		}
	}
}

static bool TouchTeleportTrigger(int client, TouchedTrigger touched, int flags)
{
	bool shouldTeleport = false;
	
	char key[32];
	GetEntityHammerIDString(touched.entRef, key, sizeof(key));
	TeleportTrigger trigger;
	if (!teleportTriggers.GetArray(key, trigger, sizeof(trigger)))
	{
		// Couldn't get the teleport trigger from the trigger array for some reason.
		return shouldTeleport;
	}
	
	bool isBhopTrigger = IsBhopTrigger(trigger.type);
	// NOTE: Player hasn't touched the ground inside this trigger yet.
	if (touched.groundTouchTick == -1 && isBhopTrigger)
	{
		return shouldTeleport;
	}
	
	float destOrigin[3];
	float destAngles[3];
	bool gotDestOrigin;
	bool gotDestAngles;
	int destinationEnt = GetTeleportDestinationAndOrientation(trigger.tpDestination, destOrigin, destAngles, gotDestOrigin, gotDestAngles);
	
	float triggerOrigin[3];
	bool gotTriggerOrigin = GetEntityAbsOrigin(touched.entRef, triggerOrigin);
	
	// NOTE: We only use the trigger's origin if we're using a relative destination, so if
	// we're not using a relative destination and don't have it, then it's fine.
	if (!IsValidEntity(destinationEnt) || !gotDestOrigin
		|| (!gotTriggerOrigin && trigger.relativeDestination))
	{
		PrintToConsole(client, "[KZ] Invalid teleport destination \"%s\" on trigger with hammerID %i.", trigger.tpDestination, trigger.hammerID);
		return shouldTeleport;
	}
	
	// NOTE: Find out if we should actually teleport.
	if (isBhopTrigger && (flags & FL_ONGROUND))
	{
		float touchTime = CalculateGroundTouchTime(client, touched);
		if (touchTime > trigger.delay)
		{
			shouldTeleport = true;
		}
		else if (trigger.type == TeleportType_SingleBhop)
		{
			shouldTeleport = lastTouchSingleBhopEntRef[client] == touched.entRef;
		}
		else if (trigger.type == TeleportType_SequentialBhop)
		{
			int length = lastTouchSequentialBhopEntRefs[client].Length;
			for (int j = 0; j < length; j++)
			{
				int entRef = lastTouchSequentialBhopEntRefs[client].Get(j);
				if (entRef == touched.entRef)
				{
					shouldTeleport = true;
					break;
				}
			}
		}
	}
	else if (trigger.type == TeleportType_Normal)
	{
		float touchTime = CalculateStartTouchTime(client, touched);
		shouldTeleport = touchTime > trigger.delay || (trigger.delay == 0.0);
	}
	
	if (!shouldTeleport)
	{
		return shouldTeleport;
	}
	
	bool shouldReorientPlayer = trigger.reorientPlayer
		&& gotDestAngles && (destAngles[1] != 0.0);
	
	float zAxis[3];
	zAxis = view_as<float>({0.0, 0.0, 1.0});
	
	// NOTE: Work out finalOrigin.
	float finalOrigin[3];
	if (trigger.relativeDestination)
	{
		float playerOrigin[3];
		Movement_GetOrigin(client, playerOrigin);
		
		float playerOffsetFromTrigger[3];
		SubtractVectors(playerOrigin, triggerOrigin, playerOffsetFromTrigger);
		
		if (shouldReorientPlayer)
		{
			// NOTE: rotate player offset by the destination trigger's yaw.
			RotateVectorAxis(playerOffsetFromTrigger, zAxis, DegToRad(destAngles[1]), playerOffsetFromTrigger);
		}
		
		AddVectors(destOrigin, playerOffsetFromTrigger, finalOrigin);
	}
	else
	{
		finalOrigin = destOrigin;
	}
	
	// NOTE: Work out finalPlayerAngles.
	float finalPlayerAngles[3];
	Movement_GetEyeAngles(client, finalPlayerAngles);
	if (shouldReorientPlayer)
	{
		finalPlayerAngles[1] -= destAngles[1];
		
		float velocity[3];
		Movement_GetVelocity(client, velocity);
		
		// NOTE: rotate velocity by the destination trigger's yaw.
		RotateVectorAxis(velocity, zAxis, DegToRad(destAngles[1]), velocity);
		Movement_SetVelocity(client, velocity);
	}
	else if (!trigger.reorientPlayer && trigger.useDestAngles)
	{
		finalPlayerAngles = destAngles;
	}
	
	if (shouldTeleport)
	{
		TeleportPlayer(client, finalOrigin, finalPlayerAngles, gotDestAngles && trigger.useDestAngles, trigger.resetSpeed);
	}
	
	return shouldTeleport;
}

static float CalculateGroundTouchTime(int client, TouchedTrigger touched)
{
	float result = float(gI_TickCount[client] - touched.groundTouchTick) * GetTickInterval();
	return result;
}

static float CalculateStartTouchTime(int client, TouchedTrigger touched)
{
	float result = float(gI_TickCount[client] - touched.startTouchTick) * GetTickInterval();
	return result;
}

static void ResetBhopState(int client)
{
	lastTouchSingleBhopEntRef[client] = INVALID_ENT_REFERENCE;
	lastTouchSequentialBhopEntRefs[client].Clear();
}

static bool GetEntityHammerIDString(int entity, char[] buffer, int maxLength)
{
	if (!IsValidEntity(entity))
	{
		return false;
	}
	
	if (!HasEntProp(entity, Prop_Data, "m_iHammerID"))
	{
		return false;
	}
	
	int hammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
	IntToString(hammerID, buffer, maxLength);
	
	return true;
}

// NOTE: returns an entity reference (possibly invalid).
static int GetTeleportDestinationAndOrientation(char[] targetName, float origin[3], float angles[3] = NULL_VECTOR, bool &gotOrigin = false, bool &gotAngles = false)
{
	// NOTE: We're not caching the teleport destination because it could change.
	int destination = GOKZFindEntityByName(targetName, .ignorePlayers = true);
	if (!IsValidEntity(destination))
	{
		return destination;
	}
	
	gotOrigin = GetEntityAbsOrigin(destination, origin);
	
	if (HasEntProp(destination, Prop_Data, "m_angAbsRotation"))
	{
		GetEntPropVector(destination, Prop_Data, "m_angAbsRotation", angles);
		gotAngles = true;
	}
	else
	{
		gotAngles = false;
	}
	
	return destination;
}