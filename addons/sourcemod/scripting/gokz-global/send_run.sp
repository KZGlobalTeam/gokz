/*
	Sends a run to the global API and delete the replay if it is a temporary replay.
*/



char storedReplayPath[MAXPLAYERS + 1][512];
int lastRecordId[MAXPLAYERS + 1], storedCourse[MAXPLAYERS + 1], storedTimeType[MAXPLAYERS + 1], storedUserId[MAXPLAYERS + 1];
float storedTime[MAXPLAYERS + 1];
bool deleteRecord[MAXPLAYERS + 1];

// =====[ PUBLIC ]=====

// Returns whether the request went out. replayPath is a kept run's temporary replay, which this takes over.
bool SendTime(int client, int mapID, const char[] map, int course, int mode, float time, int teleportsUsed, bool kept = false, const char[] replayPath = "")
{
	char steamid[32], modeStr[32];

	int timeType = GOKZ_GetTimeTypeEx(teleportsUsed);

	// If this map's filters have been loaded, skip the submission when the API would reject it.
	if (gB_FiltersLoaded && mapID == gI_MapID && course >= 0 && course < GOKZ_MAX_COURSES)
	{
		bool wouldSave = gB_HasFilter[course][mode][TimeType_Nub]
			|| (timeType == TimeType_Pro && gB_HasFilter[course][mode][TimeType_Pro]);
		if (!wouldSave)
		{
			if (replayPath[0] != '\0')
			{
				DeleteFile(replayPath);
			}
			return false;
		}
	}

	DataPack dp = CreateDataPack();
	dp.WriteCell(GetClientUserId(client));
	dp.WriteCell(course);
	dp.WriteCell(mode);
	dp.WriteCell(timeType);
	dp.WriteFloat(time);
	dp.WriteString(map);
	dp.WriteCell(kept);
	dp.WriteString(replayPath);

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GOKZ_GL_GetModeString(mode, modeStr, sizeof(modeStr));
	if (!GlobalAPI_CreateRecord(SendTimeCallback, dp, steamid, mapID, modeStr, course, 128, teleportsUsed, time))
	{
		delete dp;
		if (replayPath[0] != '\0')
		{
			DeleteFile(replayPath);
		}
		return false;
	}
	return true;
}

public int SendTimeCallback(JSON_Object response, GlobalAPIRequestData request, DataPack dp)
{
	dp.Reset();
	int userID = dp.ReadCell();
	int client = GetClientOfUserId(userID);
	int course = dp.ReadCell();
	int mode = dp.ReadCell();
	int timeType = dp.ReadCell();
	float time = dp.ReadFloat();
	char mapName[64];
	dp.ReadString(mapName, sizeof(mapName));
	bool kept = dp.ReadCell();
	char keptReplayPath[PLATFORM_MAX_PATH];
	dp.ReadString(keptReplayPath, sizeof(keptReplayPath));
	delete dp;
	
	// A successful request can still have no response body
	bool failed = request.Failure || response == null;
	
	// A kept run's replay was saved before its record existed, so it doesn't wait for GOKZ_RP_OnReplaySaved
	if (keptReplayPath[0] != '\0')
	{
		if (failed)
		{
			DeleteFile(keptReplayPath);
		}
		else
		{
			DataPack replayDP = new DataPack();
			replayDP.WriteString(keptReplayPath);
			if (!GlobalAPI_CreateReplayForRecordId(SendReplayCallback, replayDP, response.GetInt("record_id"), keptReplayPath))
			{
				delete replayDP;
				DeleteFile(keptReplayPath);
			}
		}
	}
	
	if (!IsValidClient(client))
	{
		return 0;
	}
	
	if (failed)
	{
		LogError("Failed to send a time to the global API.");
		if (GlobalAPI_HasAPIKey())
		{
			GlobalAPI_GetAuthStatus(GetAuthStatusCallback);
		}
		return 0;
	}
	
	int top_place = response.GetInt("top_100");
	int top_overall_place = response.GetInt("top_100_overall");
	
	if (top_place > 0)
	{
		Call_OnNewTopTime(client, course, mode, timeType, top_place, top_overall_place, time, mapName);
	}
	
	// Don't like doing this here, but seems to be the most efficient place
	UpdatePoints(client, true);

	if (kept)
	{
		// Only the newest can still have a replay coming, as a run ending cuts short the last one's breather
		bool newest = !HasUnverifiedRuns(client);
		SendNextUnverifiedRun(client);
		if (!newest || keptReplayPath[0] != '\0')
		{
			return 0;
		}
	}

	// Check if we can send the replay
	lastRecordId[client] = response.GetInt("record_id");
	if (IsReplayReadyToSend(client, course, timeType, time))
	{
		SendReplay(client);
	}
	else
	{
		storedUserId[client] = userID;
		storedCourse[client] = course;
		storedTimeType[client] = timeType;
		storedTime[client] = time;
	}
	return 0;
}

public void OnReplaySaved_SendReplay(int client, int replayType, const char[] map, int course, int timeType, float time, const char[] filePath, bool tempReplay)
{
	strcopy(storedReplayPath[client], sizeof(storedReplayPath[]), filePath);
	if (IsReplayReadyToSend(client, course, timeType, time))
	{
		SendReplay(client);
	}
	else
	{
		lastRecordId[client] = -1;
		storedUserId[client] = GetClientUserId(client);
		storedCourse[client] = course;
		storedTimeType[client] = timeType;
		storedTime[client] = time;
		deleteRecord[client] = tempReplay;
	}
}

bool IsReplayReadyToSend(int client, int course, int timeType, float time)
{
	// Not an error, just not ready yet
	if (lastRecordId[client] == -1 || storedReplayPath[client][0] == '\0')
	{
		return false;
	}
	
	if (storedUserId[client] == GetClientUserId(client) && storedCourse[client] == course
		&& storedTimeType[client] == timeType && storedTime[client] == time)
	{
		return true;
	}
	else
	{
		LogError("Failed to upload replay to the global API. Record mismatch.");
		return false;
	}
}

public void SendReplay(int client)
{
	DataPack dp = new DataPack();
	dp.WriteString(deleteRecord[client] ? storedReplayPath[client] : "");
	GlobalAPI_CreateReplayForRecordId(SendReplayCallback, dp, lastRecordId[client], storedReplayPath[client]);
	lastRecordId[client] = -1;
	storedReplayPath[client] = "";
}

public int SendReplayCallback(JSON_Object response, GlobalAPIRequestData request, DataPack dp)
{
	// Delete the temporary replay file if needed.
	dp.Reset();
	char replayPath[PLATFORM_MAX_PATH];
	dp.ReadString(replayPath, sizeof(replayPath));
	if (replayPath[0] != '\0')
	{
		DeleteFile(replayPath);
	}
	delete dp;
	return 0;
}
