/*
	Hide CS:GO HUD
	
	Hides elements of the CS:GO HUD.
*/



// =========================  PUBLIC  ========================= //

void UpdateCSGOHUD(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(0.1, CleanHUD, GetClientUserId(client));
}



// =========================  CALLBACKS  ========================= //

public Action CleanHUD(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		// (1 << 12) Hide Radar
		// (1 << 13) Hide Round Timer
		int clientEntFlags = GetEntProp(client, Prop_Send, "m_iHideHUD");
		SetEntProp(client, Prop_Send, "m_iHideHUD", clientEntFlags | (1 << 12) + (1 << 13));
	}
	return Plugin_Continue;
} 