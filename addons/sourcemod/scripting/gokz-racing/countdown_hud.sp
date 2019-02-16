/*
	On screen countdown for the start of the race.
*/



static Handle countdownHudSynchronizer;



// =====[ PUBLIC ]=====

void StartCountdownHUD(int raceID)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GetRaceID(client) == raceID)
		{
			DisplayCountdownHUD(client, RoundFloat(RC_COUNTDOWN_TIME));
		}
	}
	
	DataPack data = new DataPack();
	data.WriteCell(raceID);
	data.WriteCell(RoundFloat(RC_COUNTDOWN_TIME));
	CreateTimer(1.0, Timer_Countdown, data);
}

public Action Timer_Countdown(Handle timer, DataPack data)
{
	data.Reset();
	int raceID = data.ReadCell();
	int countdown = data.ReadCell() - 1;
	delete data;
	
	if (!IsValidRaceID(raceID))
	{
		return;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (GetRaceID(client) == raceID)
		{
			DisplayCountdownHUD(client, countdown);
		}
	}
	
	if (countdown > 0)
	{
		data = new DataPack();
		data.WriteCell(raceID);
		data.WriteCell(countdown);
		CreateTimer(1.0, Timer_Countdown, data);
	}
}



// =====[ EVENTS ]=====

void OnPluginStart_CountdownHUD()
{
	countdownHudSynchronizer = CreateHudSynchronizer();
}



// =====[ PRIVATE ]=====

static void DisplayCountdownHUD(int client, int time)
{
	char display[16];
	if (time <= 0)
	{
		FormatEx(display, sizeof(display), "%T", "GO!", client);
		SetHudTextParams(-1.0, 0.4, 2.5, 0, 255, 0, 255);
	}
	else
	{
		FormatEx(display, sizeof(display), "%d", time);
		switch (time)
		{
			// Red to green pattern, with red as default
			case 10:SetHudTextParams(-1.0, 0.4, 1.0, 255, 0, 0, 255);
			case 9:SetHudTextParams(-1.0, 0.4, 1.0, 255, 51, 0, 255);
			case 8:SetHudTextParams(-1.0, 0.4, 1.0, 255, 102, 0, 255);
			case 7:SetHudTextParams(-1.0, 0.4, 1.0, 255, 153, 0, 255);
			case 6:SetHudTextParams(-1.0, 0.4, 1.0, 255, 204, 0, 255);
			case 5:SetHudTextParams(-1.0, 0.4, 1.0, 255, 255, 0, 255);
			case 4:SetHudTextParams(-1.0, 0.4, 1.0, 204, 255, 0, 255);
			case 3:SetHudTextParams(-1.0, 0.4, 1.0, 153, 255, 0, 255);
			case 2:SetHudTextParams(-1.0, 0.4, 1.0, 102, 255, 0, 255);
			case 1:SetHudTextParams(-1.0, 0.4, 1.0, 51, 255, 0, 255);
			default:SetHudTextParams(-1.0, 0.4, 1.0, 255, 0, 0, 255);
		}
	}
	
	ShowSyncHudText(client, countdownHudSynchronizer, display);
	
	// Spectators
	for (int spec = 1; spec <= MaxClients; spec++)
	{
		if (IsClientInGame(spec) && !IsPlayerAlive(spec) && GetObserverTarget(spec) == client)
		{
			ShowSyncHudText(spec, countdownHudSynchronizer, display);
		}
	}
} 