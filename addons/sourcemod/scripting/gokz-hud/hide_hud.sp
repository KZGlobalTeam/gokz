/*
	Hides elements of the CS:GO HUD.
*/



// =====[ EVENTS ]=====

void OnPlayerSpawn_HideHUD(int client)
{
	UpdateCSGOHUD(client);
}



// =====[ PRIVATE ]=====

static void UpdateCSGOHUD(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(0.1, CleanHUD, GetClientUserId(client));
}

public Action CleanHUD(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		// (1 << 12) Hide Radar
		int clientEntFlags = GetEntProp(client, Prop_Send, "m_iHideHUD");
		SetEntProp(client, Prop_Send, "m_iHideHUD", clientEntFlags | (1 << 12));
	}
	return Plugin_Continue;
} 