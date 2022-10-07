/*
	Race info storing and accessing using a StringMap.
	Each race is given a unique race ID when created.
	See the RaceInfo enum for what information is accessible.
	See the RaceStatus enum for possible race states.
*/



static StringMap raceInfo;
static int lastRaceID;



// =====[ GENERAL ]=====

int GetRaceInfo(int raceID, RaceInfo prop)
{
	ArrayList info;
	if (raceInfo.GetValue(IntToStringEx(raceID), info))
	{
		return info.Get(view_as<int>(prop));
	}
	else
	{
		return -1;
	}
}

static bool SetRaceInfo(int raceID, RaceInfo prop, int value)
{
	ArrayList info;
	if (raceInfo.GetValue(IntToStringEx(raceID), info))
	{
		int oldValue = info.Get(view_as<int>(prop));
		if (oldValue != value)
		{
			info.Set(view_as<int>(prop), value);
			Call_OnRaceInfoChanged(raceID, prop, oldValue, value);
		}
		return true;
	}
	else
	{
		return false;
	}
}

int IncrementFinishedRacerCount(int raceID)
{
	int finishedRacers = GetRaceInfo(raceID, RaceInfo_FinishedRacerCount) + 1;
	SetRaceInfo(raceID, RaceInfo_FinishedRacerCount, finishedRacers);
	return finishedRacers;
}

int GetRaceHost(int raceID)
{
	return GetClientOfUserId(GetRaceInfo(raceID, RaceInfo_HostUserID));
}

ArrayList GetUnfinishedRacers(int raceID)
{
	ArrayList racers = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (GetRaceID(i) == raceID && !IsFinished(i))
		{
			racers.Push(i);
		}
	}
	return racers;
}

int GetUnfinishedRacersCount(int raceID)
{
	ArrayList racers = GetUnfinishedRacers(raceID);
	int count = racers.Length;
	delete racers;
	return count;
}

ArrayList GetAcceptedRacers(int raceID)
{
	ArrayList racers = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (GetRaceID(i) == raceID && IsAccepted(i))
		{
			racers.Push(i);
		}
	}
	return racers;
}

int GetAcceptedRacersCount(int raceID)
{
	ArrayList racers = GetAcceptedRacers(raceID);
	int count = racers.Length;
	delete racers;
	return count;
}



// =====[ REGISTRATION ]=====

int RegisterRace(int host, int type, int course, int mode, int checkpointRule, int cooldownRule)
{
	int raceID = ++lastRaceID;
	
	ArrayList info = new ArrayList(1, view_as<int>(RACEINFO_COUNT));
	info.Set(view_as<int>(RaceInfo_ID), raceID);
	info.Set(view_as<int>(RaceInfo_Status), RaceStatus_Pending);
	info.Set(view_as<int>(RaceInfo_HostUserID), GetClientUserId(host));
	info.Set(view_as<int>(RaceInfo_FinishedRacerCount), 0);
	info.Set(view_as<int>(RaceInfo_Type), type);
	info.Set(view_as<int>(RaceInfo_Course), course);
	info.Set(view_as<int>(RaceInfo_Mode), mode);
	info.Set(view_as<int>(RaceInfo_CheckpointRule), checkpointRule);
	info.Set(view_as<int>(RaceInfo_CooldownRule), cooldownRule);
	
	raceInfo.SetValue(IntToStringEx(raceID), info);
	
	Call_OnRaceRegistered(raceID);
	
	return raceID;
}

static void UnregisterRace(int raceID)
{
	ArrayList info;
	if (raceInfo.GetValue(IntToStringEx(raceID), info))
	{
		delete info;
		raceInfo.Remove(IntToStringEx(raceID));
	}
}



// =====[ START ]=====

bool StartRace(int raceID)
{
	SetRaceInfo(raceID, RaceInfo_Status, RaceStatus_Countdown);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GetRaceID(client) == raceID)
		{
			StartRacer(client);
			GOKZ_PrintToChat(client, true, "%t", "Race Countdown Started");
		}
	}
	
	CreateTimer(RC_COUNTDOWN_TIME, Timer_EndCountdown, raceID);
	
	return true;
}

public Action Timer_EndCountdown(Handle timer, int raceID)
{
	SetRaceInfo(raceID, RaceInfo_Status, RaceStatus_Started);
	return Plugin_Continue;
}



// =====[ ABORT ]=====

bool AbortRace(int raceID)
{
	SetRaceInfo(raceID, RaceInfo_Status, RaceStatus_Aborting);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GetRaceID(client) == raceID)
		{
			AbortRacer(client);
			GOKZ_PrintToChat(client, true, "%t", "Race Has Been Aborted");
			GOKZ_PlayErrorSound(client);
		}
	}
	
	UnregisterRace(raceID);
	
	return true;
}



// =====[ EVENTS ]=====

void OnPluginStart_Race()
{
	raceInfo = new StringMap();
}

void OnFinish_Race(int raceID)
{
	if (GetUnfinishedRacersCount(raceID) == 0)
	{
		UnregisterRace(raceID);
	}
}

void OnRequestAccepted_Race(int raceID)
{
	if (GetRaceInfo(raceID, RaceInfo_Type) == RaceType_Duel)
	{
		StartRace(raceID);
	}
}

void OnRequestDeclined_Race(int raceID)
{
	if (GetRaceInfo(raceID, RaceInfo_Type) == RaceType_Duel)
	{
		AbortRace(raceID);
	}
} 