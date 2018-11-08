/*
	Miscellaneous functions and features.
*/



// =====[ GENERAL HELPERS ]=====

bool InRace(int client)
{
	return GetRacerStatus(client) != RacerStatus_Available;
}

bool InStartedRace(int client)
{
	return GetRacerStatus(client) == RacerStatus_Racing;
}

bool InCountdown(int client)
{
	return InRace(client) && GetRaceInfo(GetRaceID(client), RaceInfo_Status) == RaceStatus_Countdown;
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
	int status = GetRacerStatus(client);
	return status == RacerStatus_Finished || status == RacerStatus_Surrendered;
}

bool IsAccepted(int client)
{
	return GetRacerStatus(client) == RacerStatus_Accepted;
}

bool IsAllowedToTeleport(int client)
{
	return !(InStartedRace(client) && GetRaceInfo(GetRaceID(client), RaceInfo_TeleportRule) == TeleportRule_None);
}

bool IsRaceHost(int client)
{
	return InRace(client) && GetRaceHost(GetRaceID(client)) == client;
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
		if (InRace(i) && GetRaceID(i) == raceID && !IsFinished(i))
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
		if (InRace(i) && GetRaceID(i) == raceID && IsAccepted(i))
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



// =====[ ANNOUNCEMENTS ]=====

void AnnounceRaceFinish(int client, int raceID, int place)
{
	switch (GetRaceInfo(raceID, RaceInfo_Type))
	{
		case RaceType_Normal:
		{
			if (place == 1)
			{
				GOKZ_PrintToChatAll(true, "%t", "Race Won", client);
			}
			else
			{
				ArrayList unfinishedRacers = GetUnfinishedRacers(raceID);
				if (unfinishedRacers.Length >= 1)
				{
					GOKZ_PrintToChatAll(true, "%t", "Race Placed", client, place);
				}
				else
				{
					GOKZ_PrintToChatAll(true, "%t", "Race Lost", client, place);
				}
				delete unfinishedRacers;
			}
		}
		case RaceType_Duel:
		{
			ArrayList unfinishedRacers = GetUnfinishedRacers(raceID);
			if (unfinishedRacers.Length == 1)
			{
				int opponent = unfinishedRacers.Get(0);
				GOKZ_PrintToChatAll(true, "%t", "Duel Won", client, opponent);
			}
			delete unfinishedRacers;
		}
	}
}

void AnnounceRaceSurrender(int client, int raceID)
{
	switch (GetRaceInfo(raceID, RaceInfo_Type))
	{
		case RaceType_Normal:
		{
			GOKZ_PrintToChatAll(true, "%t", "Race Surrendered", client);
		}
		case RaceType_Duel:
		{
			ArrayList unfinishedRacers = GetUnfinishedRacers(raceID);
			if (unfinishedRacers.Length == 1)
			{
				int opponent = unfinishedRacers.Get(0);
				GOKZ_PrintToChatAll(true, "%t", "Duel Surrendered", client, opponent);
			}
			delete unfinishedRacers;
		}
	}
}

void AnnounceRequestReceived(int client, int raceID)
{
	int host = GetRaceHost(raceID);
	
	switch (GetRaceInfo(raceID, RaceInfo_Type))
	{
		case RaceType_Normal:
		{
			GOKZ_PrintToChat(client, true, "%t", "Race Request Received", host);
		}
		case RaceType_Duel:
		{
			GOKZ_PrintToChat(client, true, "%t", "Duel Request Received", host);
		}
	}
	
	GOKZ_PrintToChat(client, false, "%t", "Race Rules", 
		gC_ModeNames[GetRaceInfo(raceID, RaceInfo_Mode)], 
		gC_TeleportRulePhrases[GetRaceInfo(raceID, RaceInfo_TeleportRule)]);
	GOKZ_PrintToChat(client, false, "%t", "You Have Seconds To Accept", RC_REQUEST_TIMEOUT_TIME);
}

void AnnounceRequestAccepted(int client, int raceID)
{
	int host = GetRaceHost(raceID);
	
	switch (GetRaceInfo(raceID, RaceInfo_Type))
	{
		case RaceType_Normal:
		{
			GOKZ_PrintToChatAll(true, "%t", "Race Request Accepted", client, host);
		}
		case RaceType_Duel:
		{
			GOKZ_PrintToChatAll(true, "%t", "Duel Request Accepted", client, host);
		}
	}
}

void AnnounceRequestDeclined(int client, int raceID, bool timeout)
{
	int host = GetRaceHost(raceID);
	
	if (timeout)
	{
		switch (GetRaceInfo(raceID, RaceInfo_Type))
		{
			case RaceType_Normal:
			{
				GOKZ_PrintToChat(client, true, "%t", "Race Request Not Accepted In Time (Target)");
				GOKZ_PrintToChat(host, true, "%t", "Race Request Not Accepted In Time (Host)", client);
			}
			case RaceType_Duel:
			{
				GOKZ_PrintToChat(client, true, "%t", "Duel Request Not Accepted In Time (Target)");
				GOKZ_PrintToChat(host, true, "%t", "Duel Request Not Accepted In Time (Host)", client);
			}
		}
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "You Have Declined");
		GOKZ_PrintToChat(host, true, "%t", "Player Has Declined", client);
	}
} 