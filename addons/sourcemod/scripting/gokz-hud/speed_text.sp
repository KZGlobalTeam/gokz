/*	
	Uses HUD text to show current speed somewhere on the screen.
	
	This is manually refreshed whenever player has taken off so that they see
	their pre-speed as soon as possible, improving responsiveness.
*/



static Handle speedHudSynchronizer;

static bool speedTextDuckPressedLast[MAXPLAYERS + 1];
static bool speedTextOnGroundLast[MAXPLAYERS + 1];
static bool speedTextShowDuckString[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

void OnPluginStart_SpeedText()
{
	speedHudSynchronizer = CreateHudSynchronizer();
}

void OnPlayerRunCmdPost_SpeedText(int client, int cmdnum, HUDInfo info)
{
	int updateSpeed = gB_FastUpdateRate[client] ? 3 : 6;
	if (cmdnum % updateSpeed == 0 || info.IsTakeoff)
	{
		UpdateSpeedText(client, info);
	}
	speedTextOnGroundLast[info.ID] = info.OnGround;
	speedTextDuckPressedLast[info.ID] = info.Ducking;
}

void OnOptionChanged_SpeedText(int client, HUDOption option)
{
	if (option == HUDOption_SpeedText)
	{
		ClearSpeedText(client);
	}
}



// =====[ PRIVATE ]=====

static void UpdateSpeedText(int client, HUDInfo info)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake
		 || player.SpeedText != SpeedText_Bottom)
	{
		return;
	}
	
	ShowSpeedText(player, info);
}

static void ClearSpeedText(int client)
{
	ClearSyncHud(client, speedHudSynchronizer);
}

static void ShowSpeedText(KZPlayer player, HUDInfo info)
{
	if (info.Paused)
	{
		return;
	}
	
	int colour[4] = { 255, 255, 255, 0 }; // RGBA
	float velZ = Movement_GetVerticalVelocity(info.ID);
	if (!info.OnGround && !info.OnLadder && !info.Noclipping)
	{
		if (GOKZ_HUD_GetOption(player.ID, HUDOption_DeadstrafeColor) == DeadstrafeColor_Enabled && velZ > 0.0 && velZ < 140.0)
		{
			colour = { 255, 32, 32, 0 };
		}
		else if (info.HitPerf)
		{
			if (info.HitJB)
			{
				colour = { 255, 255, 32, 0 };
			}
			else
			{
				colour = { 64, 255, 64, 0 };
			}
		}
	}

	switch (player.SpeedText)
	{
		case SpeedText_Bottom:
		{
			// Set params based on the available screen space at max scaling HUD
			if (!IsDrawingInfoPanel(player.ID))
			{
				SetHudTextParams(-1.0, 0.75, GetTextHoldTime(gB_FastUpdateRate[player.ID] ? 3 : 6), colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
			else
			{
				SetHudTextParams(-1.0, 0.65, GetTextHoldTime(gB_FastUpdateRate[player.ID] ? 3 : 6), colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
		}
	}
	
	if (info.OnGround || info.OnLadder || info.Noclipping)
	{
		ShowSyncHudText(player.ID, speedHudSynchronizer, 
			"%.0f", 
			RoundFloat(info.Speed * 10) / 10.0);
		speedTextShowDuckString[info.ID] = false;
	}
	else
	{
		if (speedTextShowDuckString[info.ID]
		|| (speedTextOnGroundLast[info.ID]
			&& !info.HitBhop 
			&& info.IsTakeoff
			&& info.Jumped
			&& info.Ducking
			&& (speedTextDuckPressedLast[info.ID] || GOKZ_GetCoreOption(info.ID, Option_Mode) == Mode_Vanilla)))
		{
			ShowSyncHudText(player.ID, speedHudSynchronizer, 
				"%.0f\n  (%.0f)C", 
				RoundToPowerOfTen(info.Speed, -2), 
				RoundToPowerOfTen(info.TakeoffSpeed, -2));	
			speedTextShowDuckString[info.ID] = true;
		}
		else {
			ShowSyncHudText(player.ID, speedHudSynchronizer, 
				"%.0f\n(%.0f)", 
				RoundToPowerOfTen(info.Speed, -2), 
				RoundToPowerOfTen(info.TakeoffSpeed, -2));
			speedTextShowDuckString[info.ID] = false;
		}
	}
} 