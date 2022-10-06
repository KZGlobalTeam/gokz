/*
	Globally ban players when they are suspected by gokz-anticheat.
*/



// =====[ PUBLIC ]=====

void GlobalBanPlayer(int client, ACReason reason, const char[] notes, const char[] stats)
{
	char playerName[MAX_NAME_LENGTH], steamid[32], ip[32];
	
	GetClientName(client, playerName, sizeof(playerName));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientIP(client, ip, sizeof(ip));
	
	DataPack dp = new DataPack();
	dp.WriteString(playerName);
	dp.WriteString(steamid);
	
	switch (reason)
	{
		case ACReason_BhopHack:GlobalAPI_CreateBan(BanPlayerCallback, dp, steamid, "bhop_hack", stats, notes, ip);
		case ACReason_BhopMacro:GlobalAPI_CreateBan(BanPlayerCallback, dp, steamid, "bhop_macro", stats, notes, ip);
	}
}

public int BanPlayerCallback(JSON_Object response, GlobalAPIRequestData request, DataPack dp)
{
	char playerName[MAX_NAME_LENGTH], steamid[32];
	
	dp.Reset();
	dp.ReadString(playerName, sizeof(playerName));
	dp.ReadString(steamid, sizeof(steamid));
	delete dp;
	
	if (request.Failure)
	{
		LogError("Failed to globally ban %s (%s).", playerName, steamid);
	}
	return 0;
}
