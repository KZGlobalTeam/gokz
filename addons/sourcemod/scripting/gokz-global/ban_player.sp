/*
	Globally ban players when they are suspected by gokz-anticheat.
*/



// =====[ PUBLIC ]=====

void GlobalBanPlayer(int client, ACReason reason, const char[] notes, const char[] stats)
{
	char playerName[MAX_NAME_LENGTH], steamid[32];
	GetClientName(client, playerName, sizeof(playerName));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	DataPack dp = new DataPack();
	dp.WriteString(playerName);
	dp.WriteString(steamid);
	
	switch (reason)
	{
		case ACReason_BhopHack:GlobalAPI_BanPlayer(client, "bhop_hack", notes, stats, BanPlayerCallback, dp);
		case ACReason_BhopMacro:GlobalAPI_BanPlayer(client, "bhop_macro", notes, stats, BanPlayerCallback, dp);
	}
}

public int BanPlayerCallback(bool failure, DataPack dp)
{
	dp.Reset();
	char playerName[MAX_NAME_LENGTH], steamid[32];
	dp.ReadString(playerName, sizeof(playerName));
	dp.ReadString(steamid, sizeof(steamid));
	delete dp;
	
	if (failure)
	{
		LogError("Failed to globally ban %s (%s).", playerName, steamid);
	}
} 