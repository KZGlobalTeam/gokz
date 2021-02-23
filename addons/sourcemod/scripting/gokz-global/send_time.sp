/*
	Sends a time to the global API.
*/



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
	
	int top_place = response.GetInt("top_100");
	int top_overall_place = response.GetInt("top_100_overall");
	
	if (request.Failure)
	{
		LogError("Failed to send a time to the global API.");
		return;
	}
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (top_place > 0)
	{
		Call_OnNewTopTime(client, course, mode, timeType, top_place, top_overall_place, time);
	}
} 