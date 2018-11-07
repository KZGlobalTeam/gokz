/*
	Functions that affect the state of clients participating in a race.
	See the RacerStatus enum for possible states.
*/



static int status[MAXPLAYERS + 1];
static int currentRaceID[MAXPLAYERS + 1];



// =====[ GENERAL ]=====

int GetRacerStatus(int client)
{
	return status[client];
}

int GetRaceID(int client)
{
	return currentRaceID[client];
}

static void ResetRacer(int client)
{
	status[client] = RacerStatus_Available;
	currentRaceID[client] = -1;
}



// =====[ RACING ]=====

void StartRacer(int client)
{
	if (!InRace(client))
	{
		return;
	}
	
	if (status[client] == RacerStatus_Pending)
	{
		ResetRacer(client);
		return;
	}
	
	status[client] = RacerStatus_Racing;
	
	// Prepare the racer
	GOKZ_StopTimer(client);
	GOKZ_SetCoreOption(client, Option_Mode, GetRaceInfo(GetRaceID(client), RaceInfo_Mode));
	GOKZ_TeleportToStart(client);
}

bool FinishRacer(int client)
{
	if (!InStartedRace(client))
	{
		return false;
	}
	
	status[client] = RacerStatus_Finished;
	
	int raceID = GetRaceID(client);
	int place = IncrementFinishedRacerCount(raceID);
	
	Call_OnFinish(client, raceID, place);
	
	ResetRacer(client);
	TryFinishLastRemainingRacer(raceID);
	
	return true;
}

bool SurrenderRacer(int client)
{
	if (!InRace(client))
	{
		return false;
	}
	
	status[client] = RacerStatus_Surrendered;
	
	int raceID = GetRaceID(client);
	
	Call_OnSurrender(client, raceID);
	
	ResetRacer(client);
	TryFinishLastRemainingRacer(raceID);
	
	return true;
}

static void TryFinishLastRemainingRacer(int raceID)
{
	ArrayList remainingRacers = GetUnfinishedRacers(raceID);
	if (remainingRacers.Length == 1)
	{
		int lastRacer = remainingRacers.Get(0);
		FinishRacer(lastRacer);
	}
	delete remainingRacers;
}

bool AbortRacer(int client)
{
	if (!InRace(client))
	{
		return false;
	}
	
	if (IsClientInGame(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Race Has Been Aborted");
		if (status[client] == RacerStatus_Racing)
		{
			GOKZ_PlayErrorSound(client);
		}
	}
	ResetRacer(client);
	
	return true;
}



// =====[ HOSTING ]=====

int HostRace(int client, int type, int course, int mode, int teleportsRule)
{
	if (InRace(client))
	{
		return -1;
	}
	
	int raceID = RegisterRace(client, type, course, mode, teleportsRule);
	currentRaceID[client] = raceID;
	status[client] = RacerStatus_Accepted;
	
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
	
	int raceID = GetRaceID(client);
	
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
	
	if (StartRace(raceID))
	{
		if (GetRaceInfo(raceID, RaceInfo_Type) == RaceType_Normal)
		{
			GOKZ_PrintToChatAll(true, "%t", "Race Started", client);
		}
		return true;
	}
	else
	{
		return false;
	}
}

bool AbortHostedRace(int client)
{
	if (!InRace(client) || !IsRaceHost(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "You Are Not Hosting A Race");
		GOKZ_PlayErrorSound(client);
		return false;
	}
	
	int raceID = GetRaceID(client);
	
	return AbortRace(raceID);
}



// =====[ REQUESTS ]=====

bool SendRequest(int host, int target)
{
	if (IsFakeClient(target) || target == host || InRace(target)
		 || !IsRaceHost(host) || GetRaceInfo(GetRaceID(host), RaceInfo_Status) != RaceStatus_Pending)
	{
		return false;
	}
	
	int raceID = GetRaceID(host);
	
	currentRaceID[target] = raceID;
	status[target] = RacerStatus_Pending;
	
	// Host callback
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(host));
	data.WriteCell(GetClientUserId(target));
	data.WriteCell(raceID);
	CreateTimer(float(RC_REQUEST_TIMEOUT_TIME), Timer_RequestTimeout, data);
	
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
	
	if (!IsValidClient(host) || GetRaceID(host) != raceID
		 || !IsValidClient(target) || GetRaceID(target) != raceID)
	{
		return;
	}
	
	// If haven't accepted by now, auto decline the race
	if (status[target] == RacerStatus_Pending)
	{
		DeclineRequest(target, true);
	}
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
	if (GetRacerStatus(client) != RacerStatus_Pending)
	{
		return false;
	}
	
	status[client] = RacerStatus_Accepted;
	
	Call_OnRequestAccepted(client, GetRaceID(client));
	
	return true;
}

bool DeclineRequest(int client, bool timeout = false)
{
	if (GetRacerStatus(client) != RacerStatus_Pending)
	{
		return false;
	}
	
	int raceID = GetRaceID(client);
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
		if (IsRaceHost(client) && GetRaceInfo(GetRaceID(client), RaceInfo_Status) == RaceStatus_Pending)
		{
			AbortRace(GetRaceID(client));
		}
		else
		{
			SurrenderRacer(client);
		}
	}
} 