/*
	Sends a run to the global API and delete the replay if it is a temporary replay.
*/



char storedReplayPath[MAXPLAYERS + 1][512];
int lastRecordId[MAXPLAYERS + 1], storedCourse[MAXPLAYERS + 1], storedTimeType[MAXPLAYERS + 1], storedUserId[MAXPLAYERS + 1];
float storedTime[MAXPLAYERS + 1];
bool deleteRecord[MAXPLAYERS + 1];

// =====[ PUBLIC ]=====

void SendTime(int client, int course, float time, int teleportsUsed)
{
	char steamid[32], modeStr[32];
	KZPlayer player = KZPlayer(client);
	int mode = player.Mode;
	
	if (GlobalsEnabled(mode))
	{
		DataPack dp = CreateDataPack();
		dp.WriteCell(GetClientUserId(client));
		dp.WriteCell(course);
		dp.WriteCell(mode);
		dp.WriteCell(GOKZ_GetTimeTypeEx(teleportsUsed));
		dp.WriteFloat(time);
		
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		GOKZ_GL_GetModeString(mode, modeStr, sizeof(modeStr));
		GlobalAPI_CreateRecord(SendTimeCallback, dp, steamid, gI_MapID, modeStr, course, 128, teleportsUsed, time);
	}
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
	delete dp;
	
	if (!IsValidClient(client))
	{
		return 0;
	}
	
	if (request.Failure)
	{
		LogError("Failed to send a time to the global API.");
		return 0;
	}
	
	int top_place = response.GetInt("top_100");
	int top_overall_place = response.GetInt("top_100_overall");
	
	if (top_place > 0)
	{
		Call_OnNewTopTime(client, course, mode, timeType, top_place, top_overall_place, time);
	}
	
	// Don't like doing this here, but seems to be the most efficient place
	UpdatePoints(client, true);

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
