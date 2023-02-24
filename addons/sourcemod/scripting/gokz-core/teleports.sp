/*
	Checkpoints and teleporting, including ability to go back
	to previous checkpoint, go to next checkpoint, and undo.
*/


static ArrayList checkpoints[MAXPLAYERS + 1];
static int checkpointCount[MAXPLAYERS + 1];
static int checkpointIndex[MAXPLAYERS + 1];
static int checkpointIndexStart[MAXPLAYERS + 1];
static int checkpointIndexEnd[MAXPLAYERS + 1];
static int teleportCount[MAXPLAYERS + 1];
static StartPositionType startType[MAXPLAYERS + 1];
static StartPositionType nonCustomStartType[MAXPLAYERS + 1];
static float nonCustomStartOrigin[MAXPLAYERS + 1][3];
static float nonCustomStartAngles[MAXPLAYERS + 1][3];
static float customStartOrigin[MAXPLAYERS + 1][3];
static float customStartAngles[MAXPLAYERS + 1][3];
static float endOrigin[MAXPLAYERS + 1][3];
static float endAngles[MAXPLAYERS + 1][3];
static UndoTeleportData undoTeleportData[MAXPLAYERS + 1];
static float lastRestartAttemptTime[MAXPLAYERS + 1];

// =====[ PUBLIC ]=====

int GetCheckpointCount(int client)
{
	return checkpointCount[client];
}

void SetCheckpointCount(int client, int cpCount)
{
	checkpointCount[client] = cpCount;
}

int GetTeleportCount(int client)
{
	return teleportCount[client];
}

void SetTeleportCount(int client, int tpCount)
{
	teleportCount[client] = tpCount;
}

// CHECKPOINT

void OnMapStart_Checkpoints()
{
	for (int client = 0; client < MAXPLAYERS + 1; client++)
	{
		if (checkpoints[client] != INVALID_HANDLE)
		{
			delete checkpoints[client];
		}
		checkpoints[client] = new ArrayList(sizeof(Checkpoint));
	}
}

