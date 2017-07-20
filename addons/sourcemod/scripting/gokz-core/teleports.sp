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
static bool lastTeleportOnGround[MAXPLAYERS + 1];
static bool lastTeleportInBhopTrigger[MAXPLAYERS + 1];
static float undoOrigin[MAXPLAYERS + 1][3];
static float undoAngles[MAXPLAYERS + 1][3];



// =========================  PUBLIC  ========================= //

int GetCheckpointCount(int client)
{
	return checkpointCount[client];
}

int GetTeleportCount(int client)
{
	return teleportCount[client];
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
	if (GetOption(client, Option_CheckpointSounds) == CheckpointSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_TELEPORT);
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
			PlayErrorSound(client);
		}
		return false;
	}
	if (!Movement_GetOnGround(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Checkpoint (Midair)");
			PlayErrorSound(client);
		}
		return false;
	}
	if (BhopTriggersJustTouched(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Checkpoint (Just Landed)");
			PlayErrorSound(client);
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
	
	// Teleport to Checkpoint
	TeleportDo(client, checkpointOrigin[client][checkpointIndex[client]], checkpointAngles[client][checkpointIndex[client]]);
	
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
			PlayErrorSound(client);
		}
		return false;
	}
	if (checkpointCount[client] == 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (No Checkpoints)");
			PlayErrorSound(client);
		}
		return false;
	}
	if (GetCurrentMapPrefix() == MapPrefix_KZPro && GetTimerRunning(client))
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Teleport (Map)");
			PlayErrorSound(client);
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
	TeleportDo(client, checkpointOrigin[client][checkpointIndex[client]], checkpointAngles[client][checkpointIndex[client]]);
	
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
			PlayErrorSound(client);
		}
		return false;
	}
	if (storedCheckpointCount[client] <= 1)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Prev CP (No Checkpoints)");
			PlayErrorSound(client);
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
	TeleportDo(client, checkpointOrigin[client][checkpointIndex[client]], checkpointAngles[client][checkpointIndex[client]]);
	
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
			PlayErrorSound(client);
		}
		return false;
	}
	if (checkpointPrevCount[client] == 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Next CP (No Checkpoints)");
			PlayErrorSound(client);
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
		PlayErrorSound(client);
		return;
	}
	
	Movement_GetOrigin(client, customStartOrigin[client]);
	Movement_GetEyeAngles(client, customStartAngles[client]);
	hasCustomStartPosition[client] = true;
	GOKZ_PrintToChat(client, true, "%t", "Set Custom Start Position");
	UpdateTPMenu(client);
}

void ClearCustomStartPosition(int client)
{
	hasCustomStartPosition[client] = false;
	GOKZ_PrintToChat(client, true, "%t", "Cleared Custom Start Position");
	UpdateTPMenu(client);
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
			PlayErrorSound(client);
		}
		return false;
	}
	if (teleportCount[client] <= 0)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (No Teleports)");
			PlayErrorSound(client);
		}
		return false;
	}
	if (!lastTeleportOnGround[client])
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (TP Was Midair)");
			PlayErrorSound(client);
		}
		return false;
	}
	if (lastTeleportInBhopTrigger[client])
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Undo (Just Landed)");
			PlayErrorSound(client);
		}
		return false;
	}
	return true;
}


// GOTO

void GotoPlayer(int client, int target)
{
	if (!IsPlayerAlive(target) || client == target)
	{
		return;
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
	
	undoOrigin[client] = oldOrigin;
	undoAngles[client] = oldAngles;
	
	if (GetOption(client, Option_TeleportSounds) == TeleportSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_TELEPORT);
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