/*
	Functions that affect the state of clients participating in a race.
	See the RacerStatus enum for possible states.
*/



static int racerStatus[MAXPLAYERS + 1];
static int racerRaceID[MAXPLAYERS + 1];
static float lastTimerStartTime[MAXPLAYERS + 1];
static float lastCheckpointTime[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

Action OnTimerStart_Racer(int client, int course)
{
	if (InCountdown(client)
		 || InStartedRace(client) && (!InRaceMode(client) || !IsRaceCourse(client, course)))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

Action OnTimerStart_Post_Racer(int client)
{
	lastTimerStartTime[client] = GetGameTime();
	return Plugin_Continue;
}

Action OnMakeCheckpoint_Racer(int client)
{
	if (GOKZ_GetTimerRunning(client) && InStartedRace(client))
	{
		int checkpointRule = GetRaceInfo(GetRaceID(client), RaceInfo_CheckpointRule);
		if (checkpointRule == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Checkpoints Not Allowed During Race");
			GOKZ_PlayErrorSound(client);
			return Plugin_Handled;
		}
		else if (checkpointRule != -1 && GOKZ_GetCheckpointCount(client) >= checkpointRule)
		{
			GOKZ_PrintToChat(client, true, "%t", "No Checkpoints Left");
			GOKZ_PlayErrorSound(client);
			return Plugin_Handled;
		}

		float cooldownRule = float(GetRaceInfo(GetRaceID(client), RaceInfo_CooldownRule));
		float timeSinceLastCheckpoint = FloatMin(
			GetGameTime() - lastTimerStartTime[client], 
			GetGameTime() - lastCheckpointTime[client]);
		if (timeSinceLastCheckpoint < cooldownRule)
		{
			GOKZ_PrintToChat(client, true, "%t", "Checkpoint On Cooldown", (cooldownRule - timeSinceLastCheckpoint));
			GOKZ_PlayErrorSound(client);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void OnMakeCheckpoint_Post_Racer(int client)
{
	lastCheckpointTime[client] = GetGameTime();
}

Action OnUndoTeleport_Racer(int client)
{
	if (GOKZ_GetTimerRunning(client)
		 && InStartedRace(client)
		 && GetRaceInfo(GetRaceID(client), RaceInfo_CheckpointRule) != -1)
	{
		GOKZ_PrintToChat(client, true, "%t", "Undo TP Not Allowed During Race");
		GOKZ_PlayErrorSound(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}



// =====[ GENERAL ]=====

int GetStatus(int client)
{
	return racerStatus[client];
}

int GetRaceID(int client)
{
	return racerRaceID[client];
}

bool InRace(int client)
{
	return GetStatus(client) != RacerStatus_Available;
}

bool InStartedRace(int client)
{
	return GetStatus(client) == RacerStatus_Racing;
}

bool InCountdown(int client)
{
	return GetRaceInfo(GetRaceID(client), RaceInfo_Status) == RaceStatus_Countdown;
}

bool InRaceMode(int client)
{
	return GOKZ_GetCoreOption(client, Option_Mode) == GetRaceInfo(GetRaceID(client), RaceInfo_Mode);
}

bool IsRaceCourse(int client, int course)
{
	return course == GetRaceInfo(GetRaceID(client), RaceInfo_Course);
}

bool IsFinished(int client)
{
	int status = GetStatus(client);
	return status == RacerStatus_Finished || status == RacerStatus_Surrendered;
}

bool IsAccepted(int client)
{
	return GetStatus(client) == RacerStatus_Accepted;
}

bool IsRaceHost(int client)
{
	return GetRaceHost(GetRaceID(client)) == client;
}

static void ResetRacer(int client)
{
	racerStatus[client] = RacerStatus_Available;
	racerRaceID[client] = -1;
	lastTimerStartTime[client] = 0.0;
	lastCheckpointTime[client] = 0.0;
}

static void ResetRacersInRace(int raceID)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (racerRaceID[client] == raceID)
		{
			ResetRacer(client);
		}
	}
}



// =====[ RACING ]=====

void StartRacer(int client)
{
	if (racerStatus[client] == RacerStatus_Pending)
	{
		DeclineRequest(client, true);
		return;
	}
	
	if (racerStatus[client] != RacerStatus_Accepted)
	{
		return;
	}
	
	racerStatus[client] = RacerStatus_Racing;
	
	// Prepare the racer
	GOKZ_StopTimer(client);
	GOKZ_SetCoreOption(client, Option_Mode, GetRaceInfo(racerRaceID[client], RaceInfo_Mode));
	
	int course = GetRaceInfo(racerRaceID[client], RaceInfo_Course);
	if (GOKZ_SetStartPositionToMapStart(client, course))
	{
		GOKZ_TeleportToStart(client);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "No Start Found", course);
	}
}

bool FinishRacer(int client, int course)
{
	if (racerStatus[client] != RacerStatus_Racing ||
		course != GetRaceInfo(racerRaceID[client], RaceInfo_Course))
	{
		return false;
	}
	
	racerStatus[client] = RacerStatus_Finished;
	
	int raceID = racerRaceID[client];
	int place = IncrementFinishedRacerCount(raceID);
	
	Call_OnFinish(client, raceID, place);
	
	CheckRaceFinished(raceID);
	
	return true;
}

bool SurrenderRacer(int client)
{
	if (racerStatus[client] == RacerStatus_Available
		 || racerStatus[client] == RacerStatus_Surrendered)
	{
		return false;
	}
	
	racerStatus[client] = RacerStatus_Surrendered;
	
	int raceID = racerRaceID[client];
	
	Call_OnSurrender(client, raceID);
	
	CheckRaceFinished(raceID);
	
	return true;
}

// Auto-finish last remaining racer, and reset everyone if no one is left
static void CheckRaceFinished(int raceID)
{
	ArrayList remainingRacers = GetUnfinishedRacers(raceID);
	if (remainingRacers.Length == 1)
	{
		int lastRacer = remainingRacers.Get(0);
		FinishRacer(lastRacer, GetRaceInfo(racerRaceID[lastRacer], RaceInfo_Course));
	}
	else if (remainingRacers.Length == 0)
	{
		ResetRacersInRace(raceID);
	}
	delete remainingRacers;
}

bool AbortRacer(int client)
{
	if (racerStatus[client] == RacerStatus_Available)
	{
		return false;
	}
	
	ResetRacer(client);
	
	return true;
}



// =====[ HOSTING ]=====

int HostRace(int client, int type, int course, int mode, int checkpointRule, int cooldownRule)
{
	if (InRace(client))
	{
		return -1;
	}
	
	int raceID = RegisterRace(client, type, course, mode, checkpointRule, cooldownRule);
	racerRaceID[client] = raceID;
	racerStatus[client] = RacerStatus_Accepted;
	
	return raceID;
}

bool StartHostedRace(int client)
{
	if (!InRace(client) || !IsRaceHost(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "You Are Not Hosting A Race");
		GOKZ_PlayErrorSound(client);
		return false;
	}
	
	int raceID = racerRaceID[client];
	
	if (GetRaceInfo(raceID, RaceInfo_Status) != RaceStatus_Pending)
	{
		GOKZ_PrintToChat(client, true, "%t", "Race Already Started");
		GOKZ_PlayErrorSound(client);
		return false;
	}
	
	if (GetAcceptedRacersCount(raceID) <= 1)
	{
		GOKZ_PrintToChat(client, true, "%t", "No One Accepted");
		GOKZ_PlayErrorSound(client);
		return false;
	}
	
	return StartRace(raceID);
}

bool AbortHostedRace(int client)
{
	if (!InRace(client) || !IsRaceHost(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "You Are Not Hosting A Race");
		GOKZ_PlayErrorSound(client);
		return false;
	}
	
	int raceID = racerRaceID[client];
	
	return AbortRace(raceID);
}



// =====[ REQUESTS ]=====

bool SendRequest(int host, int target)
{
	if (IsFakeClient(target) || target == host || InRace(target)
		 || !IsRaceHost(host) || GetRaceInfo(racerRaceID[host], RaceInfo_Status) != RaceStatus_Pending)
	{
		return false;
	}
	
	int raceID = racerRaceID[host];
	
	racerRaceID[target] = raceID;
	racerStatus[target] = RacerStatus_Pending;
	
	// Host callback
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(host));
	data.WriteCell(GetClientUserId(target));
	data.WriteCell(raceID);
	CreateTimer(RC_REQUEST_TIMEOUT_TIME, Timer_RequestTimeout, data);
	
	Call_OnRequestReceived(target, raceID);
	
	return true;
}

public Action Timer_RequestTimeout(Handle timer, DataPack data)
{
	data.Reset();
	int host = GetClientOfUserId(data.ReadCell());
	int target = GetClientOfUserId(data.ReadCell());
	int raceID = data.ReadCell();
	delete data;
	
	if (!IsValidClient(host) || racerRaceID[host] != raceID
		 || !IsValidClient(target) || racerRaceID[target] != raceID)
	{
		return Plugin_Continue;
	}
	
	// If haven't accepted by now, auto decline the race
	if (racerStatus[target] == RacerStatus_Pending)
	{
		DeclineRequest(target, true);
	}
	return Plugin_Continue;
}

int SendRequestAll(int host)
{
	int sentCount = 0;
	for (int target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target) && SendRequest(host, target))
		{
			sentCount++;
		}
	}
	return sentCount;
}

bool AcceptRequest(int client)
{
	if (GetStatus(client) != RacerStatus_Pending)
	{
		return false;
	}
	
	racerStatus[client] = RacerStatus_Accepted;
	
	Call_OnRequestAccepted(client, racerRaceID[client]);
	
	return true;
}

bool DeclineRequest(int client, bool timeout = false)
{
	if (GetStatus(client) != RacerStatus_Pending)
	{
		return false;
	}
	
	int raceID = racerRaceID[client];
	ResetRacer(client);
	
	Call_OnRequestDeclined(client, raceID, timeout);
	
	return true;
}



// =====[ EVENTS ]=====

void OnClientPutInServer_Racer(int client)
{
	ResetRacer(client);
}

void OnClientDisconnect_Racer(int client)
{
	// Abort if player was the host of the race, else surrender
	if (InRace(client))
	{
		if (IsRaceHost(client) && GetRaceInfo(racerRaceID[client], RaceInfo_Status) == RaceStatus_Pending)
		{
			AbortRace(racerRaceID[client]);
		}
		else
		{
			SurrenderRacer(client);
		}
	}
	
	ResetRacer(client);
} 