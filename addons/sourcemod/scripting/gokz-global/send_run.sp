/*
	Sends a run to the global API.
*/



char storedSteamId[17], storedMap[64];
int lastRecordId, storedCourse, storedTimeType;
float storedTime;

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
	int client = GetClientOfUserId(dp.ReadCell());
	int course = dp.ReadCell();
	int mode = dp.ReadCell();
	int timeType = dp.ReadCell();
	float time = dp.ReadFloat();
	delete dp;
	
	if (request.Failure)
	{
		LogError("Failed to send a time to the global API.");
		return;
	}
	
	int top_place = response.GetInt("top_100");
	int top_overall_place = response.GetInt("top_100_overall");
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (top_place > 0)
	{
		Call_OnNewTopTime(client, course, mode, timeType, top_place, top_overall_place, time);
	}
	
	// Don't like doing this here, but seems to be the most efficient place
	GOKZ_GL_UpdatePoints(client);

	APIRecord apiRecord = new APIRecord(response);
	lastRecordId = apiRecord.Id;
	apiRecord.GetSteamId64(storedSteamId, sizeof(storedSteamId));
	apiRecord.GetMapName(storedMap, sizeof(storedMap));
	storedCourse = apiRecord.Stage;
	storedTimeType = apiRecord.Teleports > 0 ? TimeType_Nub : TimeType_Pro;
	storedTime = apiRecord.Time;
}

public void SendReplay(int client, int replayReplayType, const char[] replayMap, int replayCourse, int replayTimeType, float replayTime, const char[] replayFilePath)
{
	char replaySteamId[17];
	GetClientAuthId(client, AuthId_SteamID64, replaySteamId, sizeof(replaySteamId));
	if (lastRecordId != -1 && StrEqual(storedSteamId, replaySteamId) && StrEqual(storedMap, replayMap)
			&& storedCourse == replayCourse && storedTimeType == replayTimeType && storedTime == replayTime)
	{
		GlobalAPI_CreateReplayForRecordId(SendReplayCallback, DEFAULT_DATA, lastRecordId, replayFilePath);
		lastRecordId = -1;
	}
	else
	{
		LogError("Failed to upload replay to the global API. No recordId found.");
	}
}

public int SendReplayCallback(JSON_Object response, GlobalAPIRequestData request, DataPack dp)
{

}