void MakeCheckpoint(int client)
{
	if (!CanMakeCheckpoint(client, true))
	{
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnMakeCheckpoint(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// Make Checkpoint
	checkpointCount[client]++;
	Checkpoint cp;
	cp.Create(client);

	if (checkpoints[client] == INVALID_HANDLE)
	{
		checkpoints[client] = new ArrayList(sizeof(Checkpoint));
	}

	checkpointIndex[client] = NextIndex(checkpointIndex[client], GOKZ_MAX_CHECKPOINTS);
	checkpointIndexEnd[client] = checkpointIndex[client];
	// The list has yet to be filled up, do PushArray instead of SetArray
	if (checkpoints[client].Length < GOKZ_MAX_CHECKPOINTS && checkpointIndex[client] == checkpoints[client].Length)
	{
		checkpoints[client].PushArray(cp);
		// Initialize start and end index for the first checkpoint
		if (checkpoints[client].Length == 1)
		{
			checkpointIndexStart[client] = 0;
			checkpointIndexEnd[client] = 0;
		}
	}
	else
	{
		checkpoints[client].SetArray(checkpointIndex[client], cp);
		// The new checkpoint has overridden the oldest checkpoint, move the start index by one.
		if (checkpointIndexEnd[client] == checkpointIndexStart[client])
		{
			checkpointIndexStart[client] = NextIndex(checkpointIndexStart[client], GOKZ_MAX_CHECKPOINTS);
		}
	}

	
	if (GOKZ_GetCoreOption(client, Option_CheckpointSounds) == CheckpointSounds_Enabled)
	{
		GOKZ_EmitSoundToClient(client, GOKZ_SOUND_CHECKPOINT, _, "Checkpoint");
	}
	if (GOKZ_GetCoreOption(client, Option_CheckpointMessages) == CheckpointMessages_Enabled)
	{
		GOKZ_PrintToChat(client, true, "%t", "Make Checkpoint", checkpointCount[client]);
	}

	if (!GetTimerRunning(client) && AntiCpTriggerIsTouched(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Anti Checkpoint Area Warning");
	}

	// Call Post Forward
	Call_GOKZ_OnMakeCheckpoint_Post(client);
}

bool CanMakeCheckpoint(int client, bool showError = false)
{
	if (!IsPlayerAlive(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (GetTimerRunning(client) && AntiCpTriggerIsTouched(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Checkpoint (Anti Checkpoint Area)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (!Movement_GetOnGround(client) && Movement_GetMovetype(client) != MOVETYPE_LADDER)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Checkpoint (Midair)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (BhopTriggersJustTouched(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Checkpoint (Just Landed)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}

ArrayList GetCheckpointData(int client)
{
	// Don't clone the entire thing, return an ordered list of checkpoints.
	// Doing this should be cleaner, saves memory and should be faster than a full Clone().
	ArrayList checkpointData = new ArrayList(sizeof(Checkpoint));
	if (checkpointIndex[client] == -1)
	{
		// No checkpoint was made, return empty ArrayList
		return checkpointData;
	}
	for (int i = checkpointIndexStart[client]; i != checkpointIndexEnd[client]; i = NextIndex(i, GOKZ_MAX_CHECKPOINTS))
	{
		Checkpoint cp;
		checkpoints[client].GetArray(i, cp);
		checkpointData.PushArray(cp);
	}
	return checkpointData;
}

bool SetCheckpointData(int client, ArrayList cps, int version)
{
	if (version != GOKZ_CHECKPOINT_VERSION)
	{
		return false;
	}
	// cps is assumed to be ordered.
	if (cps != INVALID_HANDLE)
	{
		delete checkpoints[client];
		checkpoints[client] = cps.Clone();
		if (cps.Length == 0)
		{
			checkpointIndexStart[client] = -1;
			checkpointIndexEnd[client] = -1;
		}
		else
		{
			checkpointIndexStart[client] = 0;
			checkpointIndexEnd[client] = checkpoints[client].Length - 1;
		}
		checkpointIndex[client] = checkpointIndexEnd[client];
		return true;
	}
	return false;
}

ArrayList GetUndoTeleportData(int client)
{
	// Enum structs cannot be sent directly over natives, we put it in an ArrayList of one instead.
	// We use another struct instead of reusing Checkpoint so normal checkpoints don't use more memory than needed.
	ArrayList undoTeleportDataArray = new ArrayList(sizeof(UndoTeleportData));
	undoTeleportDataArray.PushArray(undoTeleportData[client]);
	return undoTeleportDataArray;
}

bool SetUndoTeleportData(int client, ArrayList undoTeleportDataArray, int version)
{
	if (version != GOKZ_CHECKPOINT_VERSION)
	{
		return false;
	}
	if (undoTeleportDataArray != INVALID_HANDLE && undoTeleportDataArray.Length == 1)
	{
		undoTeleportDataArray.GetArray(0, undoTeleportData[client], sizeof(UndoTeleportData));
		return true;
	}
	return false;
}
// TELEPORT

void TeleportToCheckpoint(int client)
{
	if (!CanTeleportToCheckpoint(client, true))
	{
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTeleportToCheckpoint(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	CheckpointTeleportDo(client);
	
	// Call Post Forward
	Call_GOKZ_OnTeleportToCheckpoint_Post(client);
}

bool CanTeleportToCheckpoint(int client, bool showError = false)
{
	// Safeguard Check
	if (GOKZ_GetCoreOption(client, Option_Safeguard) == Safeguard_EnabledPRO && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client) && GOKZ_GetTeleportCount(client) == 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (GetCurrentMapPrefix() == MapPrefix_KZPro && GetTimerRunning(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (Map)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (checkpoints[client] == INVALID_HANDLE || checkpoints[client].Length <= 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (No Checkpoints)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}


// PREV CP

void PrevCheckpoint(int client)
{
	if (!CanPrevCheckpoint(client, true))
	{
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnPrevCheckpoint(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}

	checkpointIndex[client] = PrevIndex(checkpointIndex[client], GOKZ_MAX_CHECKPOINTS);
	CheckpointTeleportDo(client);
	
	// Call Post Forward
	Call_GOKZ_OnPrevCheckpoint_Post(client);
}

bool CanPrevCheckpoint(int client, bool showError = false)
{
	// Safeguard Check
	if (GOKZ_GetCoreOption(client, Option_Safeguard) == Safeguard_EnabledPRO && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (GetCurrentMapPrefix() == MapPrefix_KZPro && GetTimerRunning(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (Map)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (checkpointIndex[client] == checkpointIndexStart[client])
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Prev CP (No Checkpoints)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}


// NEXT CP

void NextCheckpoint(int client)
{
	if (!CanNextCheckpoint(client, true))
	{
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnNextCheckpoint(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	checkpointIndex[client] = NextIndex(checkpointIndex[client], GOKZ_MAX_CHECKPOINTS);
	CheckpointTeleportDo(client);
	
	// Call Post Forward
	Call_GOKZ_OnNextCheckpoint_Post(client);
}

bool CanNextCheckpoint(int client, bool showError = false)
{
	if (GetCurrentMapPrefix() == MapPrefix_KZPro && GetTimerRunning(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (Map)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (checkpointIndex[client] == checkpointIndexEnd[client])
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Next CP (No Checkpoints)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}


// RESTART & RESPAWN

bool CanTeleportToStart(int client, bool showError = false)
{
	// Safeguard Check
	if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		float currentTime = GetEngineTime();
		float timeSinceLastAttempt = currentTime - lastRestartAttemptTime[client];
		float cooldown;
		// If the client restarts for the first time or the last attempt is too long ago, restart the cooldown.
		if (lastRestartAttemptTime[client] == 0.0 || timeSinceLastAttempt > GOKZ_SAFEGUARD_RESTART_MAX_DELAY)
		{
			lastRestartAttemptTime[client] = currentTime;
			cooldown = GOKZ_SAFEGUARD_RESTART_MIN_DELAY;
		}
		else
		{
			cooldown = GOKZ_SAFEGUARD_RESTART_MIN_DELAY - timeSinceLastAttempt;
		}
		if (cooldown <= 0.0)
		{
			lastRestartAttemptTime[client] = 0.0;
			return true;
		}
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked (Temp)", cooldown);
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}

void TeleportToStart(int client)
{
	if (!CanTeleportToStart(client, true))
	{
		return;
	}

	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTeleportToStart(client, GetCurrentCourse(client), result);
	if (result != Plugin_Continue)
	{
		return;
	}

	// Teleport to Start
	if (startType[client] == StartPositionType_Spawn)
	{
		GOKZ_RespawnPlayer(client, .restorePos = false);
		// Respawning alone does not guarantee a valid spawn.
		float spawnOrigin[3];
		float spawnAngles[3];
		GetValidSpawn(spawnOrigin, spawnAngles);
		TeleportPlayer(client, spawnOrigin, spawnAngles);
	}
	else if (startType[client] == StartPositionType_Custom)
	{
		TeleportDo(client, customStartOrigin[client], customStartAngles[client]);
	}
	else
	{
		TeleportDo(client, nonCustomStartOrigin[client], nonCustomStartAngles[client]);
	}
	
	if (startType[client] != StartPositionType_MapButton
		&& (!InRangeOfVirtualStart(client) || !CanReachVirtualStart(client)))
	{
		GOKZ_StopTimer(client, false);
	}
	
	// Call Post Forward
	Call_GOKZ_OnTeleportToStart_Post(client, GetCurrentCourse(client));
}

void TeleportToSearchStart(int client, int course)
{
	if (!CanTeleportToStart(client, true))
	{
		return;
	}

	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTeleportToStart(client, course, result);
	if (result != Plugin_Continue)
	{
		return;
	}

	float origin[3], angles[3];
	if (!GetSearchStartPosition(course, origin, angles))
	{
		if (course == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "No Start Found");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "No Start Found (Bonus)", course);
		}
		return;
	}
	GOKZ_StopTimer(client, false);

	TeleportDo(client, origin, angles);
	// Call Post Forward
	Call_GOKZ_OnTeleportToStart_Post(client, course);
}

StartPositionType GetStartPosition(int client, float position[3], float angles[3])
{
	if (startType[client] == StartPositionType_Custom)
	{
		position = customStartOrigin[client];
		angles = customStartAngles[client];
	}
	else if (startType[client] != StartPositionType_Spawn)
	{
		position = nonCustomStartOrigin[client];
		angles = nonCustomStartAngles[client];
	}
	
	return startType[client];
}

bool TeleportToCourseStart(int client, int course)
{
	if (!CanTeleportToStart(client, true))
	{
		return false;
	}

	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTeleportToStart(client, course, result);
	if (result != Plugin_Continue)
	{
		return false;
	}
	float origin[3], angles[3];
	
	if (!GetMapStartPosition(course, origin, angles))
	{
		if (!GetSearchStartPosition(course, origin, angles))
		{
			if (course == 0)
			{
				GOKZ_PrintToChat(client, true, "%t", "No Start Found");
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%t", "No Start Found (Bonus)", course);
			}
			return false;
		}
	}

	GOKZ_StopTimer(client);
	
	TeleportDo(client, origin, angles);
	
	// Call Post Forward
	Call_GOKZ_OnTeleportToStart_Post(client, course);	
	return true;
}

StartPositionType GetStartPositionType(int client)
{
	return startType[client];
}

// Note: Use ClearStartPosition to switch off StartPositionType_Custom
void SetStartPosition(int client, StartPositionType type, const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR)
{
	if (type == StartPositionType_Custom)
	{
		startType[client] = StartPositionType_Custom;
		
		if (!IsNullVector(origin))
		{
			customStartOrigin[client] = origin;
		}
		
		if (!IsNullVector(angles))
		{
			customStartAngles[client] = angles;
		}
		
		// Call Post Forward
		Call_GOKZ_OnStartPositionSet_Post(client, startType[client], customStartOrigin[client], customStartAngles[client]);
	}
	else
	{
		nonCustomStartType[client] = type;
		
		if (!IsNullVector(origin))
		{
			nonCustomStartOrigin[client] = origin;
		}
		
		if (!IsNullVector(angles))
		{
			nonCustomStartAngles[client] = angles;
		}
		
		if (startType[client] != StartPositionType_Custom)
		{
			startType[client] = type;
			
			// Call Post Forward
			Call_GOKZ_OnStartPositionSet_Post(client, startType[client], nonCustomStartOrigin[client], nonCustomStartAngles[client]);
		}
	}
}

void SetStartPositionToCurrent(int client, StartPositionType type)
{
	float origin[3], angles[3];
	Movement_GetOrigin(client, origin);
	Movement_GetEyeAngles(client, angles);
	
	SetStartPosition(client, type, origin, angles);
}

bool SetStartPositionToMapStart(int client, int course)
{
	float origin[3], angles[3];
	
	if (!GetMapStartPosition(course, origin, angles))
	{
		return false;
	}
	
	SetStartPosition(client, StartPositionType_MapStart, origin, angles);
	
	return true;
}

bool ClearCustomStartPosition(int client)
{
	if (GetStartPositionType(client) != StartPositionType_Custom)
	{
		return false;
	}
	
	startType[client] = nonCustomStartType[client];
	
	// Call Post Forward
	Call_GOKZ_OnStartPositionSet_Post(client, startType[client], nonCustomStartOrigin[client], nonCustomStartAngles[client]);
	
	return true;
}


// TELEPORT TO END

bool CanTeleportToEnd(int client, bool showError = false)
{
	// Safeguard Check
	if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}

void TeleportToEnd(int client, int course)
{
	if (!CanTeleportToEnd(client, true))
	{
		return;
	}

	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTeleportToEnd(client, course, result);
	if (result != Plugin_Continue)
	{
		return;
	}

	GOKZ_StopTimer(client, false);

	if (!GetMapEndPosition(course, endOrigin[client], endAngles[client]))
	{
		if (course == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "No End Found");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "No End Found (Bonus)", course);
		}
		return;
	}
	TeleportDo(client, endOrigin[client], endAngles[client]);

	// Call Post Forward
	Call_GOKZ_OnTeleportToEnd_Post(client, course);
}

void SetEndPosition(int client, const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR)
{
	if (!IsNullVector(origin))
	{
		endOrigin[client] = origin;
	}
	if (!IsNullVector(angles))
	{
		endAngles[client] = angles;
	}
}

bool SetEndPositionToMapEnd(int client, int course)
{
	float origin[3], angles[3];

	if (!GetMapEndPosition(course, origin, angles))
	{
		return false;
	}

	SetEndPosition(client, origin, angles);

	return true;
}


// UNDO TP

void UndoTeleport(int client)
{
	if (!CanUndoTeleport(client, true))
	{
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnUndoTeleport(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// Undo Teleport
	TeleportDo(client, undoTeleportData[client].origin, undoTeleportData[client].angles);
	
	// Call Post Forward
	Call_GOKZ_OnUndoTeleport_Post(client);
}

bool CanUndoTeleport(int client, bool showError = false)
{
	if (teleportCount[client] <= 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (No Teleports)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (!undoTeleportData[client].lastTeleportOnGround)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (TP Was Midair)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (undoTeleportData[client].lastTeleportInBhopTrigger)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (Just Landed)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (undoTeleportData[client].lastTeleportInAntiCpTrigger)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (AntiCp)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}



// =====[ EVENTS ]=====

void OnClientPutInServer_Teleports(int client)
{
	checkpointCount[client] = 0;
	checkpointIndex[client] = -1;
	checkpointIndexStart[client] = -1;
	checkpointIndexEnd[client] = -1;
	teleportCount[client] = 0;
	startType[client] = StartPositionType_Spawn;
	nonCustomStartType[client] = StartPositionType_Spawn;
	lastRestartAttemptTime[client] = 0.0;
	if (checkpoints[client] != INVALID_HANDLE)
	{
		checkpoints[client].Clear();
	}
	// Set start and end position to main course if we know of it
	SetStartPositionToMapStart(client, 0);
	SetEndPositionToMapEnd(client, 0);

}

void OnTimerStart_Teleports(int client)
{
	checkpointCount[client] = 0;
	checkpointIndex[client] = -1;
	checkpointIndexStart[client] = -1;
	checkpointIndexEnd[client] = -1;
	teleportCount[client] = 0;
	checkpoints[client].Clear();
}

void OnStartButtonPress_Teleports(int client, int course)
{
	SetStartPositionToCurrent(client, StartPositionType_MapButton);
	SetEndPositionToMapEnd(client, course);
}

void OnVirtualStartButtonPress_Teleports(int client)
{
	SetStartPositionToCurrent(client, StartPositionType_MapButton);
}

void OnStartZoneStartTouch_Teleports(int client, int course)
{
	SetStartPositionToMapStart(client, course);
	SetEndPositionToMapEnd(client, course);
}



// =====[ PRIVATE ]=====

static int PrevIndex(int current, int maximum)
{
	int prev = current - 1;
	if (prev < 0)
	{
		return maximum - 1;
	}
	return prev;
}

static void TeleportDo(int client, const float destOrigin[3], const float destAngles[3])
{
	if (!IsPlayerAlive(client))
	{
		GOKZ_RespawnPlayer(client);
	}
	
	// Store information about where player is teleporting from
	undoTeleportData[client].Init(client, BhopTriggersJustTouched(client), Movement_GetOnGround(client), AntiCpTriggerIsTouched(client));
	
	teleportCount[client]++;
	TeleportPlayer(client, destOrigin, destAngles);
	// TeleportPlayer needs to be done before undo TP data can be fully updated.
	undoTeleportData[client].Update();
	if (GOKZ_GetCoreOption(client, Option_TeleportSounds) == TeleportSounds_Enabled)
	{
		GOKZ_EmitSoundToClient(client, GOKZ_SOUND_TELEPORT, _, "Teleport");
	}
	
	// Call Post Foward
	Call_GOKZ_OnCountedTeleport_Post(client);
}

static void CheckpointTeleportDo(int client)
{
	Checkpoint cp;
	checkpoints[client].GetArray(checkpointIndex[client], cp);
	
	TeleportDo(client, cp.origin, cp.angles);
	if (cp.groundEnt != INVALID_ENT_REFERENCE)
	{
		SetEntPropEnt(client, Prop_Data, "m_hGroundEntity", cp.groundEnt);
		SetEntityFlags(client, GetEntityFlags(client) | FL_ONGROUND);
	}
	// Handle ladder stuff
	if (cp.onLadder)
	{
		SetEntPropVector(client, Prop_Send, "m_vecLadderNormal", cp.ladderNormal);
		if (!GOKZ_GetPaused(client))
		{
			Movement_SetMovetype(client, MOVETYPE_LADDER);
		}
		else
		{
			SetPausedOnLadder(client, true);
		}
	}
	else if (GOKZ_GetPaused(client))
	{
		SetPausedOnLadder(client, false);
	}
} 
