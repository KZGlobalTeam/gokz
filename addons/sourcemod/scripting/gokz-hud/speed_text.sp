/*	
	Uses HUD text to show current speed somewhere on the screen.
	
	This is manually refreshed whenever player has taken off so that they see
	their pre-speed as soon as possible, improving responsiveness.
*/



static Handle speedHudSynchronizer;



// =====[ EVENTS ]=====

void OnPluginStart_SpeedText()
{
	speedHudSynchronizer = CreateHudSynchronizer();
}

void OnPlayerRunCmdPost_SpeedText(int client, int cmdnum)
{
	if (cmdnum % 6 == 0 || Movement_GetTakeoffCmdNum(client) == cmdnum - 1)
	{
		UpdateSpeedText(client);
	}
}

void OnOptionChanged_SpeedText(int client, HUDOption option)
{
	if (option == HUDOption_SpeedText)
	{
		ClearSpeedText(client);
		UpdateSpeedText(client);
	}
}



// =====[ PRIVATE ]=====

static void UpdateSpeedText(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake
		 || player.SpeedText != SpeedText_Bottom)
	{
		return;
	}
	
	if (player.Alive)
	{
		ShowSpeedText(player, player);
	}
	else
	{
		KZPlayer targetPlayer = KZPlayer(player.ObserverTarget);
		if (targetPlayer.ID != -1 && !targetPlayer.Fake)
		{
			ShowSpeedText(player, targetPlayer);
		}
	}
}

static void ClearSpeedText(int client)
{
	ClearSyncHud(client, speedHudSynchronizer);
}

static void ShowSpeedText(KZPlayer player, KZPlayer targetPlayer)
{
	if (targetPlayer.Paused)
	{
		return;
	}
	
	int colour[4]; // RGBA
	if (targetPlayer.GOKZHitPerf && !targetPlayer.OnGround && !targetPlayer.OnLadder && !targetPlayer.Noclipping)
	{
		colour =  { 64, 255, 64, 0 };
	}
	else
	{
		colour =  { 255, 255, 255, 0 };
	}
	
	switch (player.SpeedText)
	{
		case SpeedText_Bottom:
		{
			// Set params based on the available screen space at max scaling HUD
			if (!IsDrawingInfoPanel(player.ID))
			{
				SetHudTextParams(-1.0, 0.75, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
			else
			{
				SetHudTextParams(-1.0, 0.65, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
		}
	}
	
	if (targetPlayer.OnGround || targetPlayer.OnLadder || targetPlayer.Noclipping)
	{
		ShowSyncHudText(player.ID, speedHudSynchronizer, 
			"%.0f", 
			RoundFloat(targetPlayer.Speed * 10) / 10.0);
	}
	else
	{
		ShowSyncHudText(player.ID, speedHudSynchronizer, 
			"%.0f\n(%.0f)", 
			RoundFloat(targetPlayer.Speed * 10) / 10.0, 
			RoundFloat(targetPlayer.GOKZTakeoffSpeed * 10) / 10.0);
	}
} 