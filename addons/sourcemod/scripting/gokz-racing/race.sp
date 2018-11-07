/*
	Race info storing and accessing using a StringMap.
	Each race is given a unique race ID when created.
	See the RaceInfo enum for what information is accessible.
	See the RaceStatus enum for possible race states.
*/



static StringMap raceInfo;
static int lastRaceID;



// =====[ GENERAL ]=====

bool IsValidRaceID(int raceID)
{
	any dummy;
	return raceInfo.GetValue(IntToStringEx(raceID), dummy);
}

int IncrementFinishedRacerCount(int raceID)
{
	int finishedRacers = GetRaceInfo(raceID, RaceInfo_FinishedRacerCount) + 1;
	SetRaceInfo(raceID, RaceInfo_FinishedRacerCount, finishedRacers);
	return finishedRacers;
}



// =====[ REGISTRATION ]=====

int RegisterRace(int host, int type, int course, int mode, int teleportsRule)
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
	info.Set(view_as<int>(RaceInfo_TeleportsRule), teleportsRule);
	
	raceInfo.SetValue(IntToStringEx(raceID), info);
	
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



// =====[ RACE INFO ]=====

int GetRaceInfo(int raceID, RaceInfo infoIndex)
{
	ArrayList info;
	if (raceInfo.GetValue(IntToStringEx(raceID), info))
	{
		return info.Get(view_as<int>(infoIndex));
	}
	else
	{
		return -1;
	}
}

static bool SetRaceInfo(int raceID, RaceInfo infoIndex, int value)
{
	ArrayList info;
	if (raceInfo.GetValue(IntToStringEx(raceID), info))
	{
		info.Set(view_as<int>(infoIndex), value);
		return true;
	}
	else
	{
		return false;
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
		}
	}
	
	StartCountdownHUD(raceID);
	CreateTimer(float(RC_COUNTDOWN_TIME), Timer_EndCountdown, raceID);
	
	return true;
}

public Action Timer_EndCountdown(Handle timer, int raceID)
{
	SetRaceInfo(raceID, RaceInfo_Status, RaceStatus_Started);
}



// =====[ ABORT ]=====

bool AbortRace(int raceID)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GetRaceID(client) == raceID)
		{
			AbortRacer(client);
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