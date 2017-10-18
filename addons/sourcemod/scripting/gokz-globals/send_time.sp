/*
	Send Time
	
	Sends a time to the global API, and announces if they got a top global 
	time for the map course and mode.
*/



void SendTime(int client, int course, float time, int teleportsUsed)
{
	if (GlobalsEnabled())
	{
		KZPlayer player = new KZPlayer(client);
		int mode = player.mode;
		
		DataPack dp = CreateDataPack();
		dp.WriteCell(GetClientUserId(client));
		dp.WriteCell(course);
		dp.WriteCell(mode);
		dp.WriteCell(GOKZ_GetTimeType(teleportsUsed));
		
		GlobalAPI_SendRecord(client, GOKZ_GL_GetGlobalMode(mode), course, teleportsUsed, time, SendTimeCallback, dp);
	}
}

public int SendTimeCallback(bool failure, int place, int top_place, int top_overall_place, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int course = dp.ReadCell();
	int mode = dp.ReadCell();
	int timeType = dp.ReadCell();
	delete dp;
	
	if (failure)
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
		Call_OnNewTopTime(client, course, mode, timeType, top_place, top_overall_place);
	}
} 