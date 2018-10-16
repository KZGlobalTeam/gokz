/*	
	Teleports
	
	Checkpoints and teleporting functionality.
*/



#define MAX_STORED_CHECKPOINTS 32
#define SOUND_CHECKPOINT "buttons/blip1.wav"
#define SOUND_TELEPORT "buttons/blip1.wav"

static int checkpointCount[MAXPLAYERS + 1]; // Absolute total number of checkpoints
static int storedCheckpointCount[MAXPLAYERS + 1]; // Current number of valid stored checkpoints
static int checkpointPrevCount[MAXPLAYERS + 1]; // Number of checkpoints back from latest checkpoint
static int checkpointIndex[MAXPLAYERS + 1];
static int teleportCount[MAXPLAYERS + 1];
static float startOrigin[MAXPLAYERS + 1][3];
static float startAngles[MAXPLAYERS + 1][3];
static bool hasCustomStartPosition[MAXPLAYERS + 1];
static float customStartOrigin[MAXPLAYERS + 1][3];
static float customStartAngles[MAXPLAYERS + 1][3];
static float checkpointOrigin[MAXPLAYERS + 1][MAX_STORED_CHECKPOINTS][3];
static float checkpointAngles[MAXPLAYERS + 1][MAX_STORED_CHECKPOINTS][3];
static bool checkpointOnLadder[MAXPLAYERS + 1][MAX_STORED_CHECKPOINTS];
static bool lastTeleportOnGround[MAXPLAYERS + 1];
static bool lastTeleportInBhopTrigger[MAXPLAYERS + 1];
static float undoOrigin[MAXPLAYERS + 1][3];
static float undoAngles[MAXPLAYERS + 1][3];



// =========================  PUBLIC  ========================= //

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

void SetupClientTeleports(int client)
{
	checkpointCount[client] = 0;
	storedCheckpointCount[client] = 0;
	checkpointPrevCount[client] = 0;
	teleportCount[client] = 0;
	hasCustomStartPosition[client] = false;
}


// CHECKPOINT

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
	storedCheckpointCount[client] = IntMin(storedCheckpointCount[client] + 1, MAX_STORED_CHECKPOINTS);
	checkpointPrevCount[client] = 0;
	checkpointIndex[client] = NextIndex(checkpointIndex[client], MAX_STORED_CHECKPOINTS);
	Movement_GetOrigin(client, checkpointOrigin[client][checkpointIndex[client]]);
	Movement_GetEyeAngles(client, checkpointAngles[client][checkpointIndex[client]]);
	checkpointOnLadder[client][checkpointIndex[client]] = Movement_GetMoveType(client) == MOVETYPE_LADDER;
	if (GetOption(client, Option_CheckpointSounds) == CheckpointSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_CHECKPOINT);
	}
	if (GetOption(client, Option_CheckpointMessages) == CheckpointMessages_Enabled)
	{
		GOKZ_PrintToChat(client, true, "%t", "Make Checkpoint");
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
	if (!Movement_GetOnGround(client) && Movement_GetMoveType(client) != MOVETYPE_LADDER)
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
	if (!IsPlayerAlive(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
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
	if (checkpointCount[client] == 0)
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
	
	storedCheckpointCount[client]--;
	checkpointPrevCount[client]++;
	checkpointIndex[client] = PrevIndex(checkpointIndex[client], MAX_STORED_CHECKPOINTS);
	CheckpointTeleportDo(client);
	
	// Call Post Forward
	Call_GOKZ_OnPrevCheckpoint_Post(client);
}

bool CanPrevCheckpoint(int client, bool showError = false)
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
	if (GetCurrentMapPrefix() == MapPrefix_KZPro && GetTimerRunning(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (Map)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (storedCheckpointCount[client] <= 1)
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
	
	storedCheckpointCount[client]++;
	checkpointPrevCount[client]--;
	checkpointIndex[client] = NextIndex(checkpointIndex[client], MAX_STORED_CHECKPOINTS);
	CheckpointTeleportDo(client);
	
	// Call Post Forward
	Call_GOKZ_OnNextCheckpoint_Post(client);
}

bool CanNextCheckpoint(int client, bool showError = false)
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
	if (GetCurrentMapPrefix() == MapPrefix_KZPro && GetTimerRunning(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (Map)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (checkpointPrevCount[client] == 0)
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

void TeleportToStart(int client)
{
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTeleportToStart(client, hasCustomStartPosition[client], result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// Teleport to Start
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		CS_SwitchTeam(client, CS_TEAM_CT);
	}
	
	if (hasCustomStartPosition[client])
	{
		if (!IsPlayerAlive(client))
		{
			CS_RespawnPlayer(client);
		}
		TeleportDo(client, customStartOrigin[client], customStartAngles[client]);
		GOKZ_StopTimer(client, false);
	}
	else if (GetHasStartedTimerThisMap(client))
	{
		if (!IsPlayerAlive(client))
		{
			CS_RespawnPlayer(client);
		}
		TeleportDo(client, startOrigin[client], startAngles[client]);
	}
	else
	{
		CS_RespawnPlayer(client);
	}
	
	// Call Post Forward
	Call_GOKZ_OnTeleportToStart_Post(client, hasCustomStartPosition[client]);
}

bool GetHasCustomStartPosition(int client)
{
	return hasCustomStartPosition[client];
}

void SetCustomStartPosition(int client)
{
	if (!IsPlayerAlive(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Must Be Alive");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	Movement_GetOrigin(client, customStartOrigin[client]);
	Movement_GetEyeAngles(client, customStartAngles[client]);
	hasCustomStartPosition[client] = true;
	GOKZ_PrintToChat(client, true, "%t", "Set Custom Start Position");
	if (GetOption(client, Option_CheckpointSounds) == CheckpointSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_CHECKPOINT);
	}
	UpdateTPMenu(client);
	Call_GOKZ_OnCustomStartPositionSet_Post(client, customStartOrigin[client], customStartAngles[client]);
}

void ClearCustomStartPosition(int client)
{
	hasCustomStartPosition[client] = false;
	GOKZ_PrintToChat(client, true, "%t", "Cleared Custom Start Position");
	UpdateTPMenu(client);
	Call_GOKZ_OnCustomStartPositionCleared_Post(client);
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
	TeleportDo(client, undoOrigin[client], undoAngles[client]);
	
	// Call Post Forward
	Call_GOKZ_OnUndoTeleport_Post(client);
}

bool CanUndoTeleport(int client, bool showError = false)
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
	if (teleportCount[client] <= 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (No Teleports)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (!lastTeleportOnGround[client])
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (TP Was Midair)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (lastTeleportInBhopTrigger[client])
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (Just Landed)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}


// GOTO

// Returns whether teleport to target was successful
bool GotoPlayer(int client, int target, bool printMessage = true)
{
	if (target == client)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Goto Failure (Not Yourself)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	if (!IsPlayerAlive(target))
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Goto Failure (Dead)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	
	float targetOrigin[3];
	float targetAngles[3];
	
	Movement_GetOrigin(target, targetOrigin);
	Movement_GetEyeAngles(target, targetAngles);
	
	// Leave spectators if necessary
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
	}
	// Respawn the player if necessary
	if (!IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client);
	}
	
	TeleportDo(client, targetOrigin, targetAngles);
	
	GOKZ_PrintToChat(client, true, "%t", "Goto Success", target);
	
	if (GetTimerRunning(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Time Stopped (Goto)");
		GOKZ_StopTimer(client);
	}
	
	return true;
}



// =========================  LISTENERS  ========================= //

void OnTimerStart_Teleports(int client)
{
	checkpointCount[client] = 0;
	storedCheckpointCount[client] = 0;
	checkpointPrevCount[client] = 0;
	teleportCount[client] = 0;
	Movement_GetOrigin(client, startOrigin[client]);
	Movement_GetEyeAngles(client, startAngles[client]);
}



// =========================  PRIVATE  ========================= //

static int NextIndex(int current, int maximum)
{
	int next = current + 1;
	if (next >= maximum)
	{
		return 0;
	}
	return next;
}

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
	// Store information about where player is teleporting from
	float oldOrigin[3];
	Movement_GetOrigin(client, oldOrigin);
	float oldAngles[3];
	Movement_GetEyeAngles(client, oldAngles);
	lastTeleportInBhopTrigger[client] = BhopTriggersJustTouched(client);
	lastTeleportOnGround[client] = Movement_GetOnGround(client);
	
	// Do Teleport
	teleportCount[client]++;
	Movement_SetOrigin(client, destOrigin);
	Movement_SetEyeAngles(client, destAngles);
	Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
	Movement_SetBaseVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
	Movement_SetGravity(client, 1.0);
	CreateTimer(0.1, Timer_RemoveBoosts, GetClientUserId(client)); // Prevent booster exploits
	
	// Duck the player if there is something blocking them from above
	Handle trace = TR_TraceHullFilterEx(destOrigin, 
		destOrigin, 
		view_as<float>( { -16.0, -16.0, 0.0 } ),  // Players are 32 x 32 x 72
		view_as<float>( { 16.0, 16.0, 72.0 } ), 
		MASK_PLAYERSOLID, 
		TraceEntityFilterPlayers, 
		client);
	if (TR_DidHit(trace))
	{
		SetEntPropFloat(client, Prop_Send, "m_flDuckAmount", 1.0, 0);
	}
	delete trace;
	
	undoOrigin[client] = oldOrigin;
	undoAngles[client] = oldAngles;
	
	if (GetOption(client, Option_TeleportSounds) == TeleportSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_TELEPORT);
	}
	
	// Call Post Foward
	Call_GOKZ_OnCountedTeleport_Post(client);
}

static void CheckpointTeleportDo(int client)
{
	TeleportDo(client, checkpointOrigin[client][checkpointIndex[client]], checkpointAngles[client][checkpointIndex[client]]);
	
	// Handle ladder stuff
	if (checkpointOnLadder[client][checkpointIndex[client]])
	{
		if (!GOKZ_GetPaused(client))
		{
			Movement_SetMoveType(client, MOVETYPE_LADDER);
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

public Action Timer_RemoveBoosts(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
		Movement_SetBaseVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
		Movement_SetGravity(client, 1.0);
	}
	return Plugin_Continue;
} 